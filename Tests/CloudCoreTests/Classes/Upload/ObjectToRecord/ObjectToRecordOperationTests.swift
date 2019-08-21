//
//  ObjectToRecordOperationTests.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 03.03.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import XCTest
import CoreData
import CloudKit

@testable import CloudCore

class ObjectToRecordOperationTests: CoreDataTestCase {
	
	func createTestObject(in context: NSManagedObjectContext) -> (TestEntity, CKRecord) {
		let managedObject = CorrectObject().insert(in: context)
        let record = try! managedObject.setRecordInformation(for: .private)
		XCTAssertNil(record.value(forKey: "string"))
		
		return (managedObject, record)
	}
	
	func testGoodOperation() {
		let (managedObject, record) = createTestObject(in: context)
        let operation = ObjectToRecordOperation(scope: .private, record: record, changedAttributes: nil, serviceAttributeNames: TestEntity.entity().serviceAttributeNames!)
		let conversionExpectation = expectation(description: "ConversionCompleted")
		
		operation.errorCompletionBlock = { XCTFail($0) }
		operation.conversionCompletionBlock = { record in
			conversionExpectation.fulfill()
			assertEqualAttributes(managedObject, record)
		}
		operation.parentContext = self.context
		operation.start()
		
		waitForExpectations(timeout: 1, handler: nil)
	}
	
	func testContextIsNotDefined() {
		let record = createTestObject(in: context).1
        let operation = ObjectToRecordOperation(scope: .private, record: record, changedAttributes: nil, serviceAttributeNames: TestEntity.entity().serviceAttributeNames!)
		let errorExpectation = expectation(description: "ErrorCalled")

		operation.errorCompletionBlock = { error in
			if case CloudCoreError.coreData = error {
				errorExpectation.fulfill()
			} else {
				XCTFail("Unexpected error received")
			}
		}
		operation.conversionCompletionBlock = { _ in
			XCTFail("Called success completion block while error has been expected")
		}
		
		operation.start()
		waitForExpectations(timeout: 1, handler: nil)
	}
	
	func testNoManagedObjectForOperation() {
		let record = CorrectObject().makeRecord()
		let _ = TestEntity(context: context)
		
        let operation = ObjectToRecordOperation(scope: .private, record: record, changedAttributes: nil, serviceAttributeNames: TestEntity.entity().serviceAttributeNames!)
		operation.parentContext = self.context
		let errorExpectation = expectation(description: "ErrorCalled")
		
		operation.errorCompletionBlock = { error in
			if case CloudCoreError.coreData = error {
				errorExpectation.fulfill()
			} else {
				XCTFail("Unexpected error received")
			}
		}
		operation.conversionCompletionBlock = { _ in
			XCTFail("Called success completion block while error has been expected")
		}
		
		operation.start()
		waitForExpectations(timeout: 1, handler: nil)
	}
	
	func testOperationPerfomance() {
		var records = [CKRecord]()
	
		for _ in 1...300 {
			let record = createTestObject(in: context).1
			records.append(record)
		}
		
		try! context.save()
		
		measure {
			let backgroundContext = self.persistentContainer.newBackgroundContext()
			let queue = OperationQueue()
			
			for record in records {
                let operation = ObjectToRecordOperation(scope: .private, record: record, changedAttributes: nil, serviceAttributeNames: TestEntity.entity().serviceAttributeNames!)
				operation.errorCompletionBlock = { XCTFail($0) }
				operation.parentContext = backgroundContext
				queue.addOperation(operation)
			}
			
			queue.waitUntilAllOperationsAreFinished()
		}
	}
	
}
