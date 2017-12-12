//
//  FetchAndSaveOperation.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 13/03/2017.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import CloudKit
import CoreData

/// An operation that fetches data from CloudKit and saves it to Core Data, you can use it without calling `CloudCore.fetchAndSave` methods if you application relies on `Operation`
public class FetchAndSaveOperation: Operation {
	
	/// Private cloud database
	public static let allDatabases = [
		//		CKContainer.default().publicCloudDatabase,
		CKContainer.default().privateCloudDatabase,
//		CKContainer.default().sharedCloudDatabase
	]
	
	public typealias NotificationUserInfo = [AnyHashable : Any]
	
	private let tokens: Tokens
	private let databases: [CKDatabase]
	private let persistentContainer: NSPersistentContainer
	
	/// Called every time if error occurs
	public var errorBlock: ErrorBlock?
	
	private let fetchOperationQueue = OperationQueue()
	private let coreDataOperationQueue = OperationQueue()
	
	/// Initialize operation, it's recommended to set `errorBlock`
	///
	/// - Parameters:
	///   - databases: list of databases to fetch data from (now supported: private and shared)
	///   - persistentContainer: `NSPersistentContainer` that will be used to save data
	///   - tokens: previously saved `Tokens`, you can generate new ones if you want to fetch all data
	public init(from databases: [CKDatabase] = FetchAndSaveOperation.allDatabases, persistentContainer: NSPersistentContainer, tokens: Tokens = CloudCore.tokens) {
		self.tokens = tokens
		self.databases = databases
		self.persistentContainer = persistentContainer
		
		fetchOperationQueue.name = "CloudCoreFetchFromCloud"
		coreDataOperationQueue.name = "CloudCoreFetchFromCloud CoreData"
	}
	
	/// Performs the receiver’s non-concurrent task.
	override public func main() {
		if self.isCancelled { return }

		NotificationCenter.default.post(name: .CloudCoreWillSyncFromCloud, object: nil)
		
		let backgroundContext = persistentContainer.newBackgroundContext()
		backgroundContext.name = CloudCore.config.contextName
		
		for database in self.databases {
			self.addRecordZoneChangesOperation(recordZoneIDs: [CloudCore.config.zoneID], database: database, parentContext: backgroundContext)
		}
		
		self.fetchOperationQueue.waitUntilAllOperationsAreFinished()
		self.coreDataOperationQueue.waitUntilAllOperationsAreFinished()
		
		do {
			if self.isCancelled { return }
			try backgroundContext.save()
		} catch {
			errorBlock?(error)
		}
		
		NotificationCenter.default.post(name: .CloudCoreDidSyncFromCloud, object: nil)
	}
	
	/// Advises the operation object that it should stop executing its task.
	public override func cancel() {
		self.fetchOperationQueue.cancelAllOperations()
		self.coreDataOperationQueue.cancelAllOperations()
		
		super.cancel()
	}
	
	private func addRecordZoneChangesOperation(recordZoneIDs: [CKRecordZoneID], database: CKDatabase, parentContext: NSManagedObjectContext) {
		if recordZoneIDs.isEmpty { return }
		
		let recordZoneChangesOperation = FetchRecordZoneChangesOperation(from: database, recordZoneIDs: recordZoneIDs, tokens: tokens)
		
		recordZoneChangesOperation.recordChangedBlock = {
			// Convert and write CKRecord To NSManagedObject Operation
			let convertOperation = RecordToCoreDataOperation(parentContext: parentContext, record: $0)
			convertOperation.errorBlock = { self.errorBlock?($0) }
			self.coreDataOperationQueue.addOperation(convertOperation)
		}
		
		recordZoneChangesOperation.recordWithIDWasDeletedBlock = {
			// Delete NSManagedObject with specified recordID Operation
			let deleteOperation = DeleteFromCoreDataOperation(parentContext: parentContext, recordID: $0)
			deleteOperation.errorBlock = { self.errorBlock?($0) }
			self.coreDataOperationQueue.addOperation(deleteOperation)
		}
		
		recordZoneChangesOperation.errorBlock = { self.handle(recordZoneChangesError: $0, parentContext: parentContext) }
		
		fetchOperationQueue.addOperation(recordZoneChangesOperation)
	}

	private func handle(recordZoneChangesError: Error, parentContext: NSManagedObjectContext) {
		guard let cloudError = recordZoneChangesError as? CKError,
			case .userDeletedZone = cloudError.code else {
			errorBlock?(recordZoneChangesError)
			return
		}
		
		// If user purged cloud database, we need to delete local cache (according Apple Guidelines)
		fetchOperationQueue.cancelAllOperations()
		coreDataOperationQueue.cancelAllOperations()

		let purgeOperation = PurgeLocalDatabaseOperation(parentContext: parentContext, managedObjectModel: persistentContainer.managedObjectModel)
		purgeOperation.errorBlock = { self.errorBlock?($0) }
		coreDataOperationQueue.addOperation(purgeOperation)
	}
	
}
