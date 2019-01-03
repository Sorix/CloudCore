//
//  SetupOperation.swift
//  CloudCore-iOS
//
//  Created by Vasily Ulianov on 13/12/2017.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import Foundation
import CoreData

/**
	Performs several setup operations:

	1. Create CloudCore Zone.
	2. Subscribe to that zone.
	3. Upload all local data to cloud.
*/
class SetupOperation: Operation {
	
	var errorBlock: ErrorBlock?
	let container: NSPersistentContainer
	let parentContext: NSManagedObjectContext?
	
	/// - Parameters:
	///   - container: persistent container to get managedObject model from
	///   - parentContext: context where changed data will be save (recordID's). If it is `nil`, new context will be created from `container` and saved
	init(container: NSPersistentContainer, parentContext: NSManagedObjectContext?) {
		self.container = container
		self.parentContext = parentContext
	}
	
	private let queue = OperationQueue()
	
	override func main() {
		super.main()
		
		let childContext: NSManagedObjectContext
		
		if let parentContext = self.parentContext {
			childContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
			childContext.parent = parentContext
		} else {
			childContext = container.newBackgroundContext()
		}
		
		// Create CloudCore Zone
		let createZoneOperation = CreateCloudCoreZoneOperation()
		createZoneOperation.errorBlock = {
			self.errorBlock?($0)
			self.queue.cancelAllOperations()
		}
		
		// Subscribe operation
		#if !os(watchOS)
		let subscribeOperation = SubscribeOperation()
		subscribeOperation.errorBlock = errorBlock
		subscribeOperation.addDependency(createZoneOperation)
		queue.addOperation(subscribeOperation)
		#endif
			
		// Upload all local data
		let uploadOperation = UploadAllLocalDataOperation(parentContext: childContext, managedObjectModel: container.managedObjectModel)
		uploadOperation.errorBlock = errorBlock
		
		#if !os(watchOS)
		uploadOperation.addDependency(subscribeOperation)
		#endif
			
		queue.addOperations([createZoneOperation, uploadOperation], waitUntilFinished: true)
		
		if self.parentContext == nil {
			do {
				// It's safe to save because we instatinated that context in current thread
				try childContext.save()
			} catch {
				errorBlock?(error)
			}
		}
	}
	
}
