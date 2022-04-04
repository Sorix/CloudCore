//
//  DeleteCloudCoreZoneOperation.swift
//  CloudCore
//
//  Created by deeje cooley on 4/3/22.
//

import Foundation
import CloudKit

class DeleteCloudCoreZoneOperation: AsynchronousOperation {
    
    var errorBlock: ErrorBlock?
    private var deleteZoneOperation: CKModifyRecordZonesOperation?
    
    public override init() {
        super.init()
        
        name = "CreateCloudCoreZoneOperation"
        qualityOfService = .userInitiated
    }
    
    override func main() {
        super.main()

        let cloudCoreZone = CKRecordZone(zoneName: CloudCore.config.zoneName)
        let recordZoneOperation = CKModifyRecordZonesOperation(recordZonesToSave: nil, recordZoneIDsToDelete: [cloudCoreZone.zoneID])
        recordZoneOperation.qualityOfService = .userInitiated
        recordZoneOperation.modifyRecordZonesCompletionBlock = {
            if let error = $2 {
                self.errorBlock?(error)
            }
            
            self.state = .finished
        }
        
        CloudCore.config.container.privateCloudDatabase.add(recordZoneOperation)
        self.deleteZoneOperation = recordZoneOperation
    }
    
}
