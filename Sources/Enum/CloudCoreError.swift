//
//  CloudCoreError.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 02.02.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import Foundation
import CoreData

public enum CloudCoreError: Error, CustomStringConvertible {
	case missingServiceAttributes(entityName: String?)
	case cloudKit(String)
	case coreData(String)
	case custom(String)

	public var localizedDescription: String {
		switch self {
		case .missingServiceAttributes(let entity):
			let entityName = entity ?? "UNKNOWN_ENTITY"
			return entityName + " doesn't contain all required services attributes"
		case .cloudKit(let text): return "iCloud error: \(text)"
		case .coreData(let text): return "Core Data error: \(text)"
		case .custom(let error): return error
		}
	}
	
	public var description: String { return self.localizedDescription }
}

public typealias ErrorBlock = (Error) -> Void
