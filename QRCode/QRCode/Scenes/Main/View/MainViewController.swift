//
//  ViewController.swift
//  QRCode
//
//  Created by Алиса Иваницкая on 05.04.2023.
//

import UIKit
import SnapKit
import Photos
import PhotosUI

final class MainViewController: UIViewController {
    
    private lazy var scanButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .black
        button.titleLabel?.textColor = .white
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitle("Scan", for: .normal)
        button.layer.cornerRadius = 16
        button.addTarget(self, action: #selector(scanQRCode), for: .touchUpInside)
        return button
    }()
    
    private lazy var generateButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .black
        button.titleLabel?.textColor = .white
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitle("Generate", for: .normal)
        button.layer.cornerRadius = 16
        button.addTarget(self, action: #selector(generateQRCode), for: .touchUpInside)
        return button
    }()
    
    private lazy var pickerButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .black
        button.titleLabel?.textColor = .white
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitle("Pick", for: .normal)
        button.layer.cornerRadius = 16
        button.addTarget(self, action: #selector(selectPhoto), for: .touchUpInside)
        return button
    }()
    
    private lazy var qrImageView: UIImageView = {
        let view = UIImageView(image: UIImage(systemName: "questionmark.app"))
        view.tintColor = .lightGray
        return view
    }()
    
    private lazy var textFieldBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.borderColor = UIColor.black.cgColor
        view.layer.borderWidth = 1
        view.layer.cornerRadius = 8
        view.addSubview(textField)
        return view
    }()
    
    private lazy var textField: UITextField = {
        let textField = UITextField()
        textField.backgroundColor = .white
        textField.textColor = .black
        textField.font = .systemFont(ofSize: 16)
        return textField
    }()
    
    private lazy var shareButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            style: .plain,
            target: self,
            action: #selector(share)
        )
        button.tintColor = .white
        button.isEnabled = false
        return button
    }()
    
    // MARK: - Lifecycle
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    @objc private func selectPhoto() {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 1
        config.filter = .images
        let vc = PHPickerViewController(configuration: config)
        vc.delegate = self
        present(vc, animated: true)
    }
    
    // MARK: - Private methods
    @objc private func scanQRCode() {
        let scannerViewController = ScannerViewController()
        let navigationController = UINavigationController(rootViewController: scannerViewController)
        scannerViewController.delegate = self
        navigationController.modalPresentationStyle = .pageSheet
        present(navigationController, animated: true)
    }
    
    @objc private func generateQRCode() {
        guard let text = textField.text, !text.isEmpty else {
            showAlert(title: "Ошибка", message: "Текстовое поле пустое, введите текст и попробуйте снова")
            return
        }
        let qrCode = QRCode(string: text)
        guard let qrCodeImage = try? qrCode?.image() else {
            showAlert(title: "Ошибка", message: "Не удалось сгенерировать QRCode")
            return
        }
        DispatchQueue.main.async {
            self.qrImageView.image = qrCodeImage
            self.shareButton.isEnabled = true
        }
        textField.resignFirstResponder()
    }
    
    @objc private func share() {
        guard let image = qrImageView.image else { return }
        let imageShare: [UIImage] = [image]
        let activityViewController = UIActivityViewController(
            activityItems: imageShare,
            applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = view
        present(activityViewController, animated: true)
    }
    
    private func configureUI() {
        view.backgroundColor = .white
        view.addSubview(scanButton)
        view.addSubview(generateButton)
        view.addSubview(pickerButton)
        view.addSubview(qrImageView)
        view.addSubview(textFieldBackgroundView)
        navigationItem.rightBarButtonItem = shareButton
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barTintColor = .black
        navigationItem.title = "QRCode"
        setupToolbar()
        setConstraints()
    }
    
    private func setupToolbar() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(
            title: "Done",
            style: .done,
            target: self,
            action: #selector(dismissKeyboard)
        )
        let spaceButton = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil
        )
        toolbar.setItems([spaceButton, doneButton], animated: false)
        textField.inputAccessoryView = toolbar
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func setConstraints() {
        scanButton.snp.makeConstraints { make in
            make.width.equalTo(100)
            make.height.equalTo(44)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.trailing.equalToSuperview().offset(-20)
        }
        
        generateButton.snp.makeConstraints { make in
            make.width.equalTo(100)
            make.height.equalTo(44)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.leading.equalToSuperview().offset(20)
        }
        
        pickerButton.snp.makeConstraints { make in
            make.width.equalTo(100)
            make.height.equalTo(44)
            make.centerX.equalToSuperview()
            make.centerY.equalTo(generateButton.snp.centerY)
        }
        
        qrImageView.snp.makeConstraints { make in
            make.width.height.equalTo(240)
            make.centerX.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide).offset(120)
        }
        
        textFieldBackgroundView.snp.makeConstraints { make in
            make.height.equalTo(36)
            make.top.equalTo(qrImageView.snp.bottom).offset(12)
            make.trailing.equalToSuperview().offset(-20)
            make.leading.equalToSuperview().offset(20)
        }
        
        textField.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().offset(8)
            make.verticalEdges.equalToSuperview()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        dismissKeyboard()
    }
}

// MARK: - Extensions
extension MainViewController: ScannerDelegate {
    func receiveQRCodeData(_ data: String) {
        guard data.starts(with: "qwerty://") else {
            print("Not our qr")
            textField.text = data
            return
        }
        let mutatingData = data.dropFirst(9)
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
        
        guard let imageData = Data(base64Encoded: mutatingData) else {
            print(mutatingData)
            return
        }

        qrImageView.image = UIImage(data: imageData)
    }
}

extension MainViewController: PHPickerViewControllerDelegate {
    func picker(_ picker:PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        guard let result = results.first else { return }
        result.itemProvider.loadObject(ofClass: UIImage.self) { reading, error in
            guard
                let image = reading as? UIImage,
                error == nil
            else { return }
            // MARK: - переделала логику обработки изображений таким образом, чтобы он мог конвертировать Image -> Base64
            guard let stringImageData = image.convertToBase64() else { return }
            let qrCode = QRCode(string: stringImageData)
            guard let qrCodeImage = try? qrCode?.image() else { return }
            DispatchQueue.main.async {
                self.qrImageView.image = qrCodeImage
            }
        }
    }
}

