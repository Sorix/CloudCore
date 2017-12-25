//
//  ErrorBlockProxy.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 12.02.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import Foundation

/// Use that class to log if any errors were sent
class ErrorBlockProxy {
	private(set) var wasError = false
	var destination: ErrorBlock?
	
	init(destination: ErrorBlock?) {
		self.destination = destination
	}
	
	func send(error: Error?) {
		if let error = error {
			self.wasError = true
			destination?(error)
		}
	}
}
