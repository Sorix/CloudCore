//
//  RecordToCoreDataOperationTests.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 02.03.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import XCTest
import CoreData
import CloudKit

@testable import CloudCore

class RecordToCoreDataOperationTests: CoreDataTestCase {
	
	// - MARK: Tests
	
	func testOperation() {
		let finishExpectation = expectation(description: "conversionFinished")
		let queue = OperationQueue()
		let (convertOperation, record) = makeConvertOperation(in: self.context)
		
		let checkOperation = BlockOperation {
			finishExpectation.fulfill()
		}
		checkOperation.addDependency(convertOperation)
		
		queue.addOperations([convertOperation, checkOperation], waitUntilFinished: false)
		
		wait(for: [finishExpectation], timeout: 2)
		
		self.fetchAndCheck(record: record, in: self.context)
	}
	
	func testOperationsPerformance() {
		measure {
			let backgroundContext = self.persistentContainer.newBackgroundContext()
			let queue = OperationQueue()
			
			for _ in 1...300 {
				let operation = self.makeConvertOperation(in: backgroundContext).operation
				queue.addOperation(operation)
			}
			
			queue.waitUntilAllOperationsAreFinished()
		}
	}
	
	// MARK: - Helper methods
	
	/// - Returns: conversion operation and source test `CKRecord` from what that operation was made
	func makeConvertOperation(in context: NSManagedObjectContext) -> (operation: RecordToCoreDataOperation, testRecord: CKRecord) {
		let record = CorrectObject().makeRecord()
		
		let convertOperation = RecordToCoreDataOperation(parentContext: context, record: record)
		convertOperation.errorBlock = { XCTFail("\($0)") }
		
		return (convertOperation, record)
	}
	
	/// Find NSManagedObject for specified record and assert if values in that object is equal to record's values
	private func fetchAndCheck(record: CKRecord, in context: NSManagedObjectContext) {
		context.performAndWait {
			// Check operation results
			let fetchRequest: NSFetchRequest<TestEntity> = TestEntity.fetchRequest()
			fetchRequest.predicate = NSPredicate(format: "recordName = %@", record.recordID.recordName)
			do {
				guard let managedObject = try context.fetch(fetchRequest).first else {
					XCTFail("Couldn't find converted object")
					return
				}
				
				assertEqualAttributes(managedObject, record)
			} catch {
				XCTFail("\(error)")
			}
		}
	}

}
