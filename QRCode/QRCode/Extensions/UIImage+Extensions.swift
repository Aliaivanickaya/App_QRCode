//
//  UIImage+Extensions.swift
//  QRCode
//
//  Created by Алиса Иваницкая on 22.05.2023.
//

import UIKit

extension UIImage {
    func convertToBase64() -> String? {
        let imageData = self.pngData()
        return imageData?.base64EncodedString(options: .lineLength64Characters)
    }
}
