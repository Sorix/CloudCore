//
//  CKRecordID.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 01.03.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import XCTest
import CloudKit

@testable import CloudCore

class CKRecordIDTests: XCTestCase {
	func testRecordIDEncodeDecode() {
		let zoneID = CKRecordZoneID(zoneName: CloudCore.config.zoneID.zoneName, ownerName: CKCurrentUserDefaultName)
		let recordID = CKRecordID(recordName: "testName", zoneID: zoneID)
		
		let encodedString = recordID.encodedString
		let restoredRecordID = CKRecordID(encodedString: encodedString)
		
		XCTAssertEqual(recordID.recordName, restoredRecordID?.recordName)
		XCTAssertEqual(recordID.zoneID, restoredRecordID?.zoneID)
		
	}
}
