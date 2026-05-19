//
//  DGCAppDelegate.swift
//  Example
//
//  Created by long on 2020/8/11.
//

import UIKit

@UIApplicationMain
class DGCAppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        
        let dgc_nav = UINavigationController(rootViewController: DGCViewController())
        self.window?.rootViewController = dgc_nav
        
        self.window?.makeKeyAndVisible()
        
        return true
    }

}

