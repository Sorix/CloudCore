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
    static let valuePrivateRecordID = "privateRecordID"
    static let valuePrivateRecordData = "privateRecordData"
    static let valuePublicRecordID = "publicRecordID"
    static let valuePublicRecordData = "publicRecordData"
    
	let entityName: String
    
    let recordName: String
    let privateRecordID: String
    let privateRecordData: String
    let publicRecordID: String
    let publicRecordData: String

	let isPublic: Bool
    
    func contains(_ attributeName: String) -> Bool {
        switch attributeName {
        case recordName, privateRecordID, privateRecordData, publicRecordID, publicRecordData:
            return true
        default:
            return false
        }
    }
}
