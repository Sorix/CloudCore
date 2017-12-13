//
//  NotificationsObserver.swift
//  CloudCoreExample
//
//  Created by Vasily Ulianov on 13/12/2017.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import Foundation
import CloudCore
import os.log

class NotificationsObserver {
	
	func observe() {
		NotificationCenter.default.addObserver(forName: .CloudCoreWillSyncFromCloud, object: nil, queue: nil) { _ in
			os_log("🔁 Started fetching from iCloud", log: OSLog.default, type: .debug)
		}
		
		NotificationCenter.default.addObserver(forName: .CloudCoreDidSyncFromCloud, object: nil, queue: nil) { _ in
			os_log("✅ Finishing fetching from iCloud", log: OSLog.default, type: .debug)
		}
		
		NotificationCenter.default.addObserver(forName: .CloudCoreWillSyncToCloud, object: nil, queue: nil) { _ in
			os_log("💾 Started saving to iCloud", log: OSLog.default, type: .debug)
		}
		
		NotificationCenter.default.addObserver(forName: .CloudCoreDidSyncToCloud, object: nil, queue: nil) { _ in
			os_log("✅ Finished saving to iCloud", log: OSLog.default, type: .debug)
		}
		
	}
	
}
