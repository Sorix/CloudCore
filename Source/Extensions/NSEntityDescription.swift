//
//  NSEntityDescription.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 07.02.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import CoreData

extension NSEntityDescription {
	var serviceAttributeNames: ServiceAttributeNames? {
		guard let entityName = self.name else { return nil }
		
		let attributeNamesFromUserInfo = self.parseAttributeNamesFromUserInfo()
		
		// Get required attributes
		
		// Record Data
		let recordDataAttribute: String
		if let recordDataUserInfoName = attributeNamesFromUserInfo.recordData {
			recordDataAttribute = recordDataUserInfoName
		} else {
			// Last chance: try to find default attribute name in entity
			if self.attributesByName.keys.contains(CloudCore.config.defaultAttributeNameRecordData) {
				recordDataAttribute = CloudCore.config.defaultAttributeNameRecordData
			} else {
				return nil
			}
		}
		
        // Record ID
        let recordIDAttribute: String
        if let recordIDUserInfoName = attributeNamesFromUserInfo.recordID {
            recordIDAttribute = recordIDUserInfoName
        } else {
            // Last chance: try to find default attribute name in entity
            if self.attributesByName.keys.contains(CloudCore.config.defaultAttributeNameRecordID) {
                recordIDAttribute = CloudCore.config.defaultAttributeNameRecordID
            } else {
                return nil
            }
        }
        
        // Record Name
        let recordNameAttribute: String
        if let recordNameUserInfoName = attributeNamesFromUserInfo.recordName {
            recordNameAttribute = recordNameUserInfoName
        } else {
            // Last chance: try to find default attribute name in entity
            if self.attributesByName.keys.contains(CloudCore.config.defaultAttributeNameRecordName) {
                recordNameAttribute = CloudCore.config.defaultAttributeNameRecordName
            } else {
                return nil
            }
        }
        
        return ServiceAttributeNames(entityName: entityName, recordName: recordNameAttribute, recordID: recordIDAttribute, recordData: recordDataAttribute, isPublic: attributeNamesFromUserInfo.isPublic)
	}
	
	/// Parse data from User Info dictionary
    private func parseAttributeNamesFromUserInfo() -> (isPublic: Bool, recordData: String?, recordID: String?, recordName: String?) {
		var recordDataAttribute: String?
		var recordIDAttribute: String?
        var recordNameAttribute: String?
		var isPublic = false
		
		// In attribute
		for (attributeName, attributeDescription) in self.attributesByName {
			guard let userInfo = attributeDescription.userInfo else { continue }
			
			// In userInfo dictionary
			for (key, value) in userInfo {
				guard let key = key as? String,
					let value = value as? String else { continue }
				
				if key == ServiceAttributeNames.keyType {
					switch value {
                    case ServiceAttributeNames.valueRecordData: recordDataAttribute = attributeName
					case ServiceAttributeNames.valueRecordID: recordIDAttribute = attributeName
                    case ServiceAttributeNames.valueRecordName: recordNameAttribute = attributeName
					default: continue
					}
				} else if key == ServiceAttributeNames.keyIsPublic {
					if value == "true" { isPublic = true }
				}
			}
		}
		
		return (isPublic, recordDataAttribute, recordIDAttribute, recordNameAttribute)
	}
	
}
