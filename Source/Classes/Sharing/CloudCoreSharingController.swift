//
//  CloudCoreSharingController.swift
//  CloudCore
//
//  Created by deeje cooley on 5/25/21.
//

#if os(iOS)

import UIKit
import CoreData
import CloudKit

public typealias ConfigureSharingCompletionBlock = (_ sharingController: UICloudSharingController?) -> Void

public class CloudCoreSharingController: NSObject, UICloudSharingControllerDelegate {
    
    let persistentContainer: NSPersistentContainer
    let object: CloudCoreSharing
    
    public init(persistentContainer: NSPersistentContainer, object: CloudCoreSharing) {
        self.persistentContainer = persistentContainer
        self.object = object
    }
    
    public func configureSharingController(permissions: UICloudSharingController.PermissionOptions,
                                           completion: @escaping ConfigureSharingCompletionBlock) {
        
        func commonConfigure(_ sharingController: UICloudSharingController) {
            sharingController.availablePermissions = permissions
            sharingController.delegate = self
            completion(sharingController)
        }
        
        if let aRecord = try? object.restoreRecordWithSystemFields(for: .private) {
            let aShare: CKShare
            if let shareData = object.shareRecordData {
                aShare = CKShare(archivedData: shareData)!
                if object.isOwnedByCurrentUser {
                    CloudCore.config.container.privateCloudDatabase.fetch(withRecordID: aShare.recordID) { (record, error) in
                        if let fetchedShare = record as? CKShare {
                            DispatchQueue.main.async {
                                let sharingController = UICloudSharingController(share: fetchedShare, container: CloudCore.config.container)
                                commonConfigure(sharingController)
                            }
                        } else if let ckError = error as? CKError {
                            switch ckError.code {
                            case .unknownItem:
                                self.object.setShare(data: nil, in: self.persistentContainer)
                            default:
                                break
                            }
                            completion(nil)
                        }
                    }
                } else {
                    let zoneID = CKRecordZone.ID(zoneName: CloudCore.config.zoneName, ownerName: object.ownerName!)
                    let shareID = CKRecord.ID(recordName: aShare.recordID.recordName, zoneID: zoneID)
                    CloudCore.config.container.sharedCloudDatabase.fetch(withRecordID: shareID) { (record, error) in
                        if let fetchedShare = record as? CKShare {
                            DispatchQueue.main.async {
                                let sharingController = UICloudSharingController(share: fetchedShare, container: CloudCore.config.container)
                                commonConfigure(sharingController)
                            }
                        } else {
                            completion(nil)
                        }
                    }
                }
            } else {
                aShare = CKShare(rootRecord: aRecord)
                aShare[CKShare.SystemFieldKey.title] = object.sharingTitle as CKRecordValue?
                aShare[CKShare.SystemFieldKey.shareType] = object.sharingType as CKRecordValue?
                
                let sharingController = UICloudSharingController { (_, handler:
                                                                        @escaping (CKShare?, CKContainer?, Error?) -> Void) in
                    
                    let modifyOp = CKModifyRecordsOperation(recordsToSave: [aRecord, aShare], recordIDsToDelete: nil)
                    modifyOp.savePolicy = .changedKeys
                    modifyOp.modifyRecordsCompletionBlock = { (records, recordIDs, error) in
                        if let share = records?.first as? CKShare {
                            self.object.setShare(data: aShare.encdodedSystemFields, in: self.persistentContainer)
                            
                            handler(share, CloudCore.config.container, error)
                        } else {
                            handler(nil, nil, error)
                        }
                    }
                    modifyOp.savePolicy = .changedKeys
                    CloudCore.config.container.privateCloudDatabase.add(modifyOp)
                }
                
                commonConfigure(sharingController)
            }
        }
    }
    
    public func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
//        os_log(.debug, "failed to save share")
    }
    
    public func itemTitle(for csc: UICloudSharingController) -> String? {
        return object.sharingTitle
    }
    
    public func itemThumbnailData(for csc: UICloudSharingController) -> Data? {
        return object.sharingImage
    }
    
    public func itemType(for csc: UICloudSharingController) -> String? {
        return object.sharingType
    }
    
    public func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
        persistentContainer.performBackgroundTask { moc in
            if let updatedObject = try? moc.existingObject(with: self.object.objectID) as? CloudCoreSharing {
                if updatedObject.isOwnedByCurrentUser {
                    moc.name = CloudCore.config.pushContextName
                    updatedObject.shareRecordData = nil
                } else {
                    moc.delete(updatedObject)
                }
                try? moc.save()
            }
        }
    }
    
}

#endif
