//
//  FetchResult.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 08.02.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import Foundation

public enum FetchResult: UInt {
	case newData = 0
	case noData = 1
	case failed = 2
}

#if os(iOS)
	import UIKit
	
	public extension FetchResult {
		public var uiBackgroundFetchResult: UIBackgroundFetchResult {
			return UIBackgroundFetchResult(rawValue: self.rawValue)!
		}
	}
#endif
