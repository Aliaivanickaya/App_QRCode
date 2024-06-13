//
//  AppDelegate.swift
//  QRCode
//
//  Created by Алиса Иваницкая on 05.04.2023.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {


    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let tabBarController = makeTabBarController()
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = tabBarController
        window?.makeKeyAndVisible()
        return true
    }
    
    private func makeTabBarController() -> UITabBarController {
        
        // Create TabBarController
        let tabBarController = UITabBarController()
        tabBarController.tabBar.isTranslucent = false
        tabBarController.tabBar.barTintColor = .blue
        tabBarController.tabBar.unselectedItemTintColor = .gray
        tabBarController.tabBar.tintColor = .red
        
        // Prepare Main
        let mainVC = MainViewController()
        let mainNavController = UINavigationController(rootViewController: mainVC)
        
        // Prepare AR
        let arVC = QRCodeARViewController()
        let arNavController = UINavigationController(rootViewController: arVC)
        
        
        // Set TabBarItems
        arNavController.tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage(systemName: "cube.transparent"),
            selectedImage: UIImage(systemName: "cube.transparent")
        )
        
        mainNavController.tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage(systemName: "qrcode.viewfinder"),
            selectedImage: UIImage(systemName: "qrcode.viewfinder")
        )
        
        
        tabBarController.viewControllers = [
            mainNavController,
            arNavController
        ]
        
        return tabBarController
    }
}

