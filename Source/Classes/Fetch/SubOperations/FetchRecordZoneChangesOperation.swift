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
	let recordZoneIDs: [CKRecordZoneID]
	let database: CKDatabase
	//

    var updatedRecords = [CKRecord]()
    var deletedRecordIDs = [CKRecordID]()
    var recordChangedCompletionBlock: ((_ changed:[CKRecord],_ deleted:[CKRecordID]) -> Void)?
	var errorBlock: ((CKRecordZoneID, Error) -> Void)?
	
	private let optionsByRecordZoneID: [CKRecordZoneID: CKFetchRecordZoneChangesOptions]
	private let fetchQueue = OperationQueue()
	
	init(from database: CKDatabase, recordZoneIDs: [CKRecordZoneID], tokens: Tokens) {
		self.tokens = tokens
		self.database = database
		self.recordZoneIDs = recordZoneIDs
		
		var optionsByRecordZoneID = [CKRecordZoneID: CKFetchRecordZoneChangesOptions]()
		for zoneID in recordZoneIDs {
			let options = CKFetchRecordZoneChangesOptions()
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
		self.fetchQueue.addOperation(fetchOperation)
		
		fetchQueue.waitUntilAllOperationsAreFinished()
	}
	
	private func makeFetchOperation(optionsByRecordZoneID: [CKRecordZoneID: CKFetchRecordZoneChangesOptions]) -> CKFetchRecordZoneChangesOperation {
		// Init Fetch Operation
		let fetchOperation = CKFetchRecordZoneChangesOperation(recordZoneIDs: recordZoneIDs, optionsByRecordZoneID: optionsByRecordZoneID)
		
        fetchOperation.recordChangedBlock = {
            self.updatedRecords.append($0)
        }
        fetchOperation.recordWithIDWasDeletedBlock = { recordID, _ in
            self.deletedRecordIDs.append(recordID)
        }
		fetchOperation.recordZoneFetchCompletionBlock = { zoneId, serverChangeToken, clientChangeTokenData, isMore, error in
			self.tokens.tokensByRecordZoneID[zoneId] = serverChangeToken
			
			if let error = error {
				self.errorBlock?(zoneId, error)
			}
			
			if isMore {
				let moreOperation = self.makeFetchOperation(optionsByRecordZoneID: optionsByRecordZoneID)
				self.fetchQueue.addOperation(moreOperation)
            } else {
                self.recordChangedCompletionBlock?(self.updatedRecords, self.deletedRecordIDs)
            }
		}
		
		fetchOperation.qualityOfService = self.qualityOfService
		fetchOperation.database = self.database
		
		return fetchOperation
	}
}
