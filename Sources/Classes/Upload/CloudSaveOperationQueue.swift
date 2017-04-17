//
//  CloudSaveController.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 06.02.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import CloudKit

class CloudSaveOperationQueue: OperationQueue {
	var errorBlock: ErrorBlock?
	
	/// Modify CloudKit database, operations will be created and added to operation queue.
	func addOperations(recordsToSave: [RecordWithDatabase], recordIDsToDelete: [RecordIDWithDatabase]) {
		var datasource = [DatabaseModifyDataSource]()
		
		// Split records to save to databases
		for recordToSave in recordsToSave {
			if let modifier = datasource.find(database: recordToSave.database) {
				modifier.save.append(recordToSave.record)
			} else {
				let newModifier = DatabaseModifyDataSource(database: recordToSave.database)
				newModifier.save.append(recordToSave.record)
				datasource.append(newModifier)
			}
		}
		
		// Split record ids to delete to databases
		for idToDelete in recordIDsToDelete {
			if let modifier = datasource.find(database: idToDelete.database) {
				modifier.delete.append(idToDelete.recordID)
			} else {
				let newModifier = DatabaseModifyDataSource(database: idToDelete.database)
				newModifier.delete.append(idToDelete.recordID)
				datasource.append(newModifier)
			}
		}
		
		let initialSetupOperation = makeSetupOperationIfNeeded()
		
		// Perform
		for databaseModifier in datasource {
			addOperation(recordsToSave: databaseModifier.save, recordIDsToDelete: databaseModifier.delete, database: databaseModifier.database, dependency: initialSetupOperation)
		}
	}
	
	/// - Returns: `SetupOperation` if setup wasn't performed before otherwise `nil` will be returned
	func makeSetupOperationIfNeeded() -> SetupOperation? {
		if SetupOperation.isFinishedBefore { return nil }
		
		let setupOperation = SetupOperation()
		setupOperation.errorBlock = errorBlock
		return setupOperation
	}
	
	private func addOperation(recordsToSave: [CKRecord], recordIDsToDelete: [CKRecordID], database: CKDatabase, dependency: Operation?) {
		// Modify CKRecord Operation
		let modifyOperation = CKModifyRecordsOperation(recordsToSave: recordsToSave, recordIDsToDelete: recordIDsToDelete)
		
		modifyOperation.perRecordCompletionBlock = { record, error in
			if let error = error {
				self.errorBlock?(error)
			} else {
				self.removeCachedAssets(for: record)
			}
		}
		
		modifyOperation.modifyRecordsCompletionBlock = { [weak self] savedRecords, _, error in
			if let error = error {
				self?.errorBlock?(error)
			}
		}
		
		modifyOperation.database = database
		
		if let dependency = dependency {
			modifyOperation.addDependency(dependency)
		}
		
		self.addOperation(modifyOperation)
	}
	
	/// Remove locally cached assets prepared for uploading at CloudKit
	private func removeCachedAssets(for record: CKRecord) {
		for key in record.allKeys() {
			guard let asset = record.value(forKey: key) as? CKAsset else { continue }
			try? FileManager.default.removeItem(at: asset.fileURL)
		}
	}
}

private class DatabaseModifyDataSource {
	let database: CKDatabase
	var save = [CKRecord]()
	var delete = [CKRecordID]()
	
	init(database: CKDatabase) {
		self.database = database
	}
}

extension Sequence where Iterator.Element == DatabaseModifyDataSource {
	func find(database: CKDatabase) -> DatabaseModifyDataSource? {
		for element in self {
			if element.database == database { return element }
		}
		
		return nil
	}
}
