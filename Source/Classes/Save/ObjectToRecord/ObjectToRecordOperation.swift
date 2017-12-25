//
//  ObjectToRecordOperation.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 09.02.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import CloudKit
import CoreData

class ObjectToRecordOperation: Operation {
	/// Need to set before starting operation, child context from it will be created
	var parentContext: NSManagedObjectContext?
	
	// Set on init
	let record: CKRecord
	private let changedAttributes: [String]?
	private let serviceAttributeNames: ServiceAttributeNames
	//
	
	var errorCompletionBlock: ((Error) -> Void)?
	var conversionCompletionBlock: ((CKRecord) -> Void)?
	
	init(record: CKRecord, changedAttributes: [String]?, serviceAttributeNames: ServiceAttributeNames) {
		self.record = record
		self.changedAttributes = changedAttributes
		self.serviceAttributeNames = serviceAttributeNames
		
		super.init()
		self.name = "ObjectToRecordOperation"
	}
	
	override func main() {
		if self.isCancelled { return }
		guard let parentContext = parentContext else {
			let error = CloudCoreError.coreData("CloudCore framework error")
			errorCompletionBlock?(error)
			return
		}
		
		let childContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
		childContext.parent = parentContext
		
		do {
			try self.fillRecordWithData(using: childContext)
			try childContext.save()
			self.conversionCompletionBlock?(self.record)
		} catch {
			self.errorCompletionBlock?(error)
		}
	}
	
	private func fillRecordWithData(using context: NSManagedObjectContext) throws {
		guard let managedObject = try fetchObject(for: record, using: context) else {
			throw CloudCoreError.coreData("Unable to find managed object for record: \(record)")
		}
		
		let changedValues = managedObject.committedValues(forKeys: changedAttributes)
		
		for (attributeName, value) in changedValues {
			if attributeName == serviceAttributeNames.recordData || attributeName == serviceAttributeNames.recordID { continue }
			
			if let attribute = CoreDataAttribute(value: value, attributeName: attributeName, entity: managedObject.entity) {
				let recordValue = try attribute.makeRecordValue()
				record.setValue(recordValue, forKey: attributeName)
			} else if let relationship = CoreDataRelationship(value: value, relationshipName: attributeName, entity: managedObject.entity) {
				let references = try relationship.makeRecordValue()
				record.setValue(references, forKey: attributeName)
			}
		}
	}
	
	private func fetchObject(for record: CKRecord, using context: NSManagedObjectContext) throws -> NSManagedObject? {
		let entityName = record.recordType
		
		let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
		fetchRequest.predicate = NSPredicate(format: serviceAttributeNames.recordID + " == %@", record.recordID.encodedString)
		
		return try context.fetch(fetchRequest).first as? NSManagedObject
	}
}
