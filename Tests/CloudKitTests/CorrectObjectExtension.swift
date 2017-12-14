//
//  CorrectObjectExtension.swift
//  CloudKitTests
//
//  Created by Vasily Ulianov on 29/11/2017.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import XCTest

extension CorrectObject {
	
	func assertEqualAttributes(to managedObject: TestEntity) {
		XCTAssertEqual(managedObject.string, string)
		XCTAssertEqual(managedObject.int16, int16)
		XCTAssertEqual(managedObject.int32, int32)
		XCTAssertEqual(managedObject.int64, int64)
//		XCTAssertEqual(managedObject.decimal as Decimal?, decimal as Decimal) // FIXME
		XCTAssertEqual(managedObject.double, double)
		XCTAssertEqual(managedObject.float, float)
		XCTAssertEqual(managedObject.date?.timeIntervalSinceReferenceDate, date.timeIntervalSinceReferenceDate)
		XCTAssertEqual(managedObject.bool, bool)
		XCTAssertEqual(managedObject.empty, nil)
		
		// Relationships
		XCTAssertEqual(managedObject.singleRelationship?.name, toOneUsername)
		
		for manyObject in managedObject.manyRelationship!.allObjects {
			let userObject = manyObject as! UserEntity
			XCTAssertEqual(userObject.name, toManyUsername)
		}
		
		XCTAssertEqual(managedObject.manyRelationship!.count, manyRelationshipsCount)
	}
	
}
