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
		let recordDataName: String
		if let recordDataUserInfoName = attributeNamesFromUserInfo.recordData {
			recordDataName = recordDataUserInfoName
		} else {
			// Last chance: try to find default attribute name in entity
			if self.attributesByName.keys.contains(CloudCore.config.defaultAttributeNameRecordData) {
				recordDataName = CloudCore.config.defaultAttributeNameRecordData
			} else {
				return nil
			}
		}
		
		// Record ID
		let recordIDName: String
		if let recordIDUserInfoName = attributeNamesFromUserInfo.recordID {
			recordIDName = recordIDUserInfoName
		} else {
			// Last chance: try to find default attribute name in entity
			if self.attributesByName.keys.contains(CloudCore.config.defaultAttributeNameRecordID) {
				recordIDName = CloudCore.config.defaultAttributeNameRecordID
			} else {
				return nil
			}
		}
		
		return ServiceAttributeNames(entityName: entityName, recordData: recordDataName, recordID: recordIDName, isPublic: attributeNamesFromUserInfo.isPublic)
	}
	
	/// Parse data from User Info dictionary
	private func parseAttributeNamesFromUserInfo() -> (isPublic: Bool, recordData: String?, recordID: String?) {
		var recordDataName: String?
		var recordIDName: String?
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
					case ServiceAttributeNames.valueRecordID: recordIDName = attributeName
					case ServiceAttributeNames.valueRecordData: recordDataName = attributeName
					default: continue
					}
				} else if key == ServiceAttributeNames.keyIsPublic {
					if value == "true" { isPublic = true }
				}
			}
		}
		
		return (isPublic, recordDataName, recordIDName)
	}
	
}
