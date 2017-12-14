//
//  CoreDataRelationship.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 04.02.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import CoreData
import CloudKit

class CoreDataRelationship {
	typealias Class = CoreDataRelationship
	
	let value: Any
	let description: NSRelationshipDescription
	
	/// Initialize Core Data Attribute with properties and value
	/// - Returns: `nil` if it is not an attribute (possible it is relationship?)
	init?(value: Any, relationshipName: String, entity: NSEntityDescription) {
		guard let description = Class.relationshipDescription(for: relationshipName, in: entity) else {
			// it is not a relationship
			return nil
		}
		
		self.description = description
		self.value = value
	}
	
	private static func relationshipDescription(for lookupName: String, in entity: NSEntityDescription) -> NSRelationshipDescription? {
		for (name, description) in entity.relationshipsByName {
			if lookupName == name { return description }
		}
		
		return nil
	}

	/// Make reference(s) for relationship
	///
	/// - Returns: `CKReference` or `[CKReference]`
	func makeRecordValue() throws -> Any? {
		if self.description.isToMany {
			if value is NSOrderedSet {
				throw CloudCoreError.orderedSetRelationshipIsNotSupported(description)
			}
			
			guard let objectsSet = value as? NSSet else { return nil }
	
			var referenceList = [CKReference]()
			for (_, managedObject) in objectsSet.enumerated() {
				guard let managedObject = managedObject as? NSManagedObject,
					let reference = try makeReference(from: managedObject) else { continue }

				referenceList.append(reference)
			}
			
			if referenceList.isEmpty { return nil }
			
			return referenceList
		} else {
			guard let object = value as? NSManagedObject else { return nil }
			
			return try makeReference(from: object)
		}
	}
	
	private func makeReference(from managedObject: NSManagedObject) throws -> CKReference? {
		let action: CKReferenceAction
		if case .some(NSDeleteRule.cascadeDeleteRule) = description.inverseRelationship?.deleteRule {
			action = .deleteSelf
		} else {
			action = .none
		}

		guard let record = try managedObject.restoreRecordWithSystemFields() else {
			// That is possible if method is called before all managed object were filled with recordData
			// That may cause possible reference corruption (Core Data -> iCloud), but it is not critical
			assertionFailure("Managed Object doesn't have stored record information, should be reported as a framework bug")
			return nil
		}
		
		return CKReference(record: record, action: action)
	}

}
