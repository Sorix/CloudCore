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
    
    public var didSaveShare: ((CKShare)->Void)? = nil
    public var didStopSharing: (()->Void)? = nil
    
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
        
        guard let aRecord = try! object.restoreRecordWithSystemFields(for: .private) else { completion(nil); return }
        
        object.fetchShareRecord { share, error in
            guard error == nil, let share = share else { completion(nil); return }
            
            DispatchQueue.main.async {
                if share.participants.count > 1 {
                    let sharingController = UICloudSharingController(share: share, container: CloudCore.config.container)
                    commonConfigure(sharingController)
                } else {
                    let sharingController = UICloudSharingController { _, handler in
                        let modifyOp = CKModifyRecordsOperation(recordsToSave: [aRecord, share], recordIDsToDelete: nil)
                        modifyOp.savePolicy = .changedKeys
                        modifyOp.modifyRecordsCompletionBlock = { records, recordIDs, error in
                            if let share = records?.first as? CKShare {
                                DispatchQueue.main.async {
                                    self.object.setShare(data: share.encdodedSystemFields, in: self.persistentContainer)
                                }
                                
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
    
    public func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
        didSaveShare?(csc.share!)
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
        didStopSharing?()
    }
    
}

#endif
