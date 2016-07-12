//
//  AppDelegate.swift
//  RunIt
//
//  Created by Alex Nikishin on 07/07/2016.
//  Copyright © 2016 Alex Nikishin. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        let component = TestComponent()
        RunIt.add(component: component)
        
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(10 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) { 
            RunIt.remove(component: component)
        }
        
        return true
    }
}

