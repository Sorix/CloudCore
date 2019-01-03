//
//  CloudRecordID.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 02.02.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import CloudKit

extension CKRecord.ID {
	private static let separator = "|"
	
	/// Init from encoded string
	///
	/// - Parameter encodedString: format: `recordName|ownerName`
	convenience init?(encodedString: String) {
        let separated = encodedString.components(separatedBy: CKRecord.ID.separator)
		
		if separated.count == 2 {
            let zoneID = CKRecordZone.ID(zoneName: CloudCore.config.zoneID.zoneName, ownerName: separated[1])
			self.init(recordName: separated[0], zoneID: zoneID)
		} else {
			return nil
		}
	}
	
	/// Encoded string in format: `recordName|ownerName`
	var encodedString: String {
        return recordName + CKRecord.ID.separator + zoneID.ownerName
	}
}
