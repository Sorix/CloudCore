//
//  CloudKitAttribute.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 08.02.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import CloudKit
import CoreData

enum CloudKitAttributeError: Error {
	case unableToFindTargetEntity
}

class CloudKitAttribute {
	let value: Any?
	let fieldName: String
	let entityName: String
	let serviceAttributes: ServiceAttributeNames
	let context: NSManagedObjectContext
	
	init(value: Any?, fieldName: String, entityName: String, serviceAttributes: ServiceAttributeNames, context: NSManagedObjectContext) {
		self.value = value
		self.fieldName = fieldName
		self.entityName = entityName
		self.serviceAttributes = serviceAttributes
		self.context = context
	}
	
	func makeCoreDataValue() throws -> Any? {
		switch value {
		case let reference as CKReference: return try findManagedObject(for: reference.recordID)
		case let references as [CKReference]:
			let managedObjects = NSMutableSet()
			for ref in references {
				guard let foundObject = try findManagedObject(for: ref.recordID) else { continue }
				managedObjects.add(foundObject)
			}

			if managedObjects.count == 0 { return nil }
			return managedObjects
		case let asset as CKAsset: return try Data(contentsOf: asset.fileURL)
		default: return value
		}
	}
	
	private func findManagedObject(for recordID: CKRecordID) throws -> NSManagedObject? {
		let targetEntityName = try findTargetEntityName()
		let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: targetEntityName)
		
		// FIXME: user serviceAttributes.recordID from target entity (not from me)
		
		fetchRequest.predicate = NSPredicate(format: serviceAttributes.recordID + " == %@" , recordID.encodedString)
		fetchRequest.fetchLimit = 1
		fetchRequest.includesPropertyValues = false
		fetchRequest.includesSubentities = false
		
		let foundObject = try context.fetch(fetchRequest).first as? NSManagedObject
		
		return foundObject
	}
	
	private var myRelationship: NSRelationshipDescription? {
		let myEntity = NSEntityDescription.entity(forEntityName: entityName, in: context)
		return myEntity?.relationshipsByName[fieldName]
	}
	
	private func findTargetEntityName() throws -> String {
		guard let myRelationship = self.myRelationship,
			let destinationEntityName = myRelationship.destinationEntity?.name else {
			throw CloudKitAttributeError.unableToFindTargetEntity
		}
		
		return destinationEntityName
	}
	
}
