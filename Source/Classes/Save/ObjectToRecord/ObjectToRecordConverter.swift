//
//  ObjectToRecordConverter.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 09.02.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import CoreData
import CloudKit

class ObjectToRecordConverter {
	enum ManagedObjectChangeType {
		case inserted, updated
	}
	
	var errorBlock: ErrorBlock?
	
	private(set) var notConfirmedConvertOperations = [ObjectToRecordOperation]()
	private let operationQueue = OperationQueue()
	
	private var convertedRecords = [RecordWithDatabase]()
	private(set) var recordIDsToDelete = [RecordIDWithDatabase]()
	
	func setUnconfirmedOperations(inserted: Set<NSManagedObject>, updated: Set<NSManagedObject>, deleted: Set<NSManagedObject>) {
		self.notConfirmedConvertOperations = self.convertOperations(from: inserted, changeType: .inserted)
		self.notConfirmedConvertOperations += self.convertOperations(from: updated, changeType: .updated)
		
		self.recordIDsToDelete = convert(deleted: deleted)
	}
	
	private func convertOperations(from objectSet: Set<NSManagedObject>, changeType: ManagedObjectChangeType) -> [ObjectToRecordOperation] {
		var operations = [ObjectToRecordOperation]()
		
		for object in objectSet {
			// Ignore entities that doesn't have required service attributes
			guard let serviceAttributeNames = object.entity.serviceAttributeNames else { continue }
			
			do {
				let recordWithSystemFields: CKRecord
	
				if let restoredRecord = try object.restoreRecordWithSystemFields() {
					switch changeType {
					case .inserted:
						// Create record with same ID but wihout token data (that record was accidently deleted from CloudKit perhaps, recordID exists in CoreData, but record doesn't exist in CloudKit
						let recordID = restoredRecord.recordID
						recordWithSystemFields = CKRecord(recordType: restoredRecord.recordType, recordID: recordID)
					case .updated:
						recordWithSystemFields = restoredRecord
					}
				} else {
					recordWithSystemFields = try object.setRecordInformation()
				}
				
				var changedAttributes: [String]?
				
				// Save changes keys only for updated object, for inserted objects full sync will be used
				if case .updated = changeType { changedAttributes = Array(object.changedValues().keys) }
				
				let convertOperation = ObjectToRecordOperation(record: recordWithSystemFields,
				                                               changedAttributes: changedAttributes,
				                                               serviceAttributeNames: serviceAttributeNames)

				convertOperation.errorCompletionBlock = { [weak self] error in
					self?.errorBlock?(error)
				}
				
				convertOperation.conversionCompletionBlock = { [weak self] record in
					guard let me = self else { return }
	
					let cloudDatabase = me.database(for: record.recordID, serviceAttributes: serviceAttributeNames)
					let recordWithDB = RecordWithDatabase(record, cloudDatabase)
					me.convertedRecords.append(recordWithDB)
				}
				
				operations.append(convertOperation)
			} catch {
				errorBlock?(error)
			}
		}
		
		return operations
	}
	
	private func convert(deleted objectSet: Set<NSManagedObject>) -> [RecordIDWithDatabase] {
		var recordIDs = [RecordIDWithDatabase]()
		
		for object in objectSet {
			if	let triedRestoredRecord = try? object.restoreRecordWithSystemFields(),
				let restoredRecord = triedRestoredRecord,
				let serviceAttributeNames = object.entity.serviceAttributeNames {
					let database = self.database(for: restoredRecord.recordID, serviceAttributes: serviceAttributeNames)
					let recordIDWithDB = RecordIDWithDatabase(restoredRecord.recordID, database)
					recordIDs.append(recordIDWithDB)
			}
		}
		
		return recordIDs
	}
	
	/// Add all uncofirmed operations to operation queue
	/// - attention: Don't call this method from same context's `perfom`, that will cause deadlock
	func confirmConvertOperationsAndWait(in context: NSManagedObjectContext) -> (recordsToSave: [RecordWithDatabase], recordIDsToDelete: [RecordIDWithDatabase]) {
		for operation in notConfirmedConvertOperations {
			operation.parentContext = context
			operationQueue.addOperation(operation)
		}

		notConfirmedConvertOperations = [ObjectToRecordOperation]()
		operationQueue.waitUntilAllOperationsAreFinished()
		
		let recordsToSave = self.convertedRecords
		let recordIDsToDelete = self.recordIDsToDelete
		
		self.convertedRecords = [RecordWithDatabase]()
		self.recordIDsToDelete = [RecordIDWithDatabase]()
		
		return (recordsToSave, recordIDsToDelete)
	}
	
	/// Get appropriate database for modify operations
	private func database(for recordID: CKRecordID, serviceAttributes: ServiceAttributeNames) -> CKDatabase {
		let container = CloudCore.config.container
		
		if serviceAttributes.isPublic { return container.publicCloudDatabase }
		
		let ownerName = recordID.zoneID.ownerName
		
		if ownerName == CKCurrentUserDefaultName {
			return container.privateCloudDatabase
		} else {
			return container.sharedCloudDatabase
		}
	}
}
