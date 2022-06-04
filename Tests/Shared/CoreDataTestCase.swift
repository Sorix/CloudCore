//
//  CoreDataTests.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 02.02.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import XCTest
import CoreData

class CoreDataTestCase: XCTestCase {
	var context: NSManagedObjectContext { return persistentContainer.viewContext }
	
	private(set) var persistentContainer: NSPersistentContainer!
	
	func loadPersistenContainer() -> NSPersistentContainer {
		let bundle = Bundle(for: CoreDataTestCase.self)
		let url = bundle.url(forResource: "model", withExtension: "momd")
		let model = NSManagedObjectModel(contentsOf: url!)!
		
		let container = NSPersistentContainer(name: "model", managedObjectModel: model)
		let description = NSPersistentStoreDescription()
		description.type = NSInMemoryStoreType
        if #available(iOS 11.0, watchOS 4.0, tvOS 11.0, OSX 10.13, *) {
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        }
		container.persistentStoreDescriptions = [description]
		
		let expect = expectation(description: "CoreDataStackInitialize")
		container.loadPersistentStores(completionHandler: { (storeDescription, error) in
			expect.fulfill()
			if let error = error {
				fatalError("Unable to load NSPersistentContainer: \(error)")
			}
		})
		wait(for: [expect], timeout: 1)
		
		return container
	}
	
	override func setUp() {
		super.setUp()
		persistentContainer = loadPersistenContainer()
		context.automaticallyMergesChangesFromParent = true
	}
	
	override func tearDown() {
		super.tearDown()
		persistentContainer = nil
	}
	
	override class func tearDown() {
		super.tearDown()
		clearTemporaryFolder()
	}
	
	private static func clearTemporaryFolder() {
		let fileManager = FileManager.default
		let tempFolder = fileManager.temporaryDirectory
		
		do {
			let filePaths = try fileManager.contentsOfDirectory(at: tempFolder, includingPropertiesForKeys: nil, options: [])
			for filePath in filePaths {
				try fileManager.removeItem(at: filePath)
			}
		} catch let error as NSError {
			XCTFail("Could not clear temp folder: \(error.debugDescription)")
		}
	}
}

