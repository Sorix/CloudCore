//
//  FetchRecordZoneChangesOperation.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 09.02.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import CloudKit

class FetchRecordZoneChangesOperation: Operation {
	// Set on init
	let tokens: Tokens
	let recordZoneIDs: [CKRecordZone.ID]
	let database: CKDatabase
	//
	
	var errorBlock: ((CKRecordZone.ID, Error) -> Void)?
	var recordChangedBlock: ((CKRecord) -> Void)?
	var recordWithIDWasDeletedBlock: ((CKRecord.ID) -> Void)?
	
    private let optionsByRecordZoneID: [CKRecordZone.ID: CKFetchRecordZoneChangesOperation.ZoneOptions]
	private let fetchQueue = OperationQueue()
	
	init(from database: CKDatabase, recordZoneIDs: [CKRecordZone.ID], tokens: Tokens) {
		self.tokens = tokens
		self.database = database
		self.recordZoneIDs = recordZoneIDs
		
        var optionsByRecordZoneID = [CKRecordZone.ID: CKFetchRecordZoneChangesOperation.ZoneOptions]()
		for zoneID in recordZoneIDs {
            let options = CKFetchRecordZoneChangesOperation.ZoneOptions()
			options.previousServerChangeToken = self.tokens.tokensByRecordZoneID[zoneID]
			optionsByRecordZoneID[zoneID] = options
		}
		self.optionsByRecordZoneID = optionsByRecordZoneID
		
		super.init()
		
		self.name = "FetchRecordZoneChangesOperation"
	}
	
	override func main() {
		super.main()

		let fetchOperation = self.makeFetchOperation(optionsByRecordZoneID: optionsByRecordZoneID)
		fetchQueue.addOperation(fetchOperation)
		
		fetchQueue.waitUntilAllOperationsAreFinished()
	}
	
    private func makeFetchOperation(optionsByRecordZoneID: [CKRecordZone.ID: CKFetchRecordZoneChangesOperation.ZoneOptions]) -> CKFetchRecordZoneChangesOperation {
		// Init Fetch Operation
		let fetchOperation = CKFetchRecordZoneChangesOperation(recordZoneIDs: recordZoneIDs, optionsByRecordZoneID: optionsByRecordZoneID)
		        
		fetchOperation.recordChangedBlock = {
			self.recordChangedBlock?($0)
		}
		fetchOperation.recordWithIDWasDeletedBlock = { recordID, _ in
			self.recordWithIDWasDeletedBlock?(recordID)
		}
		fetchOperation.recordZoneFetchCompletionBlock = { zoneId, serverChangeToken, clientChangeTokenData, isMore, error in
			self.tokens.tokensByRecordZoneID[zoneId] = serverChangeToken
			
			if let error = error {
				self.errorBlock?(zoneId, error)
			}
			
			if isMore {
				let moreOperation = self.makeFetchOperation(optionsByRecordZoneID: optionsByRecordZoneID)
				self.fetchQueue.addOperation(moreOperation)
			}
		}
		
		fetchOperation.qualityOfService = self.qualityOfService
		fetchOperation.database = self.database
		
		return fetchOperation
	}
}
