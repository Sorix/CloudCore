//
//  Tokens.swift
//  CloudCore
//
//  Created by Vasily Ulianov on 07.02.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import CloudKit

/**
	CloudCore's class for storing global `CKToken` objects. Framework uses one to upload or download only changed data (smart-sync).

	To detect what data is new and old, framework uses CloudKit's `CKToken` objects and it is needed to be loaded every time application launches and saved on exit.

	Framework stores tokens in 2 places:

	* singleton `Tokens` object in `CloudCore.tokens`
	* tokens per record inside *Record Data* attribute, it is managed automatically you don't need to take any actions about that token

	You need to save `Tokens` object before application terminates otherwise you will loose smart-sync ability.

	### Example
	```swift
	func applicationWillTerminate(_ application: UIApplication) {
		CloudCore.tokens.saveToUserDefaults()
	}
	```
*/
open class Tokens: NSObject, NSCoding {
	
	var tokensByRecordZoneID = [CKRecordZoneID: CKServerChangeToken]()
	
	private struct ArchiverKey {
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
	open static func loadFromUserDefaults() -> Tokens {
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
		if let decodedTokens = aDecoder.decodeObject(forKey: ArchiverKey.tokensByRecordZoneID) as? [CKRecordZoneID: CKServerChangeToken] {
			self.tokensByRecordZoneID = decodedTokens
		} else {
			return nil
		}
	}
	
	/// Encodes the receiver using a given archiver.
	open func encode(with aCoder: NSCoder) {
		aCoder.encode(tokensByRecordZoneID, forKey: ArchiverKey.tokensByRecordZoneID)
	}
	
}
