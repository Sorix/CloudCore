//
//  CloudKitTests.swift
//  CloudKitTests
//
//  Created by Vasily Ulianov on 29/11/2017.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import XCTest
import CloudCore
import CloudKit
import CoreData

@testable import TestableApp

class CloudKitTests: CoreDataTestCase {
	
    override func setUp() {
        super.setUp()
		configureCloudKitIfNeeded()
		CloudKitTests.deleteAllRecordsFromCloudKit()
    }
    
    override class func tearDown() {
        super.tearDown()
		deleteAllRecordsFromCloudKit()
    }
    
    func testLocalToRemote() {
		CloudCore.observeCoreDataChanges(persistentContainer: self.persistentContainer, errorDelegate: self)
		defer {
			CloudCore.removeCoreDataObserver()
		}
		
		let didSyncExpectation = expectation(forNotification: .CloudCoreDidSyncToCloud, object: nil, handler: nil)
		
		// Insert and save managed object
        let object = CorrectObject()
		let testMO = object.insert(in: context)
		object.insertRelationships(in: context, testObject: testMO)
		try! context.save()

		wait(for: [didSyncExpectation], timeout: 10)
		
		// Prepare fresh DB and nullify CloudCore to fetch uploaded data
		CloudCore.removeCoreDataObserver()
		CloudCore.tokens = Tokens()
		let freshPersistentContainer = loadPersistenContainer()
		context.automaticallyMergesChangesFromParent = true
		
		// Fetch data from CloudKit
		let fetchExpectation = expectation(description: "fetchExpectation")
		CloudCore.fetchAndSave(container: freshPersistentContainer, error: { (error) in
			XCTFail("Error while trying to fetch from CloudKit: \(error)")
		}) {
			fetchExpectation.fulfill()
		}
		
		wait(for: [fetchExpectation], timeout: 10)
		
		// Fetch data from CoreData
		let testEntityFetchRequest: NSFetchRequest<TestEntity> = TestEntity.fetchRequest()
		let testEntity = try! freshPersistentContainer.viewContext.fetch(testEntityFetchRequest).first!
		
		object.assertEqualAttributes(to: testEntity)
    }
	
}

extension CloudKitTests: CloudCoreErrorDelegate {
	
	func cloudCore(saveToCloudDidFailed error: Error) {
		XCTFail("saveToCloudDidFailed: \(error)")
	}
	
}
