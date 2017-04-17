//
//  CloudKitAttribute.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 08.02.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import CloudKit
import CoreData

class CloudKitAttribute {
	let value: Any?
	let entityName: String
	let serviceAttributes: ServiceAttributeNames
	let context: NSManagedObjectContext
	
	init(value: Any?, entityName: String, serviceAttributes: ServiceAttributeNames, context: NSManagedObjectContext) {
		self.value = value
		self.entityName = entityName
		self.serviceAttributes = serviceAttributes
		self.context = context
	}
	
	func makeCoreDataValue() throws -> Any? {
		switch value {
		case let reference as CKReference: return try findManagedObject(for: reference.recordID)
		case let asset as CKAsset: return try Data(contentsOf: asset.fileURL)
		default: return value
		}
	}
	
	private func findManagedObject(for recordID: CKRecordID) throws -> NSManagedObject? {
		let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
		fetchRequest.predicate = NSPredicate(format: serviceAttributes.recordID + " == %@" , recordID.encodedString)
		fetchRequest.fetchLimit = 1
		
		return try context.fetch(fetchRequest).first as? NSManagedObject
	}
}
