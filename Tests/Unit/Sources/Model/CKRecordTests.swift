//
//  CKRecord.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 01.03.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import XCTest
import CloudKit

@testable import CloudCore

class CKRecordTests: XCTestCase {
	func testEncodeAndInit() {
		let zoneID = CKRecordZoneID(zoneName: "zone", ownerName: CKCurrentUserDefaultName)
		let record = CKRecord(recordType: "type", zoneID: zoneID)
		record.setValue("testValue", forKey: "testKey")
		
		let encodedData = record.encdodedSystemFields
		guard let restoredRecord = CKRecord(archivedData: encodedData) else {
			XCTFail("Failed to restore record from archivedData")
			return
		}
		
		XCTAssertEqual(restoredRecord.recordID, record.recordID)
		XCTAssertNil(restoredRecord.value(forKey: "testKey"))
	}
}
