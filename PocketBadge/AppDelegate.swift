//
//  AppDelegate.swift
//  PocketBadge
//
//  Created by Ryan Passage on 7/19/16.
//  Copyright © 2016 Ryan Passage. All rights reserved.
//

import UIKit
import Alamofire

enum Notifications {
    static let RegionEntered = "pocketbadge.notifications.RegionEntered"
    static let RegionExited = "pocketbadge.notifications.RegionExited"
    static let DoorSpotted = "pocketbadge.notifications.DoorSpotted"
    static let DoorUnlocked = "pocketbadge.notifications.DoorUnlocked"
}

extension CLProximity {
    var stringValue: String {
        switch self {
        case .Far:
            return "Far"
        case .Immediate:
            return "Immediate"
        case .Near:
            return "Near"
        case .Unknown:
            return "Unknown"
        }
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let beaconManager = ESTBeaconManager()
    let UUID = NSUUID(UUIDString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D")!
    let apiURL = "https://www.cmwa.com/s2api/unlock"
    var settings = NSUserDefaults.standardUserDefaults()
    let notifications = NSNotificationCenter.defaultCenter()
    
    var isMonitoring = false {
        didSet {
            if isMonitoring {
                let region = CLBeaconRegion(proximityUUID: UUID, identifier: "CMWA Beacons")
                self.beaconManager.startMonitoringForRegion(region)
                print("Started region monitoring")
            }
            else {
                self.beaconManager.stopMonitoringForAllRegions()
                self.beaconManager.stopRangingBeaconsInAllRegions()
                print("Stopped region monitoring")
            }
        }
    }
    
    var recentlyUnlocked: [CLBeacon] = []

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        self.beaconManager.delegate = self
        self.beaconManager.requestAlwaysAuthorization()
        
        UIApplication.sharedApplication().registerUserNotificationSettings(UIUserNotificationSettings(forTypes: .Alert, categories: nil))
        
        self.isMonitoring = true
        
        return true
    }
       
    func unlock(door: CLBeacon) -> Bool {
        if recentlyUnlocked.contains(door) {
            return true
        }
        
        var success = false;
        
        if let username = settings.stringForKey("username"), let password = settings.stringForKey("password") {
            let parameters = ["username": username, "password": password, "facility": String(door.major), "door": String(door.minor)]
            
            /*
            print("POST: \(self.apiURL)")
            
            for (key, value) in parameters {
                print("\(key): \(value)")
            }
            */
            
            Alamofire.request(.POST, self.apiURL, parameters: parameters)
                .responseJSON { [unowned self] response in
                    switch response.result {
                    case .Success(let JSON):
                        let json = JSON as! NSDictionary
                        
                        /*
                        print("JSON returned:")
                        for (key, value) in json {
                            print("\(key): \(value)")
                        }
                        */
                        
                        let jsonSuccess = json.objectForKey("success") as! Bool
                        
                        print("JSON success is \(jsonSuccess)")
                        
                        if jsonSuccess {
                            print("Unlock successful")
                            self.recentlyUnlocked.append(door)

                            let notification = UILocalNotification()
                            let doorLabel = Constants.knownBeacons["\(door.major):\(door.minor)"]
                            notification.alertBody = "Unlocked door: \(doorLabel!)"
                            UIApplication.sharedApplication().presentLocalNotificationNow(notification)
                            
                            self.notifications.postNotificationName(Notifications.DoorUnlocked, object: nil, userInfo: ["door": door])
                            
                            success = true;
                        }
                        else {
                            let error = json.objectForKey("error") as! String
                            print("API returned error: \(error)")
                            success = false
                        }
                        
                    case .Failure(let error):
                        print("POST error: \(error)")
                        success = false
                    }
                }
        }
        else {
            print("Missing username or password in settings.")
            success = false;
        }
        
        return success
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

extension AppDelegate: ESTBeaconManagerDelegate {
    
    // Entered Region
    func beaconManager(manager: AnyObject, didEnterRegion region: CLBeaconRegion) {
        if region.proximityUUID == UUID {
            recentlyUnlocked.removeAll()

            self.beaconManager.startRangingBeaconsInRegion(region)
            notifications.postNotificationName(Notifications.RegionEntered, object: nil, userInfo: ["region": region])
            print("Entered region: \(region.identifier)")
        }
    }
    
    // Exited Region
    func beaconManager(manager: AnyObject, didExitRegion region: CLBeaconRegion) {
        self.beaconManager.stopRangingBeaconsInRegion(region)
        recentlyUnlocked.removeAll()
        
        notifications.postNotificationName(Notifications.RegionExited, object: nil, userInfo: ["region": region])
        print("Exited region: \(region.identifier)")
    }
    
    // ranged a beacon
    func beaconManager(manager: AnyObject, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {
        notifications.postNotificationName(Notifications.DoorSpotted, object: nil, userInfo: ["beacons": beacons])

        if let nearestBeacon = beacons.first {
            if nearestBeacon.proximity == .Immediate || nearestBeacon.proximity == .Near {
                print("Beacon in unlock range (\(nearestBeacon.proximity.stringValue))")

                unlock(nearestBeacon)
            }
        }
    }
    
}









