//
//  Tokens.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 07.02.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import CloudKit

/**
	CloudCore's class for storing global `CKToken` objects. Framework uses one to download only changed data (smart-sync).

	Framework stores tokens in 2 places:

	* singleton `Tokens` object in `CloudCore.tokens`
	* tokens per record inside *Record Data* attribute, it is managed automatically you don't need to take any actions about that token
*/

open class Tokens: NSObject, NSCoding {
	
    var tokensByDatabaseScope = [Int: CKServerChangeToken]()
    var tokensByRecordZoneID = [CKRecordZone.ID: CKServerChangeToken]()
	
	private struct ArchiverKey {
        static let tokensByDatabaseScope = "tokensByDatabaseScope"
        static let tokensByRecordZoneID = "tokensByRecordZoneID"
	}
	
	/// Create fresh object without any Tokens inside. Can be used to fetch full data.
	public override init() {
		super.init()
	}
	
	// MARK: User Defaults
	
	/// Load saved Tokens from UserDefaults. Key is used from `CloudCoreConfig.userDefaultsKeyTokens`
	///
	/// - Returns: previously saved `Token` object, if tokens weren't saved before newly initialized `Tokens` object will be returned
	public static func loadFromUserDefaults() -> Tokens {
		guard let tokensData = UserDefaults.standard.data(forKey: CloudCore.config.userDefaultsKeyTokens),
			let tokens = NSKeyedUnarchiver.unarchiveObject(with: tokensData) as? Tokens else {
				return Tokens()
		}
		
		return tokens
	}
	
	/// Save tokens to UserDefaults and synchronize. Key is used from `CloudCoreConfig.userDefaultsKeyTokens`
	open func saveToUserDefaults() {
		let tokensData = NSKeyedArchiver.archivedData(withRootObject: self)
		UserDefaults.standard.set(tokensData, forKey: CloudCore.config.userDefaultsKeyTokens)
		UserDefaults.standard.synchronize()
	}
	
	// MARK: NSCoding
	
	///	Returns an object initialized from data in a given unarchiver.
	public required init?(coder aDecoder: NSCoder) {
        if let decodedTokensByScope = aDecoder.decodeObject(forKey: ArchiverKey.tokensByDatabaseScope) as? [Int: CKServerChangeToken] {
            self.tokensByDatabaseScope = decodedTokensByScope
        }
        if let decodedTokensByZone = aDecoder.decodeObject(forKey: ArchiverKey.tokensByRecordZoneID) as? [CKRecordZone.ID: CKServerChangeToken] {
			self.tokensByRecordZoneID = decodedTokensByZone
		}
	}
	
	/// Encodes the receiver using a given archiver.
	open func encode(with aCoder: NSCoder) {
        aCoder.encode(tokensByDatabaseScope, forKey: ArchiverKey.tokensByDatabaseScope)
        aCoder.encode(tokensByRecordZoneID, forKey: ArchiverKey.tokensByRecordZoneID)
	}
	
}
