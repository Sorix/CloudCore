//
//  AppDelegate.swift
//  CloudTest2
//
//  Created by Vasily Ulianov on 14.02.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import UIKit
import CoreData
import CloudCore

let persistentContainer = (UIApplication.shared.delegate as! AppDelegate).persistentContainer

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate, CloudCoreErrorDelegate {

	// MARK: - CloudCore
	
	func cloudCore(saveToCloudDidFailed error: Error) {
		print("SaveToCloudDidFailed: \(error)")
	}
	
	func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
		// Register for push notifications about changes
		UIApplication.shared.registerForRemoteNotifications()
		
		// Enable uploading changed local data to CoreData
		CloudCore.observeCoreDataChanges(persistentContainer: self.persistentContainer, errorDelegate: self)
		CloudCore.observeCloudKitChanges { (error) in
			print("Error while tried to subscribe for observing CloudKit changes: \(error)")
		}
		
		// Sync on startup if push notifications is missed, disabled etc
		// Also it acts as initial sync if no sync was done before
		CloudCore.fetchAndSave(to: persistentContainer, error: { (error) in
			print("On-startup sync error: \(error)")
		}) { 
			NSLog("On-startup sync completed")
		}
		
		return true
	}
	
	// Notification from CloudKit about changes in remote database
	func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
		// Check if it CloudKit's and CloudCore notification
		if CloudCore.isCloudCoreNotification(withUserInfo: userInfo) {
			// Fetch changed data from iCloud
			CloudCore.fetchAndSave(using: userInfo, to: persistentContainer, error: {
				print("fetchAndSave from didReceiveRemoteNotification error: \($0)")
			}, completion: { (fetchResult) in
				completionHandler(fetchResult.uiBackgroundFetchResult)
			})
		}
	}
	
	func applicationWillTerminate(_ application: UIApplication) {
		// Save tokens on exit used to differential sync
		CloudCore.tokens.saveToUserDefaults()
	}
	
	// MARK: - Default Apple initialization, you can skip that
	
	var window: UIWindow?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		let splitViewController = self.window!.rootViewController as! UISplitViewController
		let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController
		navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
		splitViewController.delegate = self

		self.persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
		
		let masterNavigationController = splitViewController.viewControllers[0] as! UINavigationController
		let controller = masterNavigationController.topViewController as! MasterViewController
		controller.managedObjectContext = self.persistentContainer.viewContext

		return true
	}


	// MARK: Split view

	func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController:UIViewController, onto primaryViewController:UIViewController) -> Bool {
	    guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
	    guard let topAsDetailController = secondaryAsNavController.topViewController as? DetailViewController else { return false }
	    if topAsDetailController.detailItem == nil {
	        // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
	        return true
	    }
	    return false
	}
	
	// MARK: Core Data stack

	lazy var persistentContainer: NSPersistentContainer = {
	    /*
	     The persistent container for the application. This implementation
	     creates and returns a container, having loaded the store for the
	     application to it. This property is optional since there are legitimate
	     error conditions that could cause the creation of the store to fail.
	    */
	    let container = NSPersistentContainer(name: "Model")
	    container.loadPersistentStores(completionHandler: { (storeDescription, error) in
	        if let error = error as NSError? {
	            // Replace this implementation with code to handle the error appropriately.
	            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
	             
	            /*
	             Typical reasons for an error here include:
	             * The parent directory does not exist, cannot be created, or disallows writing.
	             * The persistent store is not accessible, due to permissions or data protection when the device is locked.
	             * The device is out of space.
	             * The store could not be migrated to the current model version.
	             Check the error message to determine what the actual problem was.
	             */
	            fatalError("Unresolved error \(error), \(error.userInfo)")
	        }
	    })
		container.viewContext.automaticallyMergesChangesFromParent = true
	    return container
	}()

	// MARK: Core Data Saving support

	func saveContext () {
	    let context = persistentContainer.viewContext
	    if context.hasChanges {
	        do {
	            try context.save()
	        } catch {
	            // Replace this implementation with code to handle the error appropriately.
	            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
	            let nserror = error as NSError
	            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
	        }
	    }
	}

}

