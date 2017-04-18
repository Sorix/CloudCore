//
//  ActivityIndicatable.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 06.02.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import Foundation
import CoreData

/// Framework custom notifications that posted during execution
public extension Notification.Name {
	
	/// Posted when CloudCore begins fetching data from iCloud
	public static var CloudCoreWillSyncFromCloud: Notification.Name {
		return Notification.Name(rawValue: "\(#function)")
	}
	
	/// Posted when CloudCore finished fetching data from iCloud and updated local objects
	public static var CloudCoreDidSyncFromCloud: Notification.Name {
		return Notification.Name(rawValue: "\(#function)")
	}
	
	/// Posted when CloudCore begins conversion operations (NSManagedObject to CKRecord) and starts uploading to iCloud
	public static var CloudCoreWillSyncToCloud: Notification.Name {
		return Notification.Name(rawValue: "\(#function)")
	}
	
	/// Posted when CloudCore completed uploading data to iCloud
	public static var CloudCoreDidSyncToCloud: Notification.Name {
		return Notification.Name(rawValue: "\(#function)")
	}
}
