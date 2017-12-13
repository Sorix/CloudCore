//
//  ErrorReporter.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 06.02.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import Foundation


/// Enumeration with module name that issued an error in `CloudCoreErrorDelegate`
public enum Module {
	
	/// Save to CloudKit module
	case saveToCloud
	
	/// Fetch from CloudKit module
	case fetchFromCloud
	
}

/// Adopt that protocol to handle framework's errors
public protocol CloudCoreErrorDelegate: class {

	/// CloudCore throwed an error
	///
	/// - Parameters:
	///   - error: error, may be `CKError`, `CloudCoreError` or `Error`
	///   - module: CloudCore's module that throwed an error
	func cloudCore(error: Error, module: Module?)
	
}
