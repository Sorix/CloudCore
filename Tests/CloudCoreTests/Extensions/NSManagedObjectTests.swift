//
//  NSManagedObjectTests.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 04.02.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import XCTest
import CoreData
import CloudKit

@testable import CloudCore

class NSManagedObjectTests: CoreDataTestCase {
    
	func testRestoreRecordWithSystemFields() {
		let object = TestEntity(context: context)
		do {
            try object.setRecordInformation(for: .private)
			
            let record = try object.restoreRecordWithSystemFields(for: .private)
			XCTAssertEqual(record?.recordType, "TestEntity")
			XCTAssertEqual(record?.recordID.zoneID, CloudCore.config.privateZoneID())
		} catch {
			XCTFail("\(error)")
		}
	}
	
	/// If no record data is saved
	func testRestoreObjectWithoutData() {
		let object = TestEntity(context: context)
		do {
            let record = try object.restoreRecordWithSystemFields(for: .private)
			XCTAssertNil(record)
		} catch {
			XCTFail("\(error)")
		}
	}
	
	// MARK: - Expected throws
	
	func testSetRecordInformationThrow() {
		let object = IncorrectEntity(context: context)
		
        XCTAssertThrowsSpecific(try object.setRecordInformation(for: .private), CloudCoreError.missingServiceAttributes(entityName: "IncorrectEntity"))
	}
	
	func testRestoreRecordThrow() {
		let object = IncorrectEntity(context: context)
		
        XCTAssertThrowsSpecific(try object.restoreRecordWithSystemFields(for: .private), CloudCoreError.missingServiceAttributes(entityName: "IncorrectEntity"))
	}
}
