# CloudCore

[![CI Status](http://img.shields.io/travis/sorix/CloudCore.svg?style=flat)](https://travis-ci.org/sorix/CloudCore)
[![Version](https://img.shields.io/cocoapods/v/CloudCore.svg?style=flat)](http://cocoadocs.org/docsets/CloudCore)
[![Platform](https://img.shields.io/cocoapods/p/CloudCore.svg?style=flat)](http://cocoadocs.org/docsets/CloudCore)
![Status](https://img.shields.io/badge/status-alpha-red.svg)
![Swift](https://img.shields.io/badge/swift-3.0-orange.svg)

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
pod 'CloudCore'
```

### Swift Package Manager
The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the swift compiler. You can read more about package manager in [An Introduction to the Swift Package Manager](https://www.raywenderlich.com/148832/introduction-swift-package-manager) article.

Once you have set up Swift package for your application, just add CloudCore as dependency at your `Package.swift`:

```swift
dependencies: [
    .Package(url: "https://github.com/Sorix/CloudCore", majorVersion: 0)
]
```

## Quick start
1. Enable CloudKit capability for you application:
![CloudKit capability](https://cloud.githubusercontent.com/assets/5610904/25092841/28305bc0-2398-11e7-9fbf-f94c619c264f.png)

2. Add 2 [service attributes](https://github.com/Sorix/CloudCore/wiki/Service-attributes) to each entity in CoreData model you want to sync:
  * `recordData` attribute with `Binary` type
  * `recordID` attribute with `String` type

3. Make changes in your **AppDelegate.swift** file:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
	// Register for push notifications about changes
	UIApplication.shared.registerForRemoteNotifications()

	// Enable uploading changed local data to CoreData
	CloudCore.observeCoreDataChanges(persistentContainer: self.persistentContainer, errorDelegate: nil)

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

## Example application

You can find example application at [Example](/Example/) directory.

**How to run it:**
1. Change Bundle Identifier to anything else.
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

Vasily Ulianov, vasily@me.com
