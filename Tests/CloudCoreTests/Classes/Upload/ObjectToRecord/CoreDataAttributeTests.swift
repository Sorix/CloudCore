//
//  CoreDataAttributeTests.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 03.03.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import XCTest
import CoreData
import CloudKit

@testable import CloudCore

class CoreDataAttributeTests: CoreDataTestCase {
	func testInitWithRelationship() {
		let incorrectAttribute = CoreDataAttribute(value: "relationship", attributeName: "singleRelationship", entity: TestEntity.entity())
		XCTAssertNil(incorrectAttribute, "Expected nil because it is relationship, not attribute")
	}
	
	func testMakePlainTextAttributes() {
		let correctObject = CorrectObject()
		let managedObject = correctObject.insert(in: context)
		let record = correctObject.makeRecord()
		
		for (_, attributeDescription) in managedObject.entity.attributesByName {
			// Don't check headers, that class is not inteded to convert headers
			if ["recordID", "recordData"].contains(attributeDescription.name) { continue }

			let attributeValue = managedObject.value(forKey: attributeDescription.name)
			
			// Don't test binary here
			if attributeValue is NSData { continue }
			
			let cdAttribute = CoreDataAttribute(value: attributeValue, attributeName: attributeDescription.name, entity: managedObject.entity)
			do {
				let cdValue = try cdAttribute?.makeRecordValue()
				managedObject.setValue(cdValue, forKey: attributeDescription.name)
			} catch {
				XCTFail(error)
			}
		}
		
		assertEqualPlainTextAttributes(managedObject, record)
	}
	
	func testMakeBinaryAttributes() {
		let externalData = "data".data(using: .utf8)!
		let externalAttribute = CoreDataAttribute(value: externalData,
		                                                attributeName: "externalBinary",
		                                                entity: TestEntity.entity())
		
		let externalBigData = Data.random(length: 1025*1024)
		let externalBigAttribute = CoreDataAttribute(value: externalBigData,
		                                             attributeName: "binary",
		                                             entity: TestEntity.entity())
		
		let internalData = "data".data(using: .utf8)!
		let internalAttribute = CoreDataAttribute(value: internalData,
		                                          attributeName: "binary",
		                                          entity: TestEntity.entity())
		
		do {
			// External binary
			if let recordExternalValue = try externalAttribute?.makeRecordValue() as? CKAsset {
				let recordData = try Data(contentsOf: recordExternalValue.fileURL!)
				XCTAssertEqual(recordData, externalData)
			} else {
				XCTFail("External binary isn't stored correctly")
			}
			
			// External big binary
			if let recordExternalValue = try externalBigAttribute?.makeRecordValue() as? CKAsset {
				let recordData = try Data(contentsOf: recordExternalValue.fileURL!)
				XCTAssertEqual(recordData, externalBigData)
			} else {
				XCTFail("External big binary isn't stored correctly")
			}
			
			// Internal binary
			let recordInternalValue = try internalAttribute?.makeRecordValue() as? Data
			XCTAssertEqual(recordInternalValue, internalData)
		} catch {
			XCTFail(error)
		}
	}
}

fileprivate extension Data {
	static func random(length: Int) -> Data {
		let bytes = [UInt32](repeating: 0, count: length).map { _ in arc4random() }
		return Data(bytes: bytes, count: length)
	}
}
