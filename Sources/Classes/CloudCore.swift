//
//  CloudCore.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 06.02.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import CoreData
import CloudKit

open class CloudCore {
	public private(set) static var coreDataListener: CoreDataListener?
	
	public static var config = CloudCoreConfig()
	public static var tokens = Tokens.loadFromUserDefaults()
	
	public typealias NotificationUserInfo = [AnyHashable : Any]
	
	/// Enable observing of changes at local database and saving them to iCloud
	/// - note: if that method was never called before it automaticly invokes `FetchAndSave` operation to load initial data from CloudKit
	public static func observeCoreDataChanges(persistentContainer: NSPersistentContainer, errorDelegate: CloudCoreErrorDelegate?) {
		let errorBlock: ErrorBlock = { errorDelegate?.cloudCore(saveToCloudDidFailed: $0) }
		
		if !SetupOperation.isFinishedBefore {
			fetchAndSave(container: persistentContainer, error: errorBlock, completion: nil)
		}
		
		let listener = CoreDataListener(container: persistentContainer, errorBlock: errorBlock)
		listener.observe()
		self.coreDataListener = listener
	}
	
	/// Remove oberserver that was created by `observeCoreDataChanges` method
	public static func removeCoreDataObserver() {
		coreDataListener?.stopObserving()
		coreDataListener = nil
	}
	
	/// Fetch changes from CloudKit database and save it to CoreData
	///
	/// - Parameters:
	///   - userInfo: notification's user info
	///   - error: block will be called every time when error occurs during process
	///   - completion: called after operation completion
	///   - fetchResult: `FetchResult` enumeration with results of operation. Can be converted to `UIBackgroundFetchResult` to use in background fetch completion calls.
	///			* .noData: if notification doesn't contain CloudCore's data, no fetching was done
	///			* .failed: if any errors have occured during process that status will be set
	///			* .newData: if data is fetched and saved successfully
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
	
	/// Fetch changes from all CloudKit databases and save it to Core Data
	///
	/// - Parameters:
	///   - error: block will be called every time when error occurs during process
	///   - completion: called when fetching and saving are completed
	public static func fetchAndSave(container: NSPersistentContainer, error: ErrorBlock?, completion: (() -> Void)?) {
		DispatchQueue.global(qos: .utility).async {
			let operation = FetchAndSaveOperation(persistentContainer: container)
			operation.errorBlock = error
			operation.completionBlock = completion
			operation.start()
		}
	}
	
	/// Check if notification is CloudKit notification containing CloudCore data
	///
	/// - Parameter userInfo: userInfo of notification
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

