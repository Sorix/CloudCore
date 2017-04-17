//
//  CKRecord.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 02.02.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import CloudKit

extension CKRecord {
	convenience init?(archivedData: Data) {
		let unarchiver = NSKeyedUnarchiver(forReadingWith: archivedData)
		unarchiver.requiresSecureCoding = true
		self.init(coder: unarchiver)
	}
	
	var encdodedSystemFields: Data {
		let archivedData = NSMutableData()
		let archiver = NSKeyedArchiver(forWritingWith: archivedData)
		archiver.requiresSecureCoding = true
		self.encodeSystemFields(with: archiver)
		archiver.finishEncoding()
		
		return archivedData as Data
	}
}
