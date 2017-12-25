# CloudCore

[![Documentation](https://img.shields.io/cocoapods/metrics/doc-percent/CloudCore.svg)](http://cocoadocs.org/docsets/CloudCore/)
[![Version](https://img.shields.io/cocoapods/v/CloudCore.svg?style=flat)](https://cocoapods.org/pods/CloudCore)
![Platform](https://img.shields.io/cocoapods/p/CloudCore.svg?style=flat)
![Status](https://img.shields.io/badge/status-beta-orange.svg)
![Swift](https://img.shields.io/badge/swift-4-orange.svg)

**CloudCore** is a framework that manages syncing between iCloud (CloudKit) and Core Data written on native Swift. It maybe used are CloudKit caching.

#### Features
* Sync manually or on **push notifications**.
* **Differential sync**, only changed object and values are uploaded and downloaded. CloudCore even differs changed and not changed values inside objects.
* Respects of Core Data options (cascade deletions, external storage).
* Knows and manages with CloudKit errors like `userDeletedZone`, `zoneNotFound`, `changeTokenExpired`, `isMore`.
* Covered with Unit and CloudKit online **tests**.
* All public methods are **[100% documented](http://cocoadocs.org/docsets/CloudCore/)**.
* Currently only **private database** is supported.

## How it works?
CloudCore is built using "black box" architecture, so it works invisibly for your application, you just need to add several lines to `AppDelegate` to enable it. Synchronization and error resolving is managed automatically.

1. CloudCore stores *change tokens* from CloudKit, so only changed data is downloaded.
2. When CloudCore is enabled (`CloudCore.enable`) it fetches changed data from CloudKit and subscribes to CloudKit push notifications about new changes.
3. When `CloudCore.fetchAndSave` is called manually or by push notification, CloudCore fetches and saves changed data to Core Data.
4. When data is written to persistent container (parent context is saved) CloudCore founds locally changed data and uploads it to CloudKit.

## Installation

### CocoaPods
**CloudCore** is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'CloudCore', '~> 2.0'
```

## How to help?
Current version of framework hasn't been deeply tested and may contain errors. If you can test framework, I will be very glad. If you found an error, please post [an issue](https://github.com/Sorix/CloudCore/issues).

## Documentation
All public methods are documented using [XCode Markup](https://developer.apple.com/library/content/documentation/Xcode/Reference/xcode_markup_formatting_ref/) and available inside XCode.
HTML-generated version of that documentation is [available here at CocoaDocs](http://cocoadocs.org/docsets/CloudCore/).

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
  application.registerForRemoteNotifications()

  // Enable CloudCore syncing
  CloudCore.enable(persistentContainer: persistentContainer, errorDelegate: self)

  return true
}

// Notification from CloudKit about changes in remote database
func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
  // Check if it CloudKit's and CloudCore notification
  if CloudCore.isCloudCoreNotification(withUserInfo: userInfo) {
    // Fetch changed data from iCloud
    CloudCore.fetchAndSave(using: userInfo, to: persistentContainer, error: nil, completion: { (fetchResult) in
      completionHandler(fetchResult.uiBackgroundFetchResult)
    })
  }
}

func applicationWillTerminate(_ application: UIApplication) {
	// Save tokens on exit used to differential sync
	CloudCore.tokens.saveToUserDefaults()
}
```

4. Make first run of your application in a development environment, fill an example data in Core Data and wait until sync completes. CloudCore create needed CloudKit schemes automatically.

## Service attributes
CloudCore stores service CloudKit information in managed objects, you need to add that attributes to your Core Data model. If required attributes are not found in entity that entity won't be synced.

Required attributes for each synced entity:
1. *Record Data* attribute with `Binary` type
2. *Record ID* attribute with `String` type

You may specify attributes' names in 2 ways (you may combine that ways in different entities).

### User Info
First off CloudCore try to search attributes by looking up User Info at your model, you may specify User Info key `CloudCoreType` fro attribute to mark one as service one. Values are:
* *Record Data* value is `recordData`.
* *Record ID* value is `recordID`.

![Model editor User Info](https://cloud.githubusercontent.com/assets/5610904/24004400/52e0ff94-0a77-11e7-9dd9-e1e24a86add5.png)

### Default names
The most simple way is to name attributes with default names because you don't need to specify any User Info.

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

## Tests
CloudKit objects can't be mocked up, that's why I create 2 different types of tests:

* `Tests/Unit` here I placed tests that can be performed without CloudKit connection. That tests are executed when you submit a Pull Request.
* `Tests/CloudKit` here located "manual" tests, they are most important tests that can be run only in configured environment because they work with CloudKit and your Apple ID.

  Nothing will be wrong with your account, tests use only private `CKDatabase` for application.

  **Please run these tests before opening pull requests.**
 To run them you need to:
  1. Change `TestableApp` bundle id.
  2. Run in simulator or real device `TestableApp` target.
  3. Configure iCloud on that device: Settings.app → iCloud → Login.
  4. Run `CloudKitTests`, they are attached to `TestableApp`, so CloudKit connection will work.

## Roadmap

- [x] Move from alpha to beta status.
- [ ] Add `CloudCore.disable` method
- [ ] Add methods to clear local cache and remote database
- [ ] Add error resolving for `limitExceeded` error (split saves by relationships).

## Author

Open for hire / relocation.
Vasily Ulianov, [va...@me.com](http://www.google.com/recaptcha/mailhide/d?k=01eFEpy-HM-qd0Vf6QGABTjw==&c=JrKKY2bjm0Bp58w7zTvPiQ==)
