//
//  CoreDataContextObserver.swift
//
//  Created by Michal Zaborowski on 10.05.2016.
//  Copyright © 2016 Inspace Labs Sp z o. o. Spółka Komandytowa. All rights reserved.
//
import Foundation
import CoreData

public struct CoreDataContextObserverState: OptionSet {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    
    public static let Inserted    = CoreDataContextObserverState(rawValue: 1 << 0)
    public static let Updated = CoreDataContextObserverState(rawValue: 1 << 1)
    public static let Deleted   = CoreDataContextObserverState(rawValue: 1 << 2)
    public static let Refreshed   = CoreDataContextObserverState(rawValue: 1 << 3)
    
    public static let All: CoreDataContextObserverState  = [Inserted, Updated, Deleted, Refreshed]
}

public typealias CoreDataContextObserverCompletionBlock = (NSManagedObject,CoreDataContextObserverState) -> ()
public typealias CoreDataContextObserverContextChangeBlock = (_ notification: NSNotification, _ changedObjects: [CoreDataObserverObjectChange]) -> ()

public enum CoreDataObserverObjectChange {
    case Updated(NSManagedObject)
    case Refreshed(NSManagedObject)
    case Inserted(NSManagedObject)
    case Deleted(NSManagedObject)
    
    public func managedObject() -> NSManagedObject {
        switch self {
        case let .Updated(value): return value
        case let .Inserted(value): return value
        case let .Refreshed(value): return value
        case let .Deleted(value): return value
        }
    }
}

public struct CoreDataObserverAction {
    var state: CoreDataContextObserverState
    var completionBlock: CoreDataContextObserverCompletionBlock
}

public class CoreDataContextObserver {
    public var enabled: Bool = true
    public var contextChangeBlock: CoreDataContextObserverContextChangeBlock?
    
    private var notificationObserver: NSObjectProtocol?
    private(set) var context: NSManagedObjectContext
    private(set) var actionsForManagedObjectID: Dictionary<NSManagedObjectID, [CoreDataObserverAction]> = [:]
    private(set) weak var persistentStoreCoordinator: NSPersistentStoreCoordinator?
    
    deinit {
        unobserveAllObjects()
        if let notificationObserver = notificationObserver {
            NotificationCenter.default.removeObserver(notificationObserver)
        }
    }
    
    public init(context: NSManagedObjectContext) {
        self.context = context
        self.persistentStoreCoordinator = context.persistentStoreCoordinator
        
        notificationObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: context, queue: nil) { [weak self] notification in
            self?.handleContextObjectDidChangeNotification(notification: notification as NSNotification)
        }
    }
    
    private func handleContextObjectDidChangeNotification(notification: NSNotification) {
        guard let incomingContext = notification.object as? NSManagedObjectContext,
            let persistentStoreCoordinator = persistentStoreCoordinator,
            let incomingPersistentStoreCoordinator = incomingContext.persistentStoreCoordinator, enabled && persistentStoreCoordinator == incomingPersistentStoreCoordinator else {
                return
        }
        
        let insertedObjectsSet = notification.userInfo?[NSInsertedObjectsKey] as? Set<NSManagedObject> ?? Set<NSManagedObject>()
        let updatedObjectsSet = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject> ?? Set<NSManagedObject>()
        let deletedObjectsSet = notification.userInfo?[NSDeletedObjectsKey] as? Set<NSManagedObject> ?? Set<NSManagedObject>()
        let refreshedObjectsSet = notification.userInfo?[NSRefreshedObjectsKey] as? Set<NSManagedObject> ?? Set<NSManagedObject>()
        
        var combinedObjectChanges = insertedObjectsSet.map({ CoreDataObserverObjectChange.Inserted($0) })
        combinedObjectChanges += updatedObjectsSet.map({ CoreDataObserverObjectChange.Updated($0) })
        combinedObjectChanges += deletedObjectsSet.map({ CoreDataObserverObjectChange.Deleted($0) })
        combinedObjectChanges += refreshedObjectsSet.map({ CoreDataObserverObjectChange.Refreshed($0) })
        
        contextChangeBlock?(notification, combinedObjectChanges)
        
        let combinedSet = insertedObjectsSet.union(updatedObjectsSet).union(deletedObjectsSet).union(refreshedObjectsSet)
        let allObjectIDs = Array(actionsForManagedObjectID.keys)
        let filteredObjects = combinedSet.filter({ allObjectIDs.contains($0.objectID) })
        
        for object in filteredObjects {
            guard let actionsForObject = actionsForManagedObjectID[object.objectID] else { continue }
            
            for action in actionsForObject {
                if action.state.contains(.Inserted) && insertedObjectsSet.contains(object) {
                    action.completionBlock(object,.Inserted)
                } else if action.state.contains(.Updated) && updatedObjectsSet.contains(object) {
                    action.completionBlock(object,.Updated)
                } else if action.state.contains(.Deleted) && deletedObjectsSet.contains(object) {
                    action.completionBlock(object,.Deleted)
                } else if action.state.contains(.Refreshed) && refreshedObjectsSet.contains(object) {
                    action.completionBlock(object,.Refreshed)
                }
            }
        }
    }
    
    public func observeObject(object: NSManagedObject, state: CoreDataContextObserverState = .All, completionBlock: @escaping CoreDataContextObserverCompletionBlock) {
        let action = CoreDataObserverAction(state: state, completionBlock: completionBlock)
        if var actionArray = actionsForManagedObjectID[object.objectID] {
            actionArray.append(action)
            actionsForManagedObjectID[object.objectID] = actionArray
        } else {
            actionsForManagedObjectID[object.objectID] = [action]
        }
        
    }
    
    public func unobserveObject(object: NSManagedObject, forState state: CoreDataContextObserverState = .All) {
        if state == .All {
            actionsForManagedObjectID[object.objectID] = nil
        } else if let actionsForObject = actionsForManagedObjectID[object.objectID] {
            actionsForManagedObjectID[object.objectID] = actionsForObject.filter { !$0.state.contains(state) }
        }
    }
    
    public func unobserveAllObjects() {
        actionsForManagedObjectID.removeAll()
    }
}
