//
//  UploadAllLocalDataOperation.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 12/12/2017.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import Foundation
import CoreData

class UploadAllLocalDataOperation: Operation {
	
	let managedObjectModel: NSManagedObjectModel
	let parentContext: NSManagedObjectContext
	
	var errorBlock: ErrorBlock? {
		didSet {
			converter.errorBlock = errorBlock
			cloudSaveOperationQueue.errorBlock = errorBlock
		}
	}
	
	private let converter = ObjectToRecordConverter()
	private let cloudSaveOperationQueue = CloudSaveOperationQueue()
	
	init(parentContext: NSManagedObjectContext, managedObjectModel: NSManagedObjectModel) {
		self.parentContext = parentContext
		self.managedObjectModel = managedObjectModel
	}
	
	override func main() {
		super.main()
		
		CloudCore.delegate?.willSyncToCloud()
		defer {
			CloudCore.delegate?.didSyncToCloud()
		}
		
		let childContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
		childContext.parent = parentContext
		
		var allManagedObjects = Set<NSManagedObject>()
		for entity in managedObjectModel.cloudCoreEnabledEntities {
			guard let entityName = entity.name else { continue }
			let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
			
			do {
				guard let fetchedObjects = try childContext.fetch(fetchRequest) as? [NSManagedObject] else {
					continue
				}
				
				allManagedObjects.formUnion(fetchedObjects)
			} catch {
				errorBlock?(error)
			}
		}
		
		converter.setUnconfirmedOperations(inserted: allManagedObjects, updated: Set<NSManagedObject>(), deleted: Set<NSManagedObject>())
		let recordsToSave = converter.confirmConvertOperationsAndWait(in: childContext).recordsToSave
		cloudSaveOperationQueue.addOperations(recordsToSave: recordsToSave, recordIDsToDelete: [RecordIDWithDatabase]())
		cloudSaveOperationQueue.waitUntilAllOperationsAreFinished()
		
		do {
			try childContext.save()
		} catch {
			errorBlock?(error)
		}
	}
	
	override func cancel() {
		cloudSaveOperationQueue.cancelAllOperations()
		
		super.cancel()
	}

}
