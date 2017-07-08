//
//  CloudCore.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 06.02.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import CoreData
import CloudKit

/**
	Main framework class, in most cases you will use only methods from that class, all methods/properties are static.

	## Save to cloud
	On application inialization call `observeCoreDataChanges` method, so framework will automatically monitor changes at Core Data and upload it to iCloud.

	### Example

	```swift
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		// Register for push notifications about changes
		UIApplication.shared.registerForRemoteNotifications()
		// Enable uploading changed local data to CoreData
		CloudCore.observeCoreDataChanges(persistentContainer: self.persistentContainer, errorDelegate: nil)
		return true
	}
	```

	## Fetch from cloud
	Updated objects from Core Data can be fetched with `CloudCore.fetchAndSave` methods. If you have called any of CloudCore methods before, CloudCore has automatically subscribed to hidden push notifications about data changes in CloudKit, so after you receive remoteNotifications about that changes, please call appropriate method to redirect that notification to CloudCore and framework will sync data for you.

	If you want you can sync use force sync method.

	Please use method with notification user info parameter if you're calling it from `didReceiveRemoteNotification`, because CloudCore extracts CloudKit database from notification to make less network requests on fetching.

	### Example

	```swift
	func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
		if CloudCore.isCloudCoreNotification(withUserInfo: userInfo) {
			CloudCore.fetchAndSave(using: userInfo, container: self.persistentContainer, error: { error in
				NSLog("CloudKit fetch error: %@", error.localizedDescription)
			}, completion: { (fetchResult) in
				completionHandler(fetchResult.uiBackgroundFetchResult)
			})
		}
	}
	```
*/
open class CloudCore {
	
	// MARK: Properties
	
	private(set) static var coreDataListener: CoreDataListener?
	
	/// CloudCore configuration, it's recommended to set up before calling any of CloudCore methods. You can read more at `CloudCoreConfig` struct description
	public static var config = CloudCoreConfig()
	
	/// `Tokens` object, read more at class description. By default variable is loaded from User Defaults.
	public static var tokens = Tokens.loadFromUserDefaults()
	
	public typealias NotificationUserInfo = [AnyHashable : Any]
	
	// MARK: Save to cloud

	/** Enable observing of changes at local database and saving them to iCloud

	- Parameters:
		- persistentContainer: contextes without parents will be observed in that container, because saving of that context results writing information to disk or memory
		- errorDelegate: all errors that were occurred during upload processes will be reported to `errorDelegat`e and will contain `Error` or `CloudCoreError` objects.
	*/
	public static func observeCoreDataChanges(persistentContainer: NSPersistentContainer, errorDelegate: CloudCoreErrorDelegate?) {
		let errorBlock: ErrorBlock = { errorDelegate?.cloudCore(saveToCloudDidFailed: $0) }
		
		let listener = CoreDataListener(container: persistentContainer, errorBlock: errorBlock)
		listener.observe()
		self.coreDataListener = listener
	}
	
	/// Remove oberserver that was created by `observeCoreDataChanges` method
	public static func removeCoreDataObserver() {
		coreDataListener?.stopObserving()
		coreDataListener = nil
	}
	
	// MARK: Fetch from cloud

	/** Fetch changes from one CloudKit database and save it to CoreData

	Don't forget to check notification's userinfo by calling `isCloudCoreNotification(withUserInfo:)` before calling that method. If incorrect user info is provided `FetchResult.noData` will be returned at completion block.

	- Parameters:
		- userInfo: notification's user info, CloudKit database will be extraced from that notification
		- container: `NSPersistentContainer` that will be used to save fetched data
		- error: block will be called every time when error occurs during process
		- completion: `FetchResult` enumeration with results of operation
	*/
	public static func fetchAndSave(using userInfo: NotificationUserInfo, container: NSPersistentContainer, error: ErrorBlock?, completion: @escaping (_ fetchResult: FetchResult) -> Void) {
		guard let cloudDatabase = self.database(for: userInfo) else {
			completion(.noData)
			return
		}

		DispatchQueue.global(qos: .utility).async {
			let errorProxy = ErrorBlockProxy(destination: error)
			let operation = FetchAndSaveOperation(from: [cloudDatabase], persistentContainer: container)
			operation.errorBlock = { errorProxy.send(error: $0) }
			operation.start()
			
			if errorProxy.wasError {
				completion(FetchResult.failed)
			} else {
				completion(FetchResult.newData)
			}
		}
	}

	/** Fetch changes from all CloudKit databases and save it to Core Data

	- Parameters:
		- container: `NSPersistentContainer` that will be used to save fetched data
		- error: block will be called every time when error occurs during process
		- completion: `FetchResult` enumeration with results of operation
	*/
	public static func fetchAndSave(container: NSPersistentContainer, error: ErrorBlock?, completion: (() -> Void)?) {
		DispatchQueue.global(qos: .utility).async {
			let operation = FetchAndSaveOperation(persistentContainer: container)
			operation.errorBlock = error
			operation.completionBlock = completion
			operation.start()
		}
	}
	
	/** Check if notification is CloudKit notification containing CloudCore data

	 - Parameter userInfo: userInfo of notification
	 - Returns: `true` if notification contains CloudCore data
	*/
	public static func isCloudCoreNotification(withUserInfo userInfo: NotificationUserInfo) -> Bool {
		return (database(for: userInfo) != nil)
	}
	
	static func database(for notificationUserInfo: NotificationUserInfo) -> CKDatabase? {
		guard let notificationDictionary = notificationUserInfo as? [String: NSObject] else { return nil }
		let notification = CKNotification(fromRemoteNotificationDictionary: notificationDictionary)
		
		guard let id = notification.subscriptionID else { return nil }
		
		switch id {
		case config.subscriptionIDForPrivateDB: return CKContainer.default().privateCloudDatabase
		case config.subscriptionIDForSharedDB: return CKContainer.default().sharedCloudDatabase
		case _ where id.hasPrefix(config.publicSubscriptionIDPrefix): return CKContainer.default().publicCloudDatabase
		default: return nil
		}
	}
}
