//
//  QRCodeARViewController.swift
//  QRCode
//
//  Created by Алиса Иваницкая on 26.11.2023.
//

import UIKit
import ARKit
import Vision

final class QRCodeARViewController: UIViewController, ARSCNViewDelegate {
    
    // MARK: - Private properties
    private var sceneView: ARSCNView?
    private let visionQueue = DispatchQueue(label: "com.yourApp.visionQueue", qos: .userInitiated)
    private var displayLink: CADisplayLink?
    private var qrCodeURLs = [UUID: URL]()
    private var scannedImages: [String: UIImage] = [:]
    private var scannedText: String = "Test"
    private var isProcessingFrame: Bool = false
    private var lastProcessingTime: TimeInterval = 0
    private let processingInterval: TimeInterval = 0.5
    private lazy var spinner = CustomSpinnerView()
    
    // MARK: - Lifecycle
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSpinner()
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barTintColor = .black
        navigationItem.title = "AR"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupSceneView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView?.session.pause()
    }
    
    // MARK: - Private methods
    private func setupSceneView() {
        sceneView = ARSCNView(frame: view.frame)
        view.addSubview(sceneView ?? UIView())
        
        sceneView?.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.top.equalTo(view.safeAreaLayoutGuide)
        }
        
        sceneView?.delegate = self
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.vertical, .horizontal]
        sceneView?.session.run(configuration)
        
        sceneView?.scene = SCNScene()
        displayLink = CADisplayLink(target: self, selector: #selector(processCurrentARFrame))
        displayLink?.add(to: .current, forMode: .default)
    }
    
    private func setupSpinner() {
        view.addSubview(spinner)
        spinner.layer.zPosition = 10
        spinner.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(64)
        }
        spinner.stopAnimating()
    }
    
    private func showLoading(_ show: Bool) {
        DispatchQueue.main.async { [weak self] in
            if show {
                self?.spinner.startAnimating()
            } else {
                self?.spinner.stopAnimating()
            }
        }
    }
    
    @objc private func processCurrentARFrame() {
        guard let currentFrame = sceneView?.session.currentFrame,
              CACurrentMediaTime() - lastProcessingTime > processingInterval else { return }
        
        lastProcessingTime = CACurrentMediaTime()
        visionQueue.async { [weak self] in
            self?.detectQRCode(in: currentFrame.capturedImage)
        }
    }
    
    private func detectQRCode(in image: CVPixelBuffer) {
        isProcessingFrame = true
        let request = VNDetectBarcodesRequest { [weak self] (request, error) in
            DispatchQueue.main.async {
                self?.isProcessingFrame = false
            }
            guard error == nil else {
                print("QR code detection error: \(error?.localizedDescription ?? "")")
                return
            }
            
            self?.processDetectionResults(request.results)
        }
        request.symbologies = [.qr]
        let handler = VNImageRequestHandler(cvPixelBuffer: image, options: [:])
        DispatchQueue.global().async {
            do {
                try handler.perform([request])
            } catch let error {
                print("Failed to perform request: \(error)")
            }
        }
    }
    
    private func processDetectionResults(_ results: [Any]?) {
        guard
            let results,
            let result = results.first as? VNBarcodeObservation,
            let payload = result.payloadStringValue,
            let url = URL(string: payload),
            UIApplication.shared.canOpenURL(url) else {
            
            guard
                let results,
                let result = results.first as? VNBarcodeObservation,
                let payload = result.payloadStringValue
            else { return }
            displayLink?.invalidate()
            showLoading(false)
            let anchor = ARAnchor(name: payload, transform: .init())
            scannedText = payload
            sceneView?.session.add(anchor: anchor)
            return
        }
        
        displayLink?.invalidate()
        
        fetchImage(from: url.absoluteString) { [weak self] image in
            DispatchQueue.main.async {
                if let image {
                    let anchor = ARAnchor(name: payload, transform: .init())
                    self?.scannedImages[payload] = image
                    self?.sceneView?.session.add(anchor: anchor)
                } else {
                    let anchor = ARAnchor(name: payload, transform: .init())
                    self?.qrCodeURLs[anchor.identifier] = url
                    self?.sceneView?.session.add(anchor: anchor)
                }
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // Check if this is your QR code anchor
        DispatchQueue.main.async { [weak self] in
            if let url = self?.qrCodeURLs[anchor.identifier] {
                // Add the button node to this anchor node
                guard let buttonNode = self?.createNode(with: "Open Link") else { return }
                self?.sceneView?.scene.rootNode.addChildNode(buttonNode)
                // We assume the QR code is on a vertical plane and the button should appear right below the QR code
                buttonNode.position = SCNVector3(0, -0.1, -0.2) // Adjust the y, z offset as needed
                
                // Associate the URL with the button node for touch handling
                buttonNode.name = url.absoluteString
            } else if let image = self?.scannedImages[anchor.name ?? ""] {
                guard let imageNode = self?.createImageNode(with: image) else { return }
                self?.sceneView?.scene.rootNode.addChildNode(imageNode)
                imageNode.position = SCNVector3(0, -0.1, -0.2)
                imageNode.name = anchor.name
            } else {
                guard
                    let scannedText = self?.scannedText,
                    let textNode = self?.createNode(with: scannedText)
                else { return }
                self?.sceneView?.scene.rootNode.addChildNode(textNode)
                textNode.position = SCNVector3(0, -0.1, -0.2)
                textNode.name = scannedText
            }
        }
    }
    
    private func fetchImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            completion(nil)
            return
        }
        
        showLoading(true)
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            defer { self?.showLoading(false) }
            
            guard let data = data, error == nil else {
                print("Error downloading image: \(error?.localizedDescription ?? "No error description")")
                completion(nil)
                return
            }
            
            // Check if the response is an image by verifying the MIME type
            if let mimeType = response?.mimeType, mimeType.hasPrefix("image") {
                completion(UIImage(data: data))
            } else {
                print("The URL does not point to an image.")
                completion(nil)
            }
        }
        task.resume()
    }
    
    private func createNode(with text: String) -> SCNNode {
        let textGeometry = SCNText(string: text, extrusionDepth: 0.01)
        
        // Ensure text material is visible
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red // Choose an appropriate color
        textGeometry.materials = [material]
        
        let textNode = SCNNode(geometry: textGeometry)
        
        // Set a reasonable font size
        textGeometry.font = UIFont.systemFont(ofSize: 0.5)
        
        // Adjust the scale to make sure it's visible
        textNode.scale = SCNVector3(0.02, 0.02, 0.02) // You might need to tweak this
        
        // Center the pivot (optional, but helps in positioning the text correctly)
        let (min, max) = textNode.boundingBox
        textNode.pivot = SCNMatrix4MakeTranslation((max.x - min.x) / 2, (max.y - min.y) / 2, 0)
        
        return textNode
    }
    
    private func createImageNode(with image: UIImage) -> SCNNode {
        // Create a plane geometry with the image as its material
        let planeGeometry = SCNPlane(width: 1.0, height: 1.0 * image.size.height / image.size.width)
        let material = SCNMaterial()
        material.diffuse.contents = image
        planeGeometry.materials = [material]
        
        // Create a node with the plane geometry
        let imageNode = SCNNode(geometry: planeGeometry)
        
        // Adjust the scale to make sure it's visible and appropriately sized
        imageNode.scale = SCNVector3(0.2, 0.2, 0.2) // You might need to tweak this
        
        // Center the pivot (optional, but helps in positioning the image correctly)
        let (min, max) = imageNode.boundingBox
        imageNode.pivot = SCNMatrix4MakeTranslation((max.x - min.x) / 2, (max.y - min.y) / 2, 0)
        imageNode.name = ""
        return imageNode
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let location = touch.location(in: sceneView)
            let hitResults = sceneView?.hitTest(location, options: nil)
            if let hitNode = hitResults?.first?.node, let urlString = hitNode.name, let url = URL(string: urlString) {
                UIApplication.shared.open(url)
            }
        }
    }
}

// MARK: - CustomSpinnerView
extension QRCodeARViewController {
    class CustomSpinnerView: UIView {
        
        private lazy var spinner = UIActivityIndicatorView(style: .large)
        
        init() {
            super.init(frame: .zero)
            configureUI()
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
        }
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
        }
        
        private func configureUI() {
            backgroundColor = .black
            layer.cornerRadius = 8
            addSubview(spinner)
            spinner.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
        }
        
        func stopAnimating() {
            spinner.stopAnimating()
            isHidden = true
        }
        
        func startAnimating() {
            spinner.startAnimating()
            isHidden = false
        }
    }
}
