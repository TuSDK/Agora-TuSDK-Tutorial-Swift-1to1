//
//  AppDelegate.swift
//  Agora iOS Tutorial
//
//  Created by James Fang on 7/14/16.
//  Copyright © 2016 Agora.io. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        TuSDKManager.shared().initSdk(withAppKey: "304802f7e592c585-04-ewdjn1")
        TUCCore.setLogLevel(.DEBUG)
        TUPEngine.`init`(nil)
        print("TuSDK版本号\(lsqPulseSDKVersion)")
        
        return true
    }
    func applicationWillTerminate(_ application: UIApplication) {
        TUPEngine.terminate()
    }
}
