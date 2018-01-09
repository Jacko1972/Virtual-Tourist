//
//  AppDelegate.swift
//  VirtualTourist
//
//  Created by Andrew Jackson on 24/12/2017.
//  Copyright © 2017 Jacko1972. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let stack = CoreDataStack(modelName: "VirtualTourist")!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        stack.save()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        stack.save()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        stack.save()
    }


}

