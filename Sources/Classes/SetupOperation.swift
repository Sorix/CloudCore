//
//  SetupOperation.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 19/03/2017.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import Foundation
import CloudKit

/**
	An operation that performs initial setup task, have to be run one-time per application installation.
	That operation is automaticly run by every method that is communicating with CloudKit, if `isFinishedBefore` is `false`.

	You can use that method directly (e.g. in "Enable iCloud" view) or use it to debug if that operation doesn't complete
	successfully.
*/
public class SetupOperation: Operation {
	// MARK: Variables
	
	/// Variable indicating if that operation was performed before.
	public static var isFinishedBefore: Bool {
		get {
			if let cachedValue = _isFinishedBefore { return cachedValue }
			
			let defaultsValue = UserDefaults.standard.bool(forKey: CloudCore.config.userDefaultsKeyIsSetuped)
			_isFinishedBefore = defaultsValue
			return defaultsValue
		}
		set {
			_isFinishedBefore = newValue
			UserDefaults.standard.set(newValue, forKey: CloudCore.config.userDefaultsKeyIsSetuped)
			UserDefaults.standard.synchronize()
		}
	}
	static private var _isFinishedBefore: Bool?

	/// The default service level to apply to operations executed using the queue.
	override public var qualityOfService: QualityOfService {
		didSet {
			queue.qualityOfService = qualityOfService
		}
	}
	
	private let queue = OperationQueue()
	
	/// All errors will reported to this block, operation will continue execution even errors were found.
	public var errorBlock: ErrorBlock?
	private let errorProxy = ErrorBlockProxy(destination: nil)
	
	// MARK: Operation methods
	
	/// Performs the receiver’s non-concurrent task.
	override public func main() {
		if self.isCancelled { return }
		
		errorProxy.destination = errorBlock
		
		// Create zone
		let createZone = self.createZonesOperation(withNames: [CloudCore.config.zoneID.zoneName])
		
		// Subscriptions
		let container = CKContainer.default()
		
		// Subscribe operations
		let subcribeToPrivate = self.databaseSubscriptionOperation(database: container.privateCloudDatabase, id: CloudCore.config.subscriptionIDForPrivateDB)
		let subcribeToShared = self.databaseSubscriptionOperation(database: container.sharedCloudDatabase, id: CloudCore.config.subscriptionIDForSharedDB)
		
		// Fetch existing subscriptions
		let fetchPrivateSubscriptions = fetchSubscriptionOperation(in: container.privateCloudDatabase, searchForID: CloudCore.config.subscriptionIDForPrivateDB, cancelOperationIfIDFound: subcribeToPrivate)
		let fetchSharedSubcriptions = fetchSubscriptionOperation(in: container.sharedCloudDatabase, searchForID: CloudCore.config.subscriptionIDForSharedDB, cancelOperationIfIDFound: subcribeToShared)
		
//		let fetchPublicSubscriptions = FetchPublicSubscriptionsOperation()
//		fetchPublicSubscriptions.errorBlock = errorBlock
//		fetchPublicSubscriptions.fetchCompletionBlock = { PublicDatabaseSubscriptions.setCache(from: $0) }
		
		queue.addOperations([createZone, fetchPrivateSubscriptions, fetchSharedSubcriptions, subcribeToPrivate, subcribeToShared], waitUntilFinished: true)
		
		if !errorProxy.wasError {
			SetupOperation.isFinishedBefore = true
		}
	}
	
	
	/** Fetch subscriptions and cancel subscribe operation if we're already subscribe
	- Postcondition: Fetch operation dependecy is added to `subscribeOperation`
	- Parameters:
	   - database: in what database we search for subscriptiong
	   - subscriptionID: check if we're already subscribe for that id
	   - subscribeOperation: cancel that operation if subscription with `subscriptionID` if found
	*/
	private func fetchSubscriptionOperation(in database: CKDatabase, searchForID subscriptionID: String, cancelOperationIfIDFound subscribeOperation: CKModifySubscriptionsOperation) -> CKFetchSubscriptionsOperation {
		let fetchSubscriptions = CKFetchSubscriptionsOperation(subscriptionIDs: [subscriptionID])
		fetchSubscriptions.database = database
		fetchSubscriptions.fetchSubscriptionCompletionBlock = { subscriptions, error in
			// If no errors = subscription is found and we don't need to subscribe again
			if error == nil {
				subscribeOperation.cancel()
			}
		}
		
		// Subscribe operation has no to be performed before fetch operation
		subscribeOperation.addDependency(fetchSubscriptions)
		
		return fetchSubscriptions
	}
	
	/// Create new record zones with specified names
	private func createZonesOperation(withNames names: [String]) -> CKModifyRecordZonesOperation {
		assert(!names.isEmpty, "List of zones is empty")
		
		var newZones = [CKRecordZone]()
		for name in names {
			newZones += [CKRecordZone(zoneName: name)]
		}
		
		let recordZoneOperation = CKModifyRecordZonesOperation(recordZonesToSave: newZones, recordZoneIDsToDelete: nil)
		recordZoneOperation.modifyRecordZonesCompletionBlock = { self.errorProxy.send(error: $2) }
		
		recordZoneOperation.timeoutIntervalForResource = 20
		recordZoneOperation.database = CKContainer.default().privateCloudDatabase
		
		return recordZoneOperation
	}
	
	/// Subscribe to all changes at CloudKit Private & Shared databases
	private func databaseSubscriptionOperation(database: CKDatabase, id: String) -> CKModifySubscriptionsOperation {
		let notificationInfo = CKNotificationInfo()
		notificationInfo.shouldSendContentAvailable = true
		
		let subscription = CKDatabaseSubscription(subscriptionID: id)
		subscription.notificationInfo = notificationInfo
		
		let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: [])
		operation.modifySubscriptionsCompletionBlock = {
			// Cancellation is not an error
			if case .some(CKError.operationCancelled) = $2 { return }
			self.errorProxy.send(error: $2)
		}
		
		operation.timeoutIntervalForResource = 20
		operation.database = database
		
		return operation
	}
	
	/// Advises the operation object that it should stop executing its task.
	override public func cancel() {
		self.queue.cancelAllOperations()
		super.cancel()
	}
}
