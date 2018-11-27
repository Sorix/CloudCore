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
	
    static let valueRecordName = "recordName"
	static let valueRecordID = "recordID"
    static let valueRecordData = "recordData"
    
	let entityName: String
    
    let recordName: String
    let recordID: String
	let recordData: String
    
	let isPublic: Bool
    
    func contains(_ attributeName: String) -> Bool {
        switch attributeName {
        case recordName, recordID, recordData:
            return true
        default:
            return false
        }
    }
}
