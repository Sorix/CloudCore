//
//  ErrorBlockProxyTests.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 02.03.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import XCTest

@testable import CloudCore

class ErrorBlockProxyTests: XCTestCase {
	func testProxy() {
		var isErrorReceived = false
		let errorBlock: ErrorBlock = { _ in
			isErrorReceived = true
		}
		
		let proxy = ErrorBlockProxy(destination: errorBlock)
	
		// Check null error
		proxy.send(error: nil)
		XCTAssertFalse(proxy.wasError)
		XCTAssertFalse(isErrorReceived)
		
		// Check that proxy in proxifing
		proxy.send(error: CloudCoreError.custom("test"))
		XCTAssertTrue(proxy.wasError)
		XCTAssertTrue(isErrorReceived)
	}
}
