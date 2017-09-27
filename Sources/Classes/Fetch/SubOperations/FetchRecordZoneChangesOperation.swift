//
//  FetchRecordZoneChangesOperation.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 09.02.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import CloudKit

class FetchRecordZoneChangesOperation: AsynchronousOperation {
	// Set on init
	let tokens: Tokens
	let recordZoneIDs: [CKRecordZoneID]
	let database: CKDatabase
	//
	
	var errorBlock: ErrorBlock?
	var recordChangedBlock: ((CKRecord) -> Void)?
	var recordWithIDWasDeletedBlock: ((CKRecordID) -> Void)?
	
	init(from database: CKDatabase, recordZoneIDs: [CKRecordZoneID], tokens: Tokens) {
		self.tokens = tokens
		self.database = database
		self.recordZoneIDs = recordZoneIDs
		
		super.init()
		
		self.name = "FetchRecordZoneChangesOperation"
	}
	
	override func main() {
		super.main()

		// Set tokens for zones
		var optionsByRecordZoneID = [CKRecordZoneID: CKFetchRecordZoneChangesOptions]()
		for zoneID in recordZoneIDs {
			let options = CKFetchRecordZoneChangesOptions()
			options.previousServerChangeToken = self.tokens.tokensByRecordZoneID[zoneID]
			optionsByRecordZoneID[zoneID] = options
		}
		
		// Init Fetch Operation
		let fetchOperation = CKFetchRecordZoneChangesOperation(recordZoneIDs: recordZoneIDs, optionsByRecordZoneID: optionsByRecordZoneID)
		
		fetchOperation.recordChangedBlock = { self.recordChangedBlock?($0) }
        fetchOperation.recordWithIDWasDeletedBlock = { recordID, _ in
            self.recordWithIDWasDeletedBlock?(recordID)
        }
		fetchOperation.recordZoneChangeTokensUpdatedBlock = { recordZoneID, serverChangeToken, _ in
			self.tokens.tokensByRecordZoneID[recordZoneID] = serverChangeToken
		}
		
		fetchOperation.fetchRecordZoneChangesCompletionBlock = { error in
			if let error = error {
				self.errorBlock?(error)
			}
			
			self.state = .finished
		}
		
		fetchOperation.qualityOfService = self.qualityOfService
		fetchOperation.database = self.database
		fetchOperation.start()
	}
}
