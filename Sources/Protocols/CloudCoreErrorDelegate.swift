//
//  ErrorReporter.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 06.02.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import Foundation

public enum Module {
	
	/// Save to CloudKit module
	case saveToCloud
	
	
	/// Fetch from CloudKit module
	case fetchFromCloud
	
}

public protocol CloudCoreErrorDelegate: class {

	/// CloudCore throwed an error
	///
	/// - Parameters:
	///   - error: error, may be `CKError`, `CloudCoreError` or `Error`
	///   - module: CloudCore's module that throwed an error
	func cloudCore(error: Error, module: Module?)
	
}
