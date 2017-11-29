//
//  Helpers.swift
//  CloudKitTests
//
//  Created by Vasily Ulianov on 29/11/2017.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import XCTest
import CloudKit

@testable import CloudCore

extension CoreDataTestCase {
	
	func configureCloudKitIfNeeded() {
		if UserDefaults.standard.bool(forKey: "isCloudKitConfigured") { return }
		
		CloudCore.observeCoreDataChanges(persistentContainer: persistentContainer, errorDelegate: nil)
		defer {
			CloudCore.removeCoreDataObserver()
		}
		
		let didSyncExpectation = expectation(forNotification: .CloudCoreDidSyncToCloud, object: nil, handler: nil)
		
		let object = CorrectObject()
		let objectMO = object.insert(in: persistentContainer.viewContext)
		
		let user = UserEntity(context: persistentContainer.viewContext)
		user.name = "test"
		user.test = objectMO
		
		try! context.save()
		
		wait(for: [didSyncExpectation], timeout: 10)
		
		let exp = expectation(description: "fetchAndSave")
		
		CloudCore.fetchAndSave(container: persistentContainer, error: { (error) in
			XCTFail("saveToCloudDidFailed: \(error)")
		}) {
			exp.fulfill()
		}
		
		wait(for: [exp], timeout: 20)
		UserDefaults.standard.set(true, forKey: "isCloudKitConfigured")
	}
	
	static func deleteAllRecordsFromCloudKit() {
		let operationQueue = OperationQueue()
		var recordIdsToDelete = [CKRecordID]()
		let publicDatabase = CKContainer.default().privateCloudDatabase
		
		let queries = [
			CKQuery(recordType: "TestEntity", predicate: NSPredicate(value: true)),
			CKQuery(recordType: "UserEntity", predicate: NSPredicate(value: true))
		]
		
		for query in queries {
			let fetchAllOperations = CKQueryOperation(query: query)
			fetchAllOperations.recordFetchedBlock = { recordIdsToDelete.append($0.recordID) }
			fetchAllOperations.queryCompletionBlock = { _, error in
				if let error = error {
					XCTFail("Error while tried to clean test objects: \(error)")
				}
			}
			fetchAllOperations.database = publicDatabase
			operationQueue.addOperation(fetchAllOperations)
		}
		
		operationQueue.waitUntilAllOperationsAreFinished()
		
		if recordIdsToDelete.isEmpty { return }
		
		let deleteOperation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIdsToDelete)
		deleteOperation.modifyRecordsCompletionBlock = { (savedRecords: [CKRecord]?, deletedRecordIDs: [CKRecordID]?, error: Error?) in
			if let error = error {
				XCTFail("Error while tried to clean test objects: \(error)")
			}
		}
		deleteOperation.database = publicDatabase
		operationQueue.addOperation(deleteOperation)
		operationQueue.waitUntilAllOperationsAreFinished()
	}
	
}
