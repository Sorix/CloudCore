//
//  NSEntityDescription.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 01.03.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import XCTest
import CoreData

@testable import CloudCore

class NSEntityDescriptionTests: CoreDataTestCase {
	func testServiceAttributeNames() {
		let correctObject = TestEntity(context: self.context)
		
		let attributeNames = correctObject.entity.serviceAttributeNames
		XCTAssertEqual(attributeNames?.entityName, "TestEntity")
        XCTAssertEqual(attributeNames?.publicRecordData, "publicRecordData")
        XCTAssertEqual(attributeNames?.privateRecordData, "privateRecordData")
		XCTAssertEqual(attributeNames?.recordName, "recordName")
		
		let incorrectObject = IncorrectEntity(context: self.context)
		XCTAssertNil(incorrectObject.entity.serviceAttributeNames)
	}
}
