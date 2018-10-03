//
//  FetchResult.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 08.02.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import Foundation


/// Enumeration with results of `FetchAndSaveOperation`.
public enum FetchResult: UInt {
	/// Fetching has successfully completed without any errors
	case newData = 0

	/// No fetching was done, maybe fired with `FetchAndSaveOperation` was called with incorrect UserInfo without CloudCore's data
	case noData = 1
	
	/// There were some errors during operation
	case failed = 2
}

#if os(iOS)
	import UIKit
	
	public extension FetchResult {
		
		/// Convert `self` to `UIBackgroundFetchResult`
		///
		/// Very usefull at `application(_:didReceiveRemoteNotification:fetchCompletionHandler)` as `completionHandler`
		public var uiBackgroundFetchResult: UIBackgroundFetchResult {
			return UIBackgroundFetchResult(rawValue: self.rawValue)!
		}
		
	}
#endif
