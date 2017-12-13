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
	
	private let queue = OperationQueue()
	
	/// Initialize operation, it's recommended to set `errorBlock`
	///
	/// - Parameters:
	///   - databases: list of databases to fetch data from (only private is supported now)
	///   - persistentContainer: `NSPersistentContainer` that will be used to save data
	///   - tokens: previously saved `Tokens`, you can generate new ones if you want to fetch all data
	public init(from databases: [CKDatabase] = FetchAndSaveOperation.allDatabases, persistentContainer: NSPersistentContainer, tokens: Tokens = CloudCore.tokens) {
		self.tokens = tokens
		self.databases = databases
		self.persistentContainer = persistentContainer
		
		queue.name = "FetchAndSaveQueue"
	}
	
	/// Performs the receiver’s non-concurrent task.
	override public func main() {
		if self.isCancelled { return }

		NotificationCenter.default.post(name: .CloudCoreWillSyncFromCloud, object: nil)
		
		let backgroundContext = persistentContainer.newBackgroundContext()
		backgroundContext.name = CloudCore.config.contextName
		
		for database in self.databases {
			self.addRecordZoneChangesOperation(recordZoneIDs: [CloudCore.config.zoneID], database: database, context: backgroundContext)
		}
		
		self.queue.waitUntilAllOperationsAreFinished()
		
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
		self.queue.cancelAllOperations()
		
		super.cancel()
	}
	
	private func addRecordZoneChangesOperation(recordZoneIDs: [CKRecordZoneID], database: CKDatabase, context: NSManagedObjectContext) {
		if recordZoneIDs.isEmpty { return }
		
		let recordZoneChangesOperation = FetchRecordZoneChangesOperation(from: database, recordZoneIDs: recordZoneIDs, tokens: tokens)
		
		recordZoneChangesOperation.recordChangedBlock = {
			// Convert and write CKRecord To NSManagedObject Operation
			let convertOperation = RecordToCoreDataOperation(parentContext: context, record: $0)
			convertOperation.errorBlock = { self.errorBlock?($0) }
			self.queue.addOperation(convertOperation)
		}
		
		recordZoneChangesOperation.recordWithIDWasDeletedBlock = {
			// Delete NSManagedObject with specified recordID Operation
			let deleteOperation = DeleteFromCoreDataOperation(parentContext: context, recordID: $0)
			deleteOperation.errorBlock = { self.errorBlock?($0) }
			self.queue.addOperation(deleteOperation)
		}
		
		recordZoneChangesOperation.errorBlock = { zoneID, error in
			self.handle(recordZoneChangesError: error, in: zoneID, database: database, context: context)
		}
		
		queue.addOperation(recordZoneChangesOperation)
	}

	private func handle(recordZoneChangesError: Error, in zoneId: CKRecordZoneID, database: CKDatabase, context: NSManagedObjectContext) {
		guard let cloudError = recordZoneChangesError as? CKError else {
			errorBlock?(recordZoneChangesError)
			return
		}
		
		switch cloudError.code {
		// User purged cloud database, we need to delete local cache (according Apple Guidelines)
		case .userDeletedZone:
			queue.cancelAllOperations()
			
			let purgeOperation = PurgeLocalDatabaseOperation(parentContext: context, managedObjectModel: persistentContainer.managedObjectModel)
			purgeOperation.errorBlock = errorBlock
			queue.addOperation(purgeOperation)
			
		// Our token is expired, we need to refetch everything again
		case .changeTokenExpired:
			tokens.serverChangeToken = nil
			tokens.tokensByRecordZoneID[zoneId] = nil
			self.addRecordZoneChangesOperation(recordZoneIDs: [CloudCore.config.zoneID], database: database, context: context)
		default: errorBlock?(cloudError)
		}
	}
	
}
