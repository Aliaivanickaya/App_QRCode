//
//  ScannerViewController.swift
//  QRCode
//
//  Created by Алиса Иваницкая on 14.04.2023.
//

import AVFoundation
import UIKit

protocol ScannerDelegate: AnyObject {
    func receiveQRCodeData(_ data: String)
}

final class ScannerViewController: UIViewController {
    
    // MARK: - Public properties
    weak var delegate: ScannerDelegate?
    
    // MARK: - Private properties
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if captureSession?.isRunning == false {
            self.startSession()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if captureSession?.isRunning == true {
            captureSession.stopRunning()
        }
    }
    
    // MARK: - Private properties
    private func configureUI() {
        view.backgroundColor = .black
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barTintColor = .black
        navigationController?.navigationBar.backgroundColor = .black
        navigationItem.title = "Scanner"
        let closeButton = UIBarButtonItem(title: "Отменить", style: .plain, target: self, action: #selector(close))
        closeButton.tintColor = .white
        navigationItem.leftBarButtonItem = closeButton
        configureSession()
    }
    
    @objc private func close() {
        dismiss(animated: true)
    }
    
    private func configureSession() {
        captureSession = AVCaptureSession()
        guard
            let videoCaptureDevice = AVCaptureDevice.default(for: .video),
            let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice)
        else { return }
        
        guard captureSession.canAddInput(videoInput) else {
            failed()
            return
        }
        captureSession.addInput(videoInput)
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        guard captureSession.canAddOutput(metadataOutput) else {
            failed()
            return
        }

        captureSession.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = [.codabar, .code128, .code39, .code39Mod43, .code93, .dataMatrix, .microQR, .qr]
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        startSession()
    }
    
    private func startSession() {
        DispatchQueue(label: "com.qrcode", qos: .background).async {
            self.captureSession.startRunning()
        }
    }
    
    private func failed() {
        let ac = UIAlertController(
            title: "Scanning not supported",
            message: "Your device does not support scanning a code from an item. Please use a device with a camera.",
            preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }
    
    private func found(code: String) {
        delegate?.receiveQRCodeData(code)
    }
}

// MARK: - Extension
extension ScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection) {
            captureSession.stopRunning()
            
            if let metadataObject = metadataObjects.first {
                guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
                guard let stringValue = readableObject.stringValue else { return }
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                found(code: stringValue)
            }
            
            dismiss(animated: true)
        }
}
