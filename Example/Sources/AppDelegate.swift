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

extension AppDelegate: CloudCoreErrorDelegate {
	
	func cloudCore(error: Error, module: Module?) {
		print("⚠️ CloudCore error detected in module \(String(describing: module)): \(error)")
	}
	
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {

	func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
		// Register for push notifications about changes
		UIApplication.shared.registerForRemoteNotifications()
		
		// Enable uploading changed local data to CoreData
		NotificationsObserver().observe()
		CloudCore.enable(persistentContainer: persistentContainer, errorDelegate: self)
		
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
		return true
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

