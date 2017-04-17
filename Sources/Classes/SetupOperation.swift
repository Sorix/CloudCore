//
//  SetupOperation.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 19/03/2017.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import Foundation
import CloudKit

public class SetupOperation: Operation {
	// MARK: - Is setup performed
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
	
	// MARK: - Operation
	private let queue = OperationQueue()
	
	override public var qualityOfService: QualityOfService {
		didSet {
			queue.qualityOfService = qualityOfService
		}
	}
	
	public var errorBlock: ErrorBlock?
	
	override public func main() {
		if self.isCancelled { return }
		
		// Create zone
		let createZone = self.createZonesOperation(withNames: [CloudCore.config.zoneID.zoneName])
		
		// Subscriptions
		let container = CKContainer.default()
		let subcribePrivate = self.databaseSubscriptionOperation(database: container.privateCloudDatabase, id: CloudCore.config.subscriptionIDForPrivateDB)
		let subcribeShared = self.databaseSubscriptionOperation(database: container.sharedCloudDatabase, id: CloudCore.config.subscriptionIDForSharedDB)
		
		let fetchPublicSubscriptions = FetchPublicSubscriptionsOperation()
		fetchPublicSubscriptions.errorBlock = errorBlock
		fetchPublicSubscriptions.fetchCompletionBlock = { PublicDatabaseSubscriptions.setCache(from: $0) }
		
		queue.addOperations([createZone, subcribePrivate, subcribeShared, fetchPublicSubscriptions], waitUntilFinished: true)
		
		SetupOperation.isFinishedBefore = true
	}
	
	/// Create new record zones with specified names
	private func createZonesOperation(withNames names: [String]) -> CKModifyRecordZonesOperation {
		assert(!names.isEmpty, "List of zones is empty")
		
		var newZones = [CKRecordZone]()
		for name in names {
			newZones += [CKRecordZone(zoneName: name)]
		}
		
		let recordZoneOperation = CKModifyRecordZonesOperation(recordZonesToSave: newZones, recordZoneIDsToDelete: nil)
		recordZoneOperation.modifyRecordZonesCompletionBlock = {
			if let error = $2 {
				self.errorBlock?(error)
			}
		}
		
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
			if let error = $2 {
				self.errorBlock?(error)
			}
		}
		
		operation.timeoutIntervalForResource = 20
		operation.database = database
		
		return operation
	}
	
	public override func cancel() {
		self.queue.cancelAllOperations()
		super.cancel()
	}
}
