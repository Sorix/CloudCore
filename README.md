# CloudCore

[![Build Status](https://travis-ci.org/Sorix/CloudCore.svg?branch=master)](https://travis-ci.org/Sorix/CloudCore)
[![Documentation](https://img.shields.io/cocoapods/metrics/doc-percent/CloudCore.svg)](http://cocoadocs.org/docsets/CloudCore/)
[![Version](https://img.shields.io/cocoapods/v/CloudCore.svg?style=flat)](https://cocoapods.org/pods/CloudCore)
![Platform](https://img.shields.io/cocoapods/p/CloudCore.svg?style=flat)
![Status](https://img.shields.io/badge/status-alpha-red.svg)
![Swift](https://img.shields.io/badge/swift-4-orange.svg)

**CloudCore** is a framework that manages syncing between iCloud (CloudKit) and Core Data written at native Swift 3.0.

#### Features
* Differential sync, only changed values in object are uploaded and downloaded
* Support of all relationship types
* Respect of Core Data options (cascade deletions, external storage options)
* Unit and performance tests for the most offline methods
* Private and shared CloudKit databases (to be tested) are supported

## Installation

### CocoaPods
**CloudCore** is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'CloudCore', '~> 1.0'
```

### Swift Package Manager
The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the swift compiler. You can read more about package manager in [An Introduction to the Swift Package Manager](https://www.raywenderlich.com/148832/introduction-swift-package-manager) article.

Once you have set up Swift package for your application, just add CloudCore as dependency at your `Package.swift`:

```swift
dependencies: [
    .Package(url: "https://github.com/Sorix/CloudCore", majorVersion: 1)
]
```

## How to help?
Current version of framework hasn't been deeply tested and may contain errors. If you can test framework, I will be very glad. If you found an error, please post [an issue](https://github.com/Sorix/CloudCore/issues).

## Documentation
Detailed documentation is [available at CocoaDocs](http://cocoadocs.org/docsets/CloudCore/).

## Quick start
1. Enable CloudKit capability for you application:
![CloudKit capability](https://cloud.githubusercontent.com/assets/5610904/25092841/28305bc0-2398-11e7-9fbf-f94c619c264f.png)

2. Add 2 service attributes to each entity in CoreData model you want to sync:
  * `recordData` attribute with `Binary` type
  * `recordID` attribute with `String` type

3. Make changes in your **AppDelegate.swift** file:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
	// Register for push notifications about changes
	UIApplication.shared.registerForRemoteNotifications()

	// Enable uploading changed local data to CoreData
	CloudCore.observeCoreDataChanges(persistentContainer: persistentContainer, errorDelegate: nil)

  // Sync on startup if push notifications is missed, disabled etc
  // Also it acts as initial sync if no sync was done before
  CloudCore.fetchAndSave(container: persistentContainer, error: nil, completion: nil)

	return true
}

func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
	// Check if it CloudKit's and CloudCore notification
	if CloudCore.isCloudCoreNotification(withUserInfo: userInfo) {
		// Fetch changed data from iCloud
		CloudCore.fetchAndSave(using: userInfo, container: self.persistentContainer, error: nil, completion: { (fetchResult) in
			completionHandler(fetchResult.uiBackgroundFetchResult)
		})
	}
}

func applicationDidEnterBackground(_ application: UIApplication) {
	// Save tokens on exit used to differential sync
	CloudCore.tokens.saveToUserDefaults()
}
```

4. Make first run of your application in development environment, fill example data in Core Data and wait for syncing. CloudCore will create needed CloudKit schemes automatically.

## Service attributes
CloudCore stores service CloudKit information in managed objects, you need to add that attributes to your Core Data model. If required attributes are not found in entity that entity won't be synced.

Required attributes for each synced entity:
1. *Record Data* attribute with `Binary` type
2. *Record ID* attribute with `String` type

You may specify attribute's names in 2 ways (you may combine that ways in different entities).

### User Info
First off CloudCore try to search attributes by analyzing User Info at your model, you may specify attribute's key as `CloudCoreType` to mark that attribute as service one. Values are:
* *Record Data* value is `recordData`.
* *Record ID* value is `recordID`.

![Model editor User Info](https://cloud.githubusercontent.com/assets/5610904/24004400/52e0ff94-0a77-11e7-9dd9-e1e24a86add5.png)

### Default names
The most simple way is to name attributes with default names because you don't need to specify User Info. Default names are configured at [[configuration struct|Configuration]], if you haven't changed them it will be `recordID` and `recordData`.

Remember that User Info always have a priority, so if User Info is founded for that attribute type it will be used instead of default naming.

### 💡 Tips
* You can name attribute as you want, value of User Info is not changed (you can create attribute `myid` with User Info: `CloudCoreType: recordID`)
* I recommend to mark *Record ID* attribute as `Indexed`, that can speed up updates in big databases.
* *Record Data* attribute is used to store archived version of `CKRecord` with system fields only (like timestamps, tokens), so don't worry about size, no real data will be stored here.

## Example application

You can find example application at [Example](/Example/) directory.

**How to run it:**
1. Set Bundle Identifier.
2. Check that embedded binaries has a correct path (you can remove and add again CloudCore.framework).
3. If you're using simulator, login at iCloud on it.

**How to use it:**
* **+** button adds new object to local storage (that will be automatically synced to Cloud)
* **refresh** button calls `fetchAndSave` to fetch data from Cloud. That is useful button for simulators because Simulator unable to receive push notifications
* Use [CloudKit dashboard](https://icloud.developer.apple.com/dashboard/) to make changes and see it at application, and make change in application and see ones in dashboard. Don't forget to refresh dashboard's page because it doesn't update data on-the-fly.

## Roadmap

- [ ] Sync with public CloudKit database (in development)
- [ ] Add tvOS support
- [ ] Increase number of tests
- [ ] Update documentation with macOS samples

## Author

Vasily Ulianov, [va...@me.com](http://www.google.com/recaptcha/mailhide/d?k=01eFEpy-HM-qd0Vf6QGABTjw==&c=JrKKY2bjm0Bp58w7zTvPiQ==)
