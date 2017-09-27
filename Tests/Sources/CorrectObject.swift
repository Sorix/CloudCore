//
//  CorrectManagedObjectRecord.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 02.02.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import XCTest
import CoreData
import CloudKit

@testable import CloudCore

struct CorrectObject {
	let recordData: Data = CKRecord(recordType: "TestEntity").encdodedSystemFields
	let binary = "binary data".data(using: .utf8)!
	let externalBinary = "external binary data".data(using: .utf8)!
	
	let string = "text"
	
	let int16 = Int16.max
	let int32 = Int32.max
	let int64 = Int64.max
	let decimal = NSDecimalNumber.maximum
	let double = Double.greatestFiniteMagnitude
	let float = Float.greatestFiniteMagnitude
	
	let date = Date()
	let bool = true
	
	func insert(in context: NSManagedObjectContext) -> TestEntity {
		let managedObject = TestEntity(context: context)
		
		// Header
		managedObject.recordData = self.recordData as Data
		
		// Binary
		managedObject.binary = binary as Data
		managedObject.externalBinary = externalBinary as Data
		managedObject.transformable = NSData()
		
		// Plain-text
		managedObject.string = self.string
		
		managedObject.int16 = self.int16
		managedObject.int32 = self.int32
		managedObject.int64 = self.int64
		managedObject.decimal = self.decimal
		managedObject.double = self.double
		managedObject.float = self.float
		
		managedObject.date = self.date
		managedObject.bool = self.bool
		
//		// Relationships
//		let user1 = UserEntity(context: context)
//		let user2 = UserEntity(context: context)
//		managedObject.singleRelationship = user1
//		managedObject.manyRelationship = NSSet(array: [user1, user2])
		
		return managedObject
	}
	
	func makeRecord() -> CKRecord {
		let record = CKRecord(recordType: "TestEntity", zoneID: CloudCore.config.zoneID)
		
		let asset = try? CoreDataAttribute.createAsset(for: externalBinary)
		XCTAssertNotNil(asset)
		record.setValue(asset, forKey: "externalBinary")
		
		record.setValue(self.binary, forKey: "binary")
		
		record.setValue(self.string, forKey: "string")
		record.setValue(self.int16, forKey: "int16")
		record.setValue(self.int32, forKey: "int32")
		record.setValue(self.int64, forKey: "int64")
		record.setValue(self.decimal, forKey: "decimal")
		record.setValue(self.double, forKey: "double")
		record.setValue(self.float, forKey: "float")
		record.setValue(self.date, forKey: "date")
		record.setValue(self.bool, forKey: "bool")
		
		return record
	}
}

func assertEqualAttributes(_ managedObject: TestEntity, _ record: CKRecord) {
	// Headers
	if let encodedRecordData = managedObject.recordData as Data? {
		let recordFromObject = CKRecord(archivedData: encodedRecordData)
		
		XCTAssertEqual(recordFromObject?.recordID, record.recordID)
	}

	assertEqualPlainTextAttributes(managedObject, record)
	assertEqualBinaryAttributes(managedObject, record)
}

func assertEqualPlainTextAttributes(_ managedObject: TestEntity, _ record: CKRecord) {
	XCTAssertEqual(managedObject.string, record.value(forKey: "string") as! String?)
	
	let recordInt16 = (record.value(forKey: "int16") as! NSNumber?)?.int16Value ?? 0
	XCTAssertEqual(managedObject.int16, recordInt16)
	
	let recordInt32 = (record.value(forKey: "int32") as! NSNumber?)?.int32Value ?? 0
	XCTAssertEqual(managedObject.int32, recordInt32)
	
	let recordInt64 = (record.value(forKey: "int64") as! NSNumber?)?.int64Value ?? 0
	XCTAssertEqual(managedObject.int64, recordInt64)
	
	let recordDecimal = (record.value(forKey: "decimal") as! NSNumber?)?.decimalValue ?? 0
	XCTAssertEqual(managedObject.decimal as Decimal?, recordDecimal)
	
	let recordDouble = (record.value(forKey: "double") as! NSNumber?)?.doubleValue ?? 0
	XCTAssertEqual(managedObject.double, recordDouble)
	
	let recordFloat = (record.value(forKey: "float") as! NSNumber?)?.floatValue ?? 0
	XCTAssertEqual(managedObject.float, recordFloat)
	
	let recordDate = (record.value(forKey: "date") as! NSDate?)?.timeIntervalSinceReferenceDate
	XCTAssertEqual(managedObject.date?.timeIntervalSinceReferenceDate, recordDate)
	
	let recordBool = record.value(forKey: "bool") as! Bool? ?? false
	XCTAssertEqual(managedObject.bool, recordBool)
	
	XCTAssertEqual(nil, record.value(forKey: "empty") as! String?)
	XCTAssertEqual(managedObject.empty, nil)
}

func assertEqualBinaryAttributes(_ managedObject: TestEntity, _ record: CKRecord) {
	if let recordAsset = record.value(forKey: "externalBinary") as! CKAsset? {
		let downloadedData = try! Data(contentsOf: recordAsset.fileURL)
		XCTAssertEqual(managedObject.externalBinary, downloadedData)
	}
	
	XCTAssertEqual(managedObject.binary, record.value(forKey: "binary") as? Data)
}
