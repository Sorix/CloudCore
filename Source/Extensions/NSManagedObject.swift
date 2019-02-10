//
//  NSManagedObject.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 02.02.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import CoreData
import CloudKit

extension NSManagedObject {
	/// Restore record with system fields if that data is saved in recordData attribute (name of attribute is set through user info)
	///
	/// - Returns: unacrhived `CKRecord` containing restored system fields (like RecordID, tokens, creationg date etc)
	/// - Throws: `CloudCoreError.missingServiceAttributes` if names of CloudCore attributes are not specified in User Info
	func restoreRecordWithSystemFields() throws -> CKRecord? {
		guard let serviceAttributeNames = self.entity.serviceAttributeNames else {
			throw CloudCoreError.missingServiceAttributes(entityName: self.entity.name)
		}
		guard let encodedRecordData = self.value(forKey: serviceAttributeNames.recordData) as? Data else { return nil }
		
		return CKRecord(archivedData: encodedRecordData)
	}
	
	
	/// Create new CKRecord, write one's encdodedSystemFields and record id to `self`
	/// - Postcondition: `self` is modified (recordData and recordID is written)
	/// - Throws: may throw exception if unable to find attributes marked by User Info as service attributes
	/// - Returns: new `CKRecord`
	@discardableResult func setRecordInformation() throws -> CKRecord {
		guard let entityName = self.entity.name else {
			throw CloudCoreError.coreData("No entity name for \(self.entity)")
		}
		guard let serviceAttributeNames = self.entity.serviceAttributeNames else {
			throw CloudCoreError.missingServiceAttributes(entityName: self.entity.name)
		}

		let record = CKRecord(recordType: entityName, zoneID: CloudCore.config.zoneID)
		self.setValue(record.encdodedSystemFields, forKey: serviceAttributeNames.recordData)
		self.setValue(record.recordID.encodedString, forKey: serviceAttributeNames.recordID)
		
		return record
	}
}
