//
//  CoreDataRelationshipTests.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 03.03.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import XCTest
import CoreData
import CloudKit

@testable import CloudCore

class CoreDataRelationshipTests: CoreDataTestCase {
	func testInitWithAttribute() {
		let relationship = CoreDataRelationship(value: "attribute", relationshipName: "string", entity: TestEntity.entity())
		XCTAssertNil(relationship, "Expected nil because it is attribute, not relationship")
	}
	
	func testMakeRecordValues() {
		// Generate test model
		let object = TestEntity(context: context)
		try! object.setRecordInformation()
		let filledObjectRecord = try! object.restoreRecordWithSystemFields()!
		
		var manyUsers = [UserEntity]()
		var manyUsersRecordsIDs = [CKRecordID]()
		for _ in 0...2 {
			let user = UserEntity(context: context)
			try! user.setRecordInformation()
			let userRecord = try! user.restoreRecordWithSystemFields()!
			user.recordData = userRecord.encdodedSystemFields
			
			manyUsers.append(user)
			manyUsersRecordsIDs.append(userRecord.recordID)
		}
		
		object.singleRelationship = manyUsers[0]
		object.manyRelationship = NSSet(array: manyUsers)
		
		// Fill testable CKRecord
		for name in object.entity.relationshipsByName.keys {
			let managedObjectValue = object.value(forKey: name)!
			guard let relationship = CoreDataRelationship(value: managedObjectValue, relationshipName: name, entity: object.entity) else {
				XCTFail("Failed to initialize CoreDataRelationship with attribute: \(name)")
				continue
			}
			
			do {
				let recordValue = try relationship.makeRecordValue()
				filledObjectRecord.setValue(recordValue, forKey: name)
			} catch {
				XCTFail("Failed to make record value from attribute: \(name), throwed: \(error)")
			}
		}
		
		// Check single relationship
		let singleReference = filledObjectRecord.value(forKey: "singleRelationship") as! CKReference
		XCTAssertEqual(manyUsersRecordsIDs[0], singleReference.recordID)
		
		// Check many relationships
		let multipleReferences = filledObjectRecord.value(forKey: "manyRelationship") as! [CKReference]
		var filledRecordRelationshipIDs = [CKRecordID]()
		
		for recordReference in multipleReferences {
			filledRecordRelationshipIDs.append(recordReference.recordID)
		}
		
		XCTAssertEqual(Set(manyUsersRecordsIDs), Set(filledRecordRelationshipIDs))
	}
}
