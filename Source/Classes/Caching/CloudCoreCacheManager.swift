//
//  CloudCoreCacheManager.swift
//  CloudCore
//
//  Created by deeje cooley on 4/16/22.
//

import Foundation
import CoreData
import CloudKit
import Network

@objc
class CloudCoreCacheManager: NSObject {
    
    private let persistentContainer: NSPersistentContainer
    private let backgroundContext: NSManagedObjectContext
    private let container: CKContainer
    private let cacheableClassNames: [String]
    
    private var frcs: [AnyObject] = []
    
    public init(persistentContainer: NSPersistentContainer) {
        self.persistentContainer = persistentContainer
        
        let backgroundContext = persistentContainer.newBackgroundContext()
        backgroundContext.automaticallyMergesChangesFromParent = true
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        self.backgroundContext = backgroundContext
        
        self.container = CloudCore.config.container
        
        var cacheableClassNames: [String] = []
        let entities = persistentContainer.managedObjectModel.entities
        for entity in entities {
            if let userInfo = entity.userInfo, userInfo[ServiceAttributeNames.keyCacheable] != nil {
                cacheableClassNames.append(entity.managedObjectClassName!)
            }
        }
        self.cacheableClassNames = cacheableClassNames

        super.init()
        
        restoreLongLivedOperations()
        configureObservers()
    }
    
    func process(cacheables: [CloudCoreCacheable]) {
        for cacheable in cacheables {
            switch cacheable.cacheState {
            case .upload, .uploading:
                upload(cacheableID: cacheable.objectID)
            case .download, .downloading:
                download(cacheableID: cacheable.objectID)
            default:
                break
            }
        }
    }
    
    func update(_ cacheableID: NSManagedObjectID, in context: NSManagedObjectContext, change: @escaping (CloudCoreCacheable) -> Void) {
        context.perform {
            guard let cacheable = try? context.existingObject(with: cacheableID) as? CloudCoreCacheable else { return }
            
            change(cacheable)
            
            try? context.save()
        }
    }
        
    private func configureObservers() {
        let context = backgroundContext
        
        context.perform {
            for name in self.cacheableClassNames {
                let triggerUpload = NSPredicate(format: "%K == %@", "cacheStateRaw", CacheState.upload.rawValue)
                let triggerDownload = NSPredicate(format: "%K == %@", "cacheStateRaw", CacheState.download.rawValue)
                let triggers = NSCompoundPredicate(orPredicateWithSubpredicates: [triggerUpload, triggerDownload])
                
                let triggerRequest = NSFetchRequest<NSManagedObject>(entityName: name)
                triggerRequest.predicate = triggers
                triggerRequest.sortDescriptors = [NSSortDescriptor(key: "cacheStateRaw", ascending: true)]
                
                let frc = NSFetchedResultsController<NSManagedObject>(fetchRequest: triggerRequest,
                                                                      managedObjectContext: context,
                                                                      sectionNameKeyPath: nil,
                                                                      cacheName: nil)
                frc.delegate = self
                
                try? frc.performFetch()
                if let cacheables = frc.fetchedObjects as? [CloudCoreCacheable] {
                    self.process(cacheables: cacheables)
                }
                
                self.frcs.append(frc)
            }
        }
    }
    
    func restoreLongLivedOperations() {
        let context = backgroundContext
        
        context.perform {
            for name in self.cacheableClassNames {
                let uploading = NSPredicate(format: "%K == %@", "cacheStateRaw", CacheState.uploading.rawValue)
                let downloading = NSPredicate(format: "%K == %@", "cacheStateRaw", CacheState.downloading.rawValue)
                let existing = NSCompoundPredicate(orPredicateWithSubpredicates: [uploading, downloading])
                
                let restoreRequest = NSFetchRequest<NSManagedObject>(entityName: name)
                restoreRequest.predicate = existing
                
                if let cacheables = try? context.fetch(restoreRequest) as? [CloudCoreCacheable] {
                    self.process(cacheables: cacheables)
                }
            }
        }
    }
    
    func findLongLivedOperation(with operationID: String) -> CKOperation? {
        var foundOperation: CKOperation? = nil
        
        let semaphore = DispatchSemaphore(value: 0)
        container.fetchLongLivedOperation(withID: operationID) { operation, error in
            if let error = error {
                print("Error fetching operation: \(operationID)\n\(error)")
                // Handle error
                // return
            }
            
            foundOperation = operation as? CKModifyRecordsOperation
            
            semaphore.signal()
        }
        semaphore.wait()
        
        return foundOperation
    }
    
    func longLivedConfiguration() -> CKOperation.Configuration {
        let configuration = CKOperation.Configuration()
        configuration.container = container
        configuration.isLongLived = true
        configuration.qualityOfService = .utility
        
        return configuration
    }
    
    func upload(cacheableID: NSManagedObjectID) {
        let container = container
        let context = backgroundContext
        
        context.perform {
            guard let cacheable = try? context.existingObject(with: cacheableID) as? CloudCoreCacheable else { return }
            
            var modifyOp: CKModifyRecordsOperation!
            if let operationID = cacheable.operationID {
                modifyOp = self.findLongLivedOperation(with: operationID) as? CKModifyRecordsOperation
            }
            
            if modifyOp == nil
            {
                guard let record = try? cacheable.restoreRecordWithSystemFields(for: .private) else { return }
                
                record[cacheable.assetFieldName] = CKAsset(fileURL: cacheable.url)
                record["remoteStatusRaw"] = RemoteStatus.available.rawValue
                
                modifyOp = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
                modifyOp.configuration = self.longLivedConfiguration()
                modifyOp.savePolicy = .changedKeys
                
                cacheable.operationID = modifyOp.operationID
            }
            
            modifyOp.perRecordProgressBlock = { record, progress in
                self.update(cacheableID, in: context) { cacheable in
                    cacheable.uploadProgress = progress
                }
            }
            modifyOp.perRecordCompletionBlock = { record, error in
                if error != nil { return }
                                    
                self.update(cacheableID, in: context) { cacheable in
                    cacheable.uploadProgress = 0
                    cacheable.cacheState = .cached
                }
            }
            modifyOp.modifyRecordsCompletionBlock = { records, recordIDs, error in }
            modifyOp.longLivedOperationWasPersistedBlock = { }
            container.privateCloudDatabase.add(modifyOp)
            
            cacheable.cacheState = .uploading
            try? context.save()
        }
    }
    
    func download(cacheableID: NSManagedObjectID) {
        let container = container
        let context = backgroundContext
        
        context.perform {
            guard let cacheable = try? context.existingObject(with: cacheableID) as? CloudCoreCacheable else { return }
            
            var fetchOp: CKFetchRecordsOperation!
            if let operationID = cacheable.operationID {
                fetchOp = self.findLongLivedOperation(with: operationID) as? CKFetchRecordsOperation
            }
            
            if fetchOp == nil
            {
                guard let record = try? cacheable.restoreRecordWithSystemFields(for: .private) else { return }
                                
                fetchOp = CKFetchRecordsOperation(recordIDs: [record.recordID])
                fetchOp.configuration = self.longLivedConfiguration()
                fetchOp.desiredKeys = [cacheable.assetFieldName]
                
                cacheable.operationID = fetchOp.operationID
            }
            
            fetchOp.perRecordProgressBlock = { record, progress in
                self.update(cacheableID, in: context) { cacheable in
                    cacheable.downloadProgress = progress
                }
            }
            fetchOp.perRecordCompletionBlock = { record, recordID, error in
                if error != nil { return }
                                    
                self.update(cacheableID, in: context) { cacheable in
                    if let asset = record?[cacheable.assetFieldName] as? CKAsset,
                       let downloadURL = asset.fileURL
                    {
                        let fileManager = FileManager.default
                        
                        try? fileManager.moveItem(at: downloadURL, to: cacheable.url)
                    }
                    
                    cacheable.downloadProgress = 0
                    cacheable.cacheState = .cached
                }
            }
            fetchOp.longLivedOperationWasPersistedBlock = { }
            container.privateCloudDatabase.add(fetchOp)
            
            cacheable.cacheState = .uploading
            try? context.save()
        }
    }
    
}

extension CloudCoreCacheManager: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        guard let cacheable = anObject as? CloudCoreCacheable else { return }
        
        if cacheable.cacheState == .upload || cacheable.cacheState == .download {
            process(cacheables: [cacheable])
        }
    }
    
}
