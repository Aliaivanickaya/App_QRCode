//
//  UIViewController+Extensions.swift
//  QRCode
//
//  Created by Алиса Иваницкая on 18.04.2023.
//

import UIKit

extension UIViewController {
    
    final func showAlert(title: String? = nil, message: String? = nil, style: UIAlertController.Style = .alert, actions: [UIAlertAction]? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: style)
        guard let actions = actions else {
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        for action in actions {
            alert.addAction(action)
        }
        present(alert, animated: true)
    }
}
