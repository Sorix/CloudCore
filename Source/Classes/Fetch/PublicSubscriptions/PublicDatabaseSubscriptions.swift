//
//  PublicDatabaseSubscriptions.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 13/03/2017.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import CloudKit

// TODO: Temporarily disabled, in development

/// Use that class to manage subscriptions to public CloudKit database. 
/// If you want to sync some records with public database you need to subsrcibe for notifications on that changes to enable iCloud -> Local database syncing.
//class PublicDatabaseSubscriptions {
//	
//	private static var userDefaultsKey: String { return CloudCore.config.userDefaultsKeyTokens }
//	private static var prefix: String { return CloudCore.config.publicSubscriptionIDPrefix }
//	
//	internal(set) static var cachedIDs = UserDefaults.standard.stringArray(forKey: userDefaultsKey) ?? [String]()
//	
//	/// Create `CKQuerySubscription` for public database, use it if you want to enable syncing public iCloud -> Core Data
//	///
//	/// - Parameters:
//	///   - recordType: The string that identifies the type of records to track. You are responsible for naming your app’s record types. This parameter must not be empty string.
//	///   - predicate: The matching criteria to apply to the records. This parameter must not be nil. For information about the operators that are supported in search predicates, see the discussion in [CKQuery](apple-reference-documentation://hsDjQFvil9).
//	///   - completion: returns subscriptionID and error upon operation completion
//	static func subscribe(recordType: String, predicate: NSPredicate, completion: ((_ subscriptionID: String, _ error: Error?) -> Void)?) {
//		let id = prefix + UUID().uuidString
//		let subscription = CKQuerySubscription(recordType: recordType, predicate: predicate, subscriptionID: id, options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion])
//
//		let notificationInfo = CKNotificationInfo()
//		notificationInfo.shouldSendContentAvailable = true
//		subscription.notificationInfo = notificationInfo
//		
//		let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: [])
//		operation.modifySubscriptionsCompletionBlock = { _, _, error in
//			if error == nil {
//				self.cachedIDs.append(subscription.subscriptionID)
//				UserDefaults.standard.set(self.cachedIDs, forKey: self.userDefaultsKey)
//				UserDefaults.standard.synchronize()
//			}
//
//			completion?(subscription.subscriptionID, error)
//		}
//		
//		operation.timeoutIntervalForResource = 20
//		CKContainer.default().publicCloudDatabase.add(operation)
//	}
//	
//	/// Unsubscribe from public database
//	///
//	/// - Parameters:
//	///   - subscriptionID: id of subscription to remove
//	static func unsubscribe(subscriptionID: String, completion: ((Error?) -> Void)?) {
//		let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [], subscriptionIDsToDelete: [subscriptionID])
//		operation.modifySubscriptionsCompletionBlock = { _, _, error in
//			if error == nil {
//				if let index = self.cachedIDs.index(of: subscriptionID) {
//					self.cachedIDs.remove(at: index)
//				}
//				UserDefaults.standard.set(self.cachedIDs, forKey: self.userDefaultsKey)
//				UserDefaults.standard.synchronize()
//			}
//			
//			completion?(error)
//		}
//		
//		operation.timeoutIntervalForResource = 20
//		CKContainer.default().publicCloudDatabase.add(operation)
//	}
//	
//	
//	/// Refresh local `cachedIDs` variable with actual data from CloudKit.
//	/// Recommended to use after application's UserDefaults reset.
//	///
//	/// - Parameter completion: called upon operation completion, contains list of CloudCore subscriptions and error
//	static func refreshCache(errorCompletion: ErrorBlock? = nil, successCompletion: (([CKSubscription]) -> Void)? = nil) {
//		let operation = FetchPublicSubscriptionsOperation()
//		operation.errorBlock = errorCompletion
//		operation.fetchCompletionBlock = { subscriptions in
//			self.setCache(from: subscriptions)
//			successCompletion?(subscriptions)
//		}
//		operation.start()
//	}
//
//	internal static func setCache(from subscriptions: [CKSubscription]) {
//		let ids = subscriptions.map { $0.subscriptionID }
//		self.cachedIDs = ids
//		
//		UserDefaults.standard.set(ids, forKey: self.userDefaultsKey)
//		UserDefaults.standard.synchronize()
//	}
//}

