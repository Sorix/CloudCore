//
//  DeleteFromCoreDataOperationTests.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 02.03.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import XCTest
import CoreData
import CloudKit

@testable import CloudCore

class DeleteFromCoreDataOperationTests: CoreDataTestCase {
	
	// - MARK: Tests
	
	func testOperation() {
		let remainingObject = TestEntity(context: context)
		do {
            try remainingObject.setRecordInformation(for: .private)
			
			let objectToDelete = TestEntity(context: context)
            let record = try objectToDelete.setRecordInformation(for: .private)
			
			try context.save()
			
			let operation = DeleteFromCoreDataOperation(parentContext: context, recordID: record.recordID)
			operation.start()
			
			XCTAssertTrue(objectToDelete.isDeleted)
			XCTAssertFalse(remainingObject.isDeleted)
		} catch {
			XCTFail(error)
		}
	}
	
	func testOperationPerfomance() {
		// Make dummy objects
		let records = self.insertPerfomanceTestObjects()
		
		measure {
			let backgroundContext = self.persistentContainer.newBackgroundContext()
			
			let queue = OperationQueue()
			
			for record in records {
				let operation = DeleteFromCoreDataOperation(parentContext: backgroundContext, recordID: record.recordID)
				queue.addOperation(operation)
			}
			
			queue.waitUntilAllOperationsAreFinished()
		}
	}
	
	// - MARK: Helper methods
	
	/// Prepare for perfomance test (make and insert test objects)
	///
	/// - Returns: records for inserted test objects
	private func insertPerfomanceTestObjects() -> [CKRecord] {
		var recordsToDelete = [CKRecord]()
		
		for _ in 1...300 {
			let objectToDelete = TestEntity(context: context)
			do {
                let record = try objectToDelete.setRecordInformation(for: .private)
				recordsToDelete.append(record)
			} catch {
				XCTFail(error)
			}
		}
		
		do {
			try context.save()
		} catch {
			XCTFail(error)
		}
		
		return recordsToDelete
	}
	

}
