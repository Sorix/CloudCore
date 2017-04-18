//
//  ErrorReporter.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 06.02.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import Foundation

public protocol CloudCoreErrorDelegate {

	/// Save to cloud operation throwed an error
	///
	/// - Parameter error: `Error` or `CloudCoreError` object
	func cloudCore(saveToCloudDidFailed error: Error)
}
