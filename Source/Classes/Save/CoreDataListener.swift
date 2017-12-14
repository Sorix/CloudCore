//
//  CoreDataChangesListener.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 02.02.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

/// Class responsible for taking action on Core Data save notifications
class CoreDataListener {
	var container: NSPersistentContainer
	
	let converter = ObjectToRecordConverter()
	let cloudSaveOperationQueue = CloudSaveOperationQueue()

	let cloudContextName = "CloudCoreSync"
	
	let errorBlock: ErrorBlock?
	
	public init(container: NSPersistentContainer, errorBlock: ErrorBlock?) {
		self.errorBlock = errorBlock
		self.container = container
		
		converter.errorBlock = errorBlock
	}
	
	/// Observe Core Data willSave and didSave notifications
	func observe() {
		NotificationCenter.default.addObserver(self, selector: #selector(self.willSave(notification:)), name: .NSManagedObjectContextWillSave, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.didSave(notification:)), name: .NSManagedObjectContextDidSave, object: nil)
	}
	
	/// Remove Core Data observers
	func stopObserving() {
		NotificationCenter.default.removeObserver(self)
	}
	
	deinit {
		stopObserving()
	}
	
	@objc private func willSave(notification: Notification) {
		guard let context = notification.object as? NSManagedObjectContext else { return }
		
		// Ignore saves that are generated by FetchAndSaveController
		if context.name == CloudCore.config.contextName { return }
		
		// Upload only for changes in root context that will be saved to persistentStore
		if context.parent != nil { return }
		
		converter.setUnconfirmedOperations(inserted: context.insertedObjects,
		                                  updated: context.updatedObjects,
		                                  deleted: context.deletedObjects)
	}
	
	@objc private func didSave(notification: Notification) {
		guard let context = notification.object as? NSManagedObjectContext else { return }
		if context.name == CloudCore.config.contextName { return }
		if context.parent != nil { return }

		if converter.notConfirmedConvertOperations.isEmpty && converter.recordIDsToDelete.isEmpty { return }
		
		DispatchQueue.global(qos: .utility).async { [weak self] in
			guard let listener = self else { return }
			NotificationCenter.default.post(name: .CloudCoreWillSyncToCloud, object: nil)
			
			let backgroundContext = listener.container.newBackgroundContext()
			backgroundContext.name = listener.cloudContextName
			
			let records = listener.converter.confirmConvertOperationsAndWait(in: backgroundContext)
			listener.cloudSaveOperationQueue.errorBlock = { listener.handle(error: $0, parentContext: backgroundContext) }
			listener.cloudSaveOperationQueue.addOperations(recordsToSave: records.recordsToSave, recordIDsToDelete: records.recordIDsToDelete)
			listener.cloudSaveOperationQueue.waitUntilAllOperationsAreFinished()
			
			do {
				if backgroundContext.hasChanges {
					try backgroundContext.save()
				}
			} catch {
				listener.errorBlock?(error)
			}

			NotificationCenter.default.post(name: .CloudCoreDidSyncToCloud, object: nil)
		}
	}
	
	private func handle(error: Error, parentContext: NSManagedObjectContext) {
		guard let cloudError = error as? CKError else {
			errorBlock?(error)
			return
		}

		switch cloudError.code {
		// Zone was accidentally deleted (NOT PURGED), we need to reupload all data accroding Apple Guidelines
		case .zoneNotFound:
			cloudSaveOperationQueue.cancelAllOperations()
			
			// Create CloudCore Zone
			let createZoneOperation = CreateCloudCoreZoneOperation()
			createZoneOperation.errorBlock = {
				self.errorBlock?($0)
				self.cloudSaveOperationQueue.cancelAllOperations()
			}
			
			// Subscribe operation
			#if !os(watchOS)
				let subscribeOperation = SubscribeOperation()
				subscribeOperation.errorBlock = errorBlock
				subscribeOperation.addDependency(createZoneOperation)
				cloudSaveOperationQueue.addOperation(subscribeOperation)
			#endif
			
			// Upload all local data
			let uploadOperation = UploadAllLocalDataOperation(parentContext: parentContext, managedObjectModel: container.managedObjectModel)
			uploadOperation.errorBlock = errorBlock
			
			cloudSaveOperationQueue.addOperations([createZoneOperation, uploadOperation], waitUntilFinished: true)
		case .operationCancelled: return
		default: errorBlock?(cloudError)
		}
	}

}