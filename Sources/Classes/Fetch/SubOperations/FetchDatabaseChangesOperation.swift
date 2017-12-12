//
//  FetchChangesOperation.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 09.02.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

//import CloudKit
//
//class FetchDatabaseChangesOperation: AsynchronousOperation {
//	// Set on init
//	let tokens: Tokens
//	let zoneName: String
//	let database: CKDatabase
//	//
//	
//	var fetchDatabaseChangesCompletionBlock: ((_ changed: [CKRecordZoneID], _ purged: [CKRecordZoneID], _ deleted: [CKRecordZoneID], _ error: Error?) -> Void)?
//	
//	private(set) var changed = [CKRecordZoneID]()
//	private(set) var purged = [CKRecordZoneID]()
//	private(set) var deleted = [CKRecordZoneID]()
//	
//	init(from database: CKDatabase, zoneName: String, tokens: Tokens) {
//		self.tokens = tokens
//		self.database = database
//		self.zoneName = zoneName
//		
//		super.init()
//		
//		self.name = "FetchDatabaseChangesOperation"
//	}
//	
//	override func main() {
//		super.main()
//		
//		let changesOperation = CKFetchDatabaseChangesOperation(previousServerChangeToken: tokens.serverChangeToken)
//		changesOperation.fetchAllChanges = true
//		changesOperation.recordZoneWithIDChangedBlock = {
//			if $0.zoneName != self.zoneName { return }
//			self.changed.append($0)
//		}
//		
//		if #available(iOS 11.0, *) {
//			changesOperation.recordZoneWithIDWasPurgedBlock = {
//				if $0.zoneName != self.zoneName { return }
//				self.purged.append($0)
//			}
//		}
//		changesOperation.recordZoneWithIDWasDeletedBlock = {
//			if $0.zoneName != self.zoneName { return }
//			self.deleted.append($0)
//		}
//		
//		changesOperation.changeTokenUpdatedBlock = { self.tokens.serverChangeToken = $0 }
//		
//		// Fetch completed
//		changesOperation.fetchDatabaseChangesCompletionBlock = {
//			(newToken: CKServerChangeToken?, _, error: Error?) -> Void in
//			self.tokens.serverChangeToken = newToken
//			self.fetchDatabaseChangesCompletionBlock?(self.changed, self.purged, self.deleted, error)
//			
//			self.state = .finished
//		}
//		
//		changesOperation.qualityOfService = self.qualityOfService
//		self.database.add(changesOperation)
//	}
//}

