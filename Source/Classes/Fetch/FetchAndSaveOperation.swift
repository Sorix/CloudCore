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
	
	/// Private cloud database for the CKContainer specified by CloudCoreConfig
	public static let allDatabases = [
//		CloudCore.config.container.publicCloudDatabase,
		CloudCore.config.container.privateCloudDatabase
//		CloudCore.config.container.sharedCloudDatabase
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

		CloudCore.delegate?.willSyncFromCloud()
		
		let backgroundContext = persistentContainer.newBackgroundContext()
		backgroundContext.name = CloudCore.config.contextName
		
		for database in self.databases {
			self.addRecordZoneChangesOperation(recordZoneIDs: [CloudCore.config.zoneID], database: database, context: backgroundContext)
		}
		
		self.queue.waitUntilAllOperationsAreFinished()

		do {
			try backgroundContext.save()
		} catch {
			errorBlock?(error)
		}
		
		CloudCore.delegate?.didSyncFromCloud()
	}
    
    func dependencyGraph() -> Graph {
        
        let cloudCoreEnabledEntities = self.persistentContainer.managedObjectModel.cloudCoreEnabledEntities
        let entityNames = cloudCoreEnabledEntities.flatMap({$0.name})
        let dependencyGraph: Graph = Graph(vertices: entityNames)
        
        for entityDescription in cloudCoreEnabledEntities {
            guard let name = entityDescription.name else {continue}
            
            for relationshipDescription in entityDescription.relationshipsByName {
                guard let destinationEntityName = relationshipDescription.value.destinationEntity?.name else {continue}
                
                dependencyGraph.addEdge(from: destinationEntityName, to: name)
            }
        }
        return dependencyGraph
    }
    
    
    func createConvertOperationsByRecordType(records:[CKRecord], context:NSManagedObjectContext) -> [String:[Operation]] {
        var operationsByRecordType = [String:[Operation]]()
        for record in records {
            // Convert and write CKRecord To NSManagedObject Operation
            let convertOperation = RecordToCoreDataOperation(parentContext: context, record: record)
            convertOperation.errorBlock = { self.errorBlock?($0) }
            
            var auxOperations = operationsByRecordType[record.recordType] ?? [Operation]()
            auxOperations.append(convertOperation)
            operationsByRecordType[record.recordType] = auxOperations
        }
        return operationsByRecordType
    }
    
	
	private func addRecordZoneChangesOperation(recordZoneIDs: [CKRecordZoneID], database: CKDatabase, context: NSManagedObjectContext) {
		if recordZoneIDs.isEmpty { return }
		
		let recordZoneChangesOperation = FetchRecordZoneChangesOperation(from: database, recordZoneIDs: recordZoneIDs, tokens: tokens)
		
        recordZoneChangesOperation.recordChangedCompletionBlock = { changedRecords, deletedRecordIDs in
            
            // Record Changes
            let operationsByRecordType = self.createConvertOperationsByRecordType(records: changedRecords, context: context)
            let dependencyGraph = self.dependencyGraph()
            
            if let topologicalSort = dependencyGraph.topologicalSort() {
                for recordType in topologicalSort {
                    guard let operations = operationsByRecordType[recordType] else {continue}
                    operations.forEach { changeOperation in
                        self.queue.addOperation(changeOperation)
                    }
                }
            } else {
                
                // Perform all changes many times to fill the all the relationships.
                let cycleLength = dependencyGraph.detectCycles().flatMap({$0.count}).sorted().last ?? 2
                for _ in 0...cycleLength {
                    changedRecords.forEach {record in
                        let convertOperation = RecordToCoreDataOperation(parentContext: context, record: record)
                        convertOperation.errorBlock = { self.errorBlock?($0) }
                        self.queue.addOperation(convertOperation)
                    }
                }
            }
            
            // Record Deletions
            deletedRecordIDs.forEach {
                // Delete NSManagedObject with specified recordID Operation
                let deleteOperation = DeleteFromCoreDataOperation(parentContext: context, recordID: $0)
                deleteOperation.errorBlock = { self.errorBlock?($0) }
                self.queue.addOperation(deleteOperation)
            }
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
			tokens.tokensByRecordZoneID[zoneId] = nil
			self.addRecordZoneChangesOperation(recordZoneIDs: [CloudCore.config.zoneID], database: database, context: context)
		default: errorBlock?(cloudError)
		}
	}
	
}
