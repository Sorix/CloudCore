//
//  CloudCoreSharing.swift
//  CloudCore
//
//  Created by deeje cooley on 5/25/21.
//

import CoreData
import CloudKit

public typealias FetchedEditablePermissionsCompletionBlock = (_ canEdit: Bool) -> Void
public typealias StopSharingCompletionBlock = (_ didStop: Bool) -> Void

public protocol CloudCoreSharing: CloudKitSharing, CloudCoreType {
    
    var isOwnedByCurrentUser: Bool { get }
    var shareRecordData: Data? { get set }
    
    func fetchExistingShareRecord(completion: @escaping ((CKShare?, Error?) -> Void))
    func fetchShareRecord(in persistentContainer: NSPersistentContainer, completion: @escaping ((CKShare?, Error?) -> Void))
    func fetchEditablePermissions(completion: @escaping FetchedEditablePermissionsCompletionBlock)
    func setShare(data: Data?, in persistentContainer: NSPersistentContainer)
    func stopSharing(completion: @escaping StopSharingCompletionBlock)

}

extension CloudCoreSharing {
    
    public var isOwnedByCurrentUser: Bool {
        get {
            return ownerName == CKCurrentUserDefaultName
        }
    }
    
    public func fetchExistingShareRecord(completion: @escaping ((CKShare?, Error?) -> Void)) {
        if let shareData = shareRecordData {
            let aShare = CKShare(archivedData: shareData)!
            
            var database = CloudCore.config.container.sharedCloudDatabase
            var ownerUUID = ownerName!
            if ownerUUID == CKCurrentUserDefaultName {
                database = CloudCore.config.container.privateCloudDatabase
                ownerUUID = CloudCore.userRecordName()!
            }
            
            let zoneID = CKRecordZone.ID(zoneName: CloudCore.config.zoneName, ownerName: ownerUUID)
            let shareID = CKRecord.ID(recordName: aShare.recordID.recordName, zoneID: zoneID)
            database.fetch(withRecordID: shareID) { (record, error) in
                completion(record as? CKShare, error)
            }
        } else {
            completion(nil, nil)
        }
    }
    
    public func fetchShareRecord(in persistentContainer: NSPersistentContainer, completion: @escaping ((CKShare?, Error?) -> Void)) {
        fetchExistingShareRecord { share, error in
            var createIt = false
            if share == nil && error == nil {
                createIt = true
            }
            if let ckError = error as? CKError,
               ckError.code == .unknownItem {
                createIt = true
            }
            if createIt, let aRecord = try? self.restoreRecordWithSystemFields(for: .private) {
                let newShare = CKShare(rootRecord: aRecord)
                newShare[CKShare.SystemFieldKey.title] = self.sharingTitle as CKRecordValue?
                newShare[CKShare.SystemFieldKey.shareType] = self.sharingType as CKRecordValue?
                
                let modOp: CKModifyRecordsOperation = CKModifyRecordsOperation(recordsToSave: [newShare, aRecord], recordIDsToDelete: nil)
                modOp.savePolicy = .ifServerRecordUnchanged
                modOp.modifyRecordsCompletionBlock = {records, recordIDs, error in
                    let savedShare = records?.first as? CKShare
                    if let savedShare = savedShare {
                        let shareData = savedShare.encdodedSystemFields
                        self.setShare(data: shareData, in: persistentContainer)
                    }
                    completion(savedShare, error)
                }
                CloudCore.config.container.privateCloudDatabase.add(modOp)
            } else {
                completion(share, error)
            }
        }
    }
    
    public func fetchEditablePermissions(completion: @escaping FetchedEditablePermissionsCompletionBlock) {
        if isOwnedByCurrentUser {
            completion(true)
        } else {
            fetchExistingShareRecord { record, error in
                var canEdit = false
                
                if let fetchedShare = record {
                    for aParticipant in fetchedShare.participants {
                        if aParticipant.userIdentity.userRecordID?.recordName == CKCurrentUserDefaultName {
                            canEdit = aParticipant.permission == .readWrite
                            break
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    completion(canEdit)
                }
            }
        }
    }
    
    public func setShare(data: Data?, in persistentContainer: NSPersistentContainer) {
        persistentContainer.performBackgroundPushTask { moc in
            if let updatedObject = try? moc.existingObject(with: self.objectID) as? CloudCoreSharing {
                updatedObject.shareRecordData = data
                try? moc.save()
            }
        }
    }
    
    public func stopSharing(completion: @escaping StopSharingCompletionBlock) {
        if isOwnedByCurrentUser {
            completion(false)
            
            return
        }
        
        if let shareData = shareRecordData {
            let sharedDB = CloudCore.config.container.sharedCloudDatabase
            
            let aShare = CKShare(archivedData: shareData)!
            let zoneID = CKRecordZone.ID(zoneName: CloudCore.config.zoneName, ownerName: ownerName!)
            let shareID = CKRecord.ID(recordName: aShare.recordID.recordName, zoneID: zoneID)
            sharedDB.delete(withRecordID: shareID) { recordID, error in
                completion(error == nil)
            }
        }
    }
    
}
