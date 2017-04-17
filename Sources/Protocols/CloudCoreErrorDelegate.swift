//
//  ErrorReporter.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 06.02.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import Foundation

public protocol CloudCoreErrorDelegate {
	func cloudCore(saveToCloudDidFailed error: Error)
}
