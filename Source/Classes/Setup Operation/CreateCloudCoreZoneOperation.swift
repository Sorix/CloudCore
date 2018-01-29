//
//  CreateCloudCoreZoneOperation.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 12/12/2017.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import Foundation
import CloudKit

class CreateCloudCoreZoneOperation: AsynchronousOperation {
	
	var errorBlock: ErrorBlock?
	private var createZoneOperation: CKModifyRecordZonesOperation?
	
	override func main() {
		super.main()

		let cloudCoreZone = CKRecordZone(zoneName: CloudCore.config.zoneID.zoneName)
		let recordZoneOperation = CKModifyRecordZonesOperation(recordZonesToSave: [cloudCoreZone], recordZoneIDsToDelete: nil)
		recordZoneOperation.modifyRecordZonesCompletionBlock = {
			if let error = $2 {
				self.errorBlock?(error)
			}
			
			self.state = .finished
		}
		
		CloudCore.config.container.privateCloudDatabase.add(recordZoneOperation)
		self.createZoneOperation = recordZoneOperation
	}
	
}
