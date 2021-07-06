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
    var isShared: Bool { get }
    var shareRecordData: Data? { get set }
    
    func fetchExistingShareRecord(completion: @escaping ((CKShare?, Error?) -> Void))
    func fetchShareRecord(completion: @escaping ((CKShare?, Error?) -> Void))
    func fetchEditablePermissions(completion: @escaping FetchedEditablePermissionsCompletionBlock)
    func setShare(data: Data?, in persistentContainer: NSPersistentContainer)
    func stopSharing(in persistentContainer: NSPersistentContainer, completion: @escaping StopSharingCompletionBlock)
    
}

extension CloudCoreSharing {
    
    public var isOwnedByCurrentUser: Bool {
        get {
            return ownerName == CKCurrentUserDefaultName
        }
    }
    
    public var isShared: Bool {
        get {
            return shareRecordData != nil
        }
    }
    
    public func fetchExistingShareRecord(completion: @escaping ((CKShare?, Error?) -> Void)) {
        if let shareData = shareRecordData {
            let shareForName = CKShare(archivedData: shareData)!
            let database: CKDatabase
            let shareID: CKRecord.ID
            
            if isOwnedByCurrentUser {
                database = CloudCore.config.container.privateCloudDatabase
                
                shareID = shareForName.recordID
            } else {
                database = CloudCore.config.container.sharedCloudDatabase
                
                let zoneID = CKRecordZone.ID(zoneName: CloudCore.config.zoneName, ownerName: ownerName!)
                shareID = CKRecord.ID(recordName: shareForName.recordID.recordName, zoneID: zoneID)
            }
            
            database.fetch(withRecordID: shareID) { record, error in
                completion(record as? CKShare, error)
            }
        } else {
            completion(nil, nil)
        }
    }
    
    public func fetchShareRecord(completion: @escaping ((CKShare?, Error?) -> Void)) {
        let aRecord = try! self.restoreRecordWithSystemFields(for: .private)!
        let title = sharingTitle as CKRecordValue?
        let type = sharingType as CKRecordValue?
        
        fetchExistingShareRecord { share, error in
            if let share = share {
                completion(share, nil)
            } else {
                let newShare = CKShare(rootRecord: aRecord)
                newShare[CKShare.SystemFieldKey.title] = title
                newShare[CKShare.SystemFieldKey.shareType] = type
                
                completion(newShare, nil)
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
    
    public func stopSharing(in persistentContainer: NSPersistentContainer, completion: @escaping StopSharingCompletionBlock) {
        if let shareData = shareRecordData {
            var database = CloudCore.config.container.sharedCloudDatabase
            var ownerUUID = ownerName!
            if ownerUUID == CKCurrentUserDefaultName {
                database = CloudCore.config.container.privateCloudDatabase
                ownerUUID = CloudCore.userRecordName()!
            }
            
            let shareForName = CKShare(archivedData: shareData)!
            let zoneID = CKRecordZone.ID(zoneName: CloudCore.config.zoneName, ownerName: ownerUUID)
            let shareID = CKRecord.ID(recordName: shareForName.recordID.recordName, zoneID: zoneID)
            
            database.delete(withRecordID: shareID) { recordID, error in
                completion(error == nil)
            }
            
            if isOwnedByCurrentUser {
                persistentContainer.performBackgroundPushTask { moc in
                    if let updatedObject = try? moc.existingObject(with: self.objectID) as? CloudCoreSharing {
                        updatedObject.shareRecordData = nil
                        try? moc.save()
                    }
                }
            }
        } else {
            completion(true)
        }
    }
    
}
