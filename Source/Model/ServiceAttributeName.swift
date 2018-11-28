//
//  ServiceAttributeName.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 11.02.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import CoreData
import CloudKit

struct ServiceAttributeNames {
	// User Info keys & values
	static let keyType = "CloudCoreType"
	static let keyScopes = "CloudCoreScopes"
	
    static let valueRecordName = "recordName"
    static let valuePrivateRecordData = "privateRecordData"
    static let valuePublicRecordData = "publicRecordData"
    
	let entityName: String
    
    let scopes: [CKDatabase.Scope]
    
    let recordName: String
    let privateRecordData: String
    let publicRecordData: String
    
    func contains(_ attributeName: String) -> Bool {
        switch attributeName {
        case recordName, privateRecordData, publicRecordData:
            return true
        default:
            return false
        }
    }
}
