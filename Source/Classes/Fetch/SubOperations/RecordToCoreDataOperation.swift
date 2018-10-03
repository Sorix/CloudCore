//
//  RecordToCoreDataOperation.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 08.02.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import CoreData
import CloudKit

/// Convert CKRecord to NSManagedObject and save it to parent context, thread-safe
class RecordToCoreDataOperation: AsynchronousOperation {
	let parentContext: NSManagedObjectContext
	let record: CKRecord
	var errorBlock: ErrorBlock?
	
    /// - Parameters:
    ///   - parentContext: operation will be safely performed in that context, **operation doesn't save that context** you need to do it manually
    ///   - record: record that will be converted to `NSManagedObject`
	init(parentContext: NSManagedObjectContext, record: CKRecord) {
		self.parentContext = parentContext
		self.record = record
		
		super.init()
		
		self.name = "RecordToCoreDataOperation"
	}
	
	override func main() {
		if self.isCancelled { return }

        parentContext.perform {
            do {
                try self.setManagedObject(in: self.parentContext)
            } catch {
                self.errorBlock?(error)
            }
            
            self.state = .finished
        }
	}
	
	/// Create or update existing NSManagedObject from CKRecord
	///
	/// - Parameter context: child context to perform fetch operations
	private func setManagedObject(in context: NSManagedObjectContext) throws {
		let entityName = record.recordType
		
		guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: context) else {
			throw CloudCoreError.coreData("Unable to find entity specified in CKRecord: " + entityName)
		}
		guard let serviceAttributes = NSEntityDescription.entity(forEntityName: entityName, in: context)?.serviceAttributeNames else {
			throw CloudCoreError.missingServiceAttributes(entityName: entityName)
		}
		
		// Try to find existing objects
		let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
		fetchRequest.predicate = NSPredicate(format: serviceAttributes.recordID + " == %@", record.recordID.encodedString)
		
		if let foundObject = try context.fetch(fetchRequest).first as? NSManagedObject {
			try fill(object: foundObject, entityName: entityName, serviceAttributeNames: serviceAttributes, context: context)
		} else {
			let newObject = NSManagedObject(entity: entity, insertInto: context)
			try fill(object: newObject, entityName: entityName, serviceAttributeNames: serviceAttributes, context: context)
		}
	}
	
	
	/// Fill provided `NSManagedObject` with data
	///
	/// - Parameters:
	///   - entityName: entity name of `object`
	///   - recordDataAttributeName: attribute name containing recordData
	private func fill(object: NSManagedObject, entityName: String, serviceAttributeNames: ServiceAttributeNames, context: NSManagedObjectContext) throws {
		for key in record.allKeys() {
			let recordValue = record.value(forKey: key)
			
			let attribute = CloudKitAttribute(value: recordValue, fieldName: key, entityName: entityName, serviceAttributes: serviceAttributeNames, context: context)
			let coreDataValue = try attribute.makeCoreDataValue()
			object.setValue(coreDataValue, forKey: key)
		}
		
		// Set system headers
		object.setValue(record.recordID.encodedString, forKey: serviceAttributeNames.recordID)
		object.setValue(record.encdodedSystemFields, forKey: serviceAttributeNames.recordData)
	}
}
