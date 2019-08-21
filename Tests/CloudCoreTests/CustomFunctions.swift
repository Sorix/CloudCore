//
//  XCTAssertThrowsSpecific.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 02.03.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import XCTest

func XCTAssertThrowsSpecific<T>(_ expression: @autoclosure () throws -> T, _ error: Error) {
	XCTAssertThrowsError(try expression()) { (throwedError) in
		XCTAssertEqual("\(throwedError)", "\(error)", "XCTAssertThrowsSpecific: errors are not equal")
	}
}

func XCTFail(_ error: Error) {
	XCTFail("\(error)")
}
