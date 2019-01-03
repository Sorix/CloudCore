//
//  ServiceAttributeName.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 11.02.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import CoreData

struct ServiceAttributeNames {
	// User Info keys & values
	static let keyType = "CloudCoreType"
	static let keyIsPublic = "CloudCorePublicDatabase"
	
	static let valueRecordData = "recordData"
	static let valueRecordID = "recordID"
	
	let entityName: String
	let recordData: String
	let recordID: String
	let isPublic: Bool
}
