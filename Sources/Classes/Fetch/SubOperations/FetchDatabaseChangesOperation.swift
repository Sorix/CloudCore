//
//  FetchChangesOperation.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 09.02.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import CloudKit

class FetchDatabaseChangesOperation: AsynchronousOperation {
	// Set on init
	let tokens: Tokens
	let zoneName: String
	let database: CKDatabase
	//
	
	var fetchDatabaseChangesCompletionBlock: (([CKRecordZoneID], Error?) -> Void)?
	
	var changed = [CKRecordZoneID]()
	
	init(from database: CKDatabase, zoneName: String, tokens: Tokens) {
		self.tokens = tokens
		self.database = database
		self.zoneName = zoneName
		
		super.init()
		
		self.name = "FetchDatabaseChangesOperation"
	}
	
	override func main() {
		super.main()
		
		let changesOperation = CKFetchDatabaseChangesOperation(previousServerChangeToken: tokens.serverChangeToken)
		changesOperation.fetchAllChanges = true
		changesOperation.recordZoneWithIDChangedBlock = {
			if $0.zoneName != self.zoneName { return }
			self.changed.append($0)
		}
		changesOperation.changeTokenUpdatedBlock = { self.tokens.serverChangeToken = $0 }
		
		// Fetch completed
		changesOperation.fetchDatabaseChangesCompletionBlock = {
			(newToken: CKServerChangeToken?, _, error: Error?) -> Void in
			self.tokens.serverChangeToken = newToken
			self.fetchDatabaseChangesCompletionBlock?(self.changed, error)
			
			self.state = .finished
		}
		
		changesOperation.qualityOfService = self.qualityOfService
		self.database.add(changesOperation)
	}
}
