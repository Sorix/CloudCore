//
//  Tokens.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 07.02.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import CloudKit

/// CloudKit tokens, recommended to store it locally, class is conforming to `NSCoding` protocol
open class Tokens: NSObject, NSCoding {
	open var serverChangeToken: CKServerChangeToken?
	open var tokensByRecordZoneID = [CKRecordZoneID: CKServerChangeToken]()
	
	private struct ArchiverKey {
		static let serverToken = "serverChangeToken"
		static let tokensByRecordZoneID = "tokensByRecordZoneID"
	}
	
	override init() {
		super.init()
	}
	
	public required init?(coder aDecoder: NSCoder) {
		self.serverChangeToken = aDecoder.decodeObject(forKey: ArchiverKey.serverToken) as? CKServerChangeToken
		self.tokensByRecordZoneID = aDecoder.decodeObject(forKey: ArchiverKey.tokensByRecordZoneID) as? [CKRecordZoneID: CKServerChangeToken] ?? [CKRecordZoneID: CKServerChangeToken]()
	}
	
	open func encode(with aCoder: NSCoder) {
		aCoder.encode(serverChangeToken, forKey: ArchiverKey.serverToken)
		aCoder.encode(tokensByRecordZoneID, forKey: ArchiverKey.tokensByRecordZoneID)
	}
	
	// MARK: - User Defaults
	
	/// Load saved Tokens from UserDefaults
	///
	/// - Parameter fromKey: UserDefaults key, default is `CloudCore.config.userDefaultsKeyTokens`
	/// - Returns: if tokens is not saved before initialize with no tokens
	open static func loadFromUserDefaults(fromKey: String = CloudCore.config.userDefaultsKeyTokens) -> Tokens {
		guard let tokensData = UserDefaults.standard.data(forKey: fromKey),
			let tokens = NSKeyedUnarchiver.unarchiveObject(with: tokensData) as? Tokens else {
				return Tokens()
		}

		return tokens
	}
	
	/// Save tokens to UserDefaults and synchronize
	///
	/// - Parameter forKey: UserDefaults key, default is `CloudCore.config.userDefaultsKeyTokens`
	open func saveToUserDefaults(forKey: String = CloudCore.config.userDefaultsKeyTokens) {
		let tokensData = NSKeyedArchiver.archivedData(withRootObject: self)
		UserDefaults.standard.set(tokensData, forKey: forKey)
		UserDefaults.standard.synchronize()
	}
}
