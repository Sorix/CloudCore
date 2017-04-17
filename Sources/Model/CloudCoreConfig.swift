//
//  Scheme.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 02.02.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import Foundation
import CloudKit

public struct CloudCoreConfig {
	// CloudKit
	
	/// RecordZone inside private database to store CoreData
	public var zoneID = CKRecordZoneID(zoneName: "CloudCore", ownerName: CKCurrentUserDefaultName)
	let subscriptionIDForPrivateDB = "CloudCorePrivate"
	let subscriptionIDForSharedDB = "CloudCoreShared"
	
	/// subscriptionID's prefix for custom CKSubscription in public databases
	var publicSubscriptionIDPrefix = "CloudCore-"
	
	
	// Core Data
	let contextName = "CloudCoreFetchAndSave"
	public var defaultAttributeNameRecordID = "recordID"
	public var defaultAttributeNameRecordData = "recordData"
	
	// User Default
	public var userDefaultsKeyTokens = "CloudCoreTokens"
	public var userDefaultsKeyIsSetuped = "CloudCoreIsSetuped"
}
