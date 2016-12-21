//
//  TableViewController.swift
//  PocketBadge
//
//  Created by Ryan Passage on 7/22/16.
//  Copyright © 2016 Ryan Passage. All rights reserved.
//

import UIKit

class DoorTableViewController: UITableViewController {
   
    var beaconsInRange: [CLBeacon] = []
    var currentRegion: String? {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let notifications = NSNotificationCenter.defaultCenter()
        
        notifications.addObserver(self, selector: #selector(updateBeaconsInRange(_:)), name: Notifications.DoorSpotted, object: nil)

        // Handle region notifications
        notifications.addObserverForName(Notifications.RegionEntered, object: nil, queue: nil) { [unowned self] notification in
            // notification.userInfo
            let region = notification.userInfo!["region"] as! CLBeaconRegion
            self.currentRegion = region.identifier
        }

        notifications.addObserverForName(Notifications.RegionExited, object: nil, queue: nil) { [unowned self] notification in
            // notification.userInfo
            self.currentRegion = nil
        }
        
        updateToolbarStatus()
        
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func updateToolbarStatus() {
        let flexibleSpaceItem = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: self, action: nil)
        let textItem = UIBarButtonItem(title: "Searching...", style: .Plain, target: self, action: nil)
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        spinner.hidesWhenStopped = true

        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate

        if appDelegate.isMonitoring {
            textItem.title = "Searching..."
            spinner.startAnimating()
        }
        else {
            textItem.title = "Paused"
            spinner.stopAnimating()
        }
        
        let spinnerItem = UIBarButtonItem(customView: spinner)
        self.setToolbarItems([flexibleSpaceItem, textItem, spinnerItem, flexibleSpaceItem], animated: true)
    }
    
    func updateBeaconsInRange(details: NSNotification) {
        if let beaconsList = details.userInfo!["beacons"] as? [CLBeacon] {
            self.beaconsInRange = beaconsList
            self.tableView.reloadData()
        }
    }

    @IBAction func startStopButtonTapped(sender: UIBarButtonItem) {
        beaconsInRange.removeAll()
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        if appDelegate.isMonitoring {
            appDelegate.isMonitoring = false
            let playButton = UIBarButtonItem(barButtonSystemItem: .Play, target: self, action: #selector(startStopButtonTapped(_:)))
            self.navigationItem.leftBarButtonItem = playButton
        }
        else {
            appDelegate.isMonitoring = true
            let pauseButton = UIBarButtonItem(barButtonSystemItem: .Pause, target: self, action: #selector(startStopButtonTapped(_:)))
            self.navigationItem.leftBarButtonItem = pauseButton
        }
        
        updateToolbarStatus()
    }
    
    
    @IBAction func settingsTapped(sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "Credentials", message: "Enter your Emerge credentials.", preferredStyle: .Alert)
        
        alertController.addTextFieldWithConfigurationHandler { textField in
            textField.placeholder = "User name"
        }
        
        alertController.addTextFieldWithConfigurationHandler { textField in
            textField.placeholder = "Password"
            textField.secureTextEntry = true
        }
        
        // Save
        let saveAction = UIAlertAction(title: "Save", style: .Default) { _ in
            let usernameTextField = alertController.textFields![0] as UITextField
            let passwordTextField = alertController.textFields![1] as UITextField
            let settings = NSUserDefaults.standardUserDefaults()
            
            settings.setObject(usernameTextField.text, forKey: "username")
            settings.setObject(passwordTextField.text, forKey: "password")
        }
        alertController.addAction(saveAction)
        
        
        // Cancel
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { _ in
            return
        }
        alertController.addAction(cancelAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let region = self.currentRegion {
            return "Region: \(region)"
        }
        else {
            return "Not in a region"
        }
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return beaconsInRange.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
        
        let beacon = self.beaconsInRange[indexPath.row]
        
        if let description = Constants.knownBeacons["\(beacon.major):\(beacon.minor)"] {
            cell.textLabel!.text = description
            cell.detailTextLabel!.text = beacon.proximity.stringValue
        } else {
            cell.textLabel!.text = "Unknown Beacon"
            cell.detailTextLabel!.text = beacon.proximity.stringValue
        }
        
        return cell
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
