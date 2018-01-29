//
//  SubscribeOperation.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 12/12/2017.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import Foundation
import CloudKit

#if !os(watchOS)
@available(watchOS, unavailable)
class SubscribeOperation: AsynchronousOperation {
	
	var errorBlock: ErrorBlock?
	
	private let queue = OperationQueue()

	override func main() {
		super.main()

		let container = CloudCore.config.container
		
		// Subscribe operation
		let subcribeToPrivate = self.makeRecordZoneSubscriptionOperation(for: container.privateCloudDatabase, id: CloudCore.config.subscriptionIDForPrivateDB)
		
		// Fetch subscriptions and cancel subscription operation if subscription is already exists
		let fetchPrivateSubscriptions = makeFetchSubscriptionOperation(for: container.privateCloudDatabase,
																	   searchForSubscriptionID: CloudCore.config.subscriptionIDForPrivateDB,
																	   operationToCancelIfSubcriptionExists: subcribeToPrivate)
		
		subcribeToPrivate.addDependency(fetchPrivateSubscriptions)
		
		// Finish operation
		let finishOperation = BlockOperation {
			self.state = .finished
		}
		finishOperation.addDependency(subcribeToPrivate)
		finishOperation.addDependency(fetchPrivateSubscriptions)
		
		queue.addOperations([subcribeToPrivate, fetchPrivateSubscriptions, finishOperation], waitUntilFinished: false)
	}
	
	private func makeRecordZoneSubscriptionOperation(for database: CKDatabase, id: String) -> CKModifySubscriptionsOperation {
		let notificationInfo = CKNotificationInfo()
		notificationInfo.shouldSendContentAvailable = true
		
		let subscription = CKRecordZoneSubscription(zoneID: CloudCore.config.zoneID, subscriptionID: id)
		subscription.notificationInfo = notificationInfo
		
		let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: [])
		operation.modifySubscriptionsCompletionBlock = {
			if let error = $2 {
				// Cancellation is not an error
				if case CKError.operationCancelled = error { return }
				
				self.errorBlock?(error)
			}
		}
		
		operation.database = database
		
		return operation
	}
	
	private func makeFetchSubscriptionOperation(for database: CKDatabase, searchForSubscriptionID subscriptionID: String, operationToCancelIfSubcriptionExists operationToCancel: CKModifySubscriptionsOperation) -> CKFetchSubscriptionsOperation {
		let fetchSubscriptions = CKFetchSubscriptionsOperation(subscriptionIDs: [subscriptionID])
		fetchSubscriptions.database = database
		fetchSubscriptions.fetchSubscriptionCompletionBlock = { subscriptions, error in
			// If no errors = subscription is found and we don't need to subscribe again
			if error == nil {
				operationToCancel.cancel()
			}
		}
		
		return fetchSubscriptions
	}
	
}
#endif
