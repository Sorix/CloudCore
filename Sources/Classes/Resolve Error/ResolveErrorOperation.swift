//
//  ResolveErrorOperation.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 12/12/2017.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import Foundation
import CloudKit
import CoreData

/// Resolves `userDeletedZone` and `zoneNotFound` errors
class ResolveErrorOperation: Operation {

	let error: CKError
	let parentContext: NSManagedObjectContext
	let managedObjectModel: NSManagedObjectModel
	let resolvableCode: CKError.Code
	
	var errorBlock: ErrorBlock? {
		didSet {
			errorProxy.destination = errorBlock
		}
	}
	private(set) var isResolved: Bool = false
	
	private let queue = OperationQueue()
	
	private let errorProxy = ErrorBlockProxy(destination: nil)
	
	// MARK: - Static methods
	
	static func getFirstResolvableCode(for error: CKError) -> CKError.Code? {
		if isResolvable(code: error.code) { return error.code }
		
		if let partialErrors = error.partialErrorsByItemID?.values {
			for suberror in partialErrors {
				guard let cloudSubError = suberror as? CKError else { continue }
				if isResolvable(code: cloudSubError.code) { return cloudSubError.code }
			}
		}
		
		return nil
	}
	
	static func isResolvable(code: CKError.Code) -> Bool {
		switch code {
		case .userDeletedZone: return true
		case .zoneNotFound: return true
		case .operationCancelled: return true
		default: break
		}
		
		return false
	}
	
	// MARK: - Public class methods
	
	init?(error: Error, parentContext: NSManagedObjectContext, managedObjectModel: NSManagedObjectModel) {
		guard let cloudError = error as? CKError else { return nil }
		
		self.error = cloudError
		self.parentContext = parentContext
		self.managedObjectModel = managedObjectModel
		
		if let resolvableCode = ResolveErrorOperation.getFirstResolvableCode(for: cloudError) {
			self.resolvableCode = resolvableCode
		} else {
			return nil
		}
		
		super.init()
	}
	
	override func main() {
		super.main()
		
		switch resolvableCode {
		case .userDeletedZone: purgeLocalDatabase()
		case .zoneNotFound: resolveZoneNotFound()
		case .operationCancelled: isResolved = true // cancellation is not an error
		default: break
		}
		
		updateResolvedStatus()
		
		parentContext.performAndWait {
			do {
				try parentContext.save()
			} catch {
				errorBlock?(error)
			}
		}
	}
	
	// MARK: - Private class methods
	
	private func purgeLocalDatabase() {
		let purgeOperation = PurgeLocalDatabaseOperation(parentContext: parentContext, managedObjectModel: managedObjectModel)
		purgeOperation.errorBlock = { self.errorProxy.send(error: $0) }
		queue.addOperation(purgeOperation)
		
		queue.waitUntilAllOperationsAreFinished()
	}
	
	/// Create CloudCore zone, upload all local data to CloudKit
	private func resolveZoneNotFound() {
		// Create CloudCore Zone
		let createZoneOperation = CreateCloudCoreZoneOperation()
		createZoneOperation.errorBlock = {
			self.errorProxy.send(error: $0)
			self.queue.cancelAllOperations()
		}
		
		// Subscribe operation
		let subscribeOperation = SubscribeOperation()
		subscribeOperation.dontResolveErrors = true
		subscribeOperation.errorBlock = { self.errorProxy.send(error: $0) }
		subscribeOperation.addDependency(createZoneOperation)
		
		// Upload all local data
		let uploadOperation = UploadAllLocalDataOperation(parentContext: parentContext, managedObjectModel: managedObjectModel)
		uploadOperation.errorBlock = { self.errorProxy.send(error: $0) }
		uploadOperation.addDependency(subscribeOperation)
		
		queue.addOperations([createZoneOperation, subscribeOperation, uploadOperation], waitUntilFinished: true)
	}
	
	private func updateResolvedStatus() {
		isResolved = !errorProxy.wasError
	}
	
}
