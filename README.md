# CloudCore

![Platform](https://img.shields.io/cocoapods/p/CloudCore.svg?style=flat)
![Status](https://img.shields.io/badge/status-beta-orange.svg)
![Swift](https://img.shields.io/badge/swift-5.0-orange.svg)

**CloudCore** is an advanced sync engine for CloudKit and Core Data.

#### Features
* Leveraging **NSPersistentHistory**, local changes are pushed to CloudKit when online.  Never lose a change again.
* Pull manually or on CloudKit **remote notifications**.
* **Differential sync**, only changed object and values are uploaded and downloaded.
* Core Data relationships are preserved
* **private database** and **shared database** push and pull is supported.
* **public database** push is supported
* Parent-Child relationships can be defined for CloudKit Sharing
* Respects Core Data options (cascade deletions, external storage).
* Support for 'Allows Cloud Encryption' for attributes in Core Data with automatic encoding to and from encryptedValues[] in CloudKit.
* Knows and manages CloudKit errors like `userDeletedZone`, `zoneNotFound`, `changeTokenExpired`, `isMore`.
* Available on iOS and iPadOS (watchOS and tvOS haven't been tested)
* Sharing can be extended to your NSManagedObject classes, and native SharingUI is implemented
* Maskable Attributes allows you to control which attributes are ignored during upload and/or download.
* Cacheable Assets are uploaded automatically and downloaded on-demand, using long-lived operations separate from sync operations.

#### CloudCore vs NSPersistentCloudKitContainer?

NSPersistentCloudKitContainer provides native support for Core Data <-> CloudKit synchronization.  Here are some thoughts on the differences between these two approaches, as of May 2022.

###### NSPersistentCloudKitContainer
* Simple to enable
* Support for Private, Shared, and Public databases
* Synchronizes All Records
* No CloudKit Metadata (e.g. recordName, systemFields, owner)
* Record-level Synchronization (entire objects are pushed)
* Offline Synchronization is opaque, but doesn't appear to require NSPersistentHistoryTracking
* All Core Data names are preceeded with "CD_" in CloudKit
* Core Data Relationships are mapped thru CDMR records in CloudKit
* Sharing is supported via zones
* No(?) long-lived operations support for large file upload/download

###### CloudCore
* Support requires specific configuration in the Core Data Model
* Support for Private, Shared, and Public databases
* Selective Synchronization (e.g. can delete local objects without deleting remote records)
* Explicit CloudKit Metadata
* Field-level Synchronization (only changed attributes are pushed)
* Offline Synchronziation via NSPersistentHistoryTracking
* Core Data names are mapped exactly in CloudKit
* Core Data Relationships are mapped to CloudKit CKReferences
* Maskable Attributes provides fine-grain control over local-only data and manually managed remote data
* Sharing is supported via root records
* Supports upload/download of large data files via long-lived operations, with proper schema configuration

Apple very clearly states that NSPersistentCloudKitContainer is a foundation for future support of more advanced features. I'm still waiting to learn which first-party apps use it. #YMMV

## How it works?
CloudCore is built using a "black box" architecture, so it works fairly invisibly for your application.  You just need to add several lines to your `AppDelegate` to enable it, as well as identify various aspects of your Core Data Model schema. Synchronization and error resolving is managed automatically.

1. CloudCore stores *change tokens* from CloudKit, so only changed data is downloaded.
2. When CloudCore is enabled (`CloudCore.enable`) it pulls changed data from CloudKit and subscribes to CloudKit push notifications about new changes.
3. When `CloudCore.pull` is called manually or by push notification, CloudCore pulls and saves changed data to Core Data.
4. When data is written to your persistent container (parent context is saved) CloudCore finds locally changed data and pushes to CloudKit.
5. By leveraging NSPersistentHistory, changes can be queued when offline and pushed when online.

## Installation

### CocoaPods
**CloudCore** is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'CloudCore'
```

## How to help?
What would you like to see improved?

## Quick start
1. Enable CloudKit capability for you application:

![CloudKit capability](https://cloud.githubusercontent.com/assets/5610904/25092841/28305bc0-2398-11e7-9fbf-f94c619c264f.png)

2. For each entity type you want to sync, add this key: value pair to the UserInfo record of the entity:
* `CloudCoreScopes`: `private`

3. Also add 4 attributes to each entity:
  * `privateRecordData` attribute with `Binary` type
  * `publicRecordData` attribute with `Binary` type
  * `recordName` attribute with `String` type
  * `ownerName` attribute with `String` type

4. And enable 'Preserve After Deletion' for the following attributes
  * `privateRecordData` 
  * `publicRecordData`

5. Make changes in your **AppDelegate.swift** file:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
  // Register for push notifications about changes
  application.registerForRemoteNotifications()

  // Enable CloudCore syncing
  CloudCore.enable(persistentContainer: persistentContainer)

  return true
}

// Notification from CloudKit about changes in remote database
func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
  // Check if it CloudKit's and CloudCore notification
  if CloudCore.isCloudCoreNotification(withUserInfo: userInfo) {
    // Fetch changed data from iCloud
    CloudCore.pull(using: userInfo, to: persistentContainer, error: nil, completion: { (fetchResult) in
      completionHandler(fetchResult.uiBackgroundFetchResult)
    })
  }
}
```

6. If you want to enable offline support, **enable NSPersistentHistoryTracking** when you initialize your Core Data stack

```swift
lazy var persistentContainer: NSPersistentContainer = {
  let container = NSPersistentContainer(name: "YourApp")

  let storeDescription = container.persistentStoreDescriptions.first
  storeDescription?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)

  container.loadPersistentStores { storeDescription, error in
    if let error = error as NSError? {
      // Replace this implementation with code to handle the error appropriately.                
    }
  }
  return container
}()
```

7. To identify changes from your app that should be pushed, **save** from a background ManagedObjectContext named `CloudCorePushContext`, or use the convenience function performBackgroundPushTask

```swift
persistentContainer.performBackgroundPushTask { moc in
  // make changes to objects, properties, and relationships you want pushed via CloudCore
  try? context.save()
}
```

8. Make first run of your application in a development environment, fill an example data in Core Data and wait until sync completes. CloudKit will create needed schemas automatically.

## Service attributes
CloudCore stores CloudKit information inside your managed objects, so you need to add attributes to your Core Data model for that. If required attributes are not found in an entity, that entity won't be synced.

Required attributes for each synced entity:
1. *Private Record Data* attribute with `Binary` type
2. *Public Record Data* attribute with `Binary` type
3. *Record Name* attribute with `String` type
4. *Owner Name* attribute with `String` type

You may specify attributes' names in one of two 2 ways (you may combine that ways in different entities).

### Default names
The most simple way is to name attributes with default names because you don't need to map them in UserInfo.

### Mapping via UserInfo
You can map your own attributes to the required service attributes.  For each attribute you want to map, add an item to the attribute's UserInfo, using the key `CloudCoreType` and following values:
* *Record Name* value is `recordName`.
* *Owner Name* value is `ownerName`.

![Model editor User Info](https://cloud.githubusercontent.com/assets/5610904/24004400/52e0ff94-0a77-11e7-9dd9-e1e24a86add5.png)

When your *entities have relationships*, CloudCore will look for the following key:value pair in the UserInfo of your entities:

`CloudCoreParent`: name of the to-one relationship property in your entity

### 💡 Tips
* I recommend to set the *Record Name* attribute as `Indexed`, to speed up updates in big databases.
* *P… Record Data* attributes are used to store archived version of `CKRecord` with system fields only (like timestamps, tokens), so don't worry about size, no real data will be stored here.

## Scope: Public and/or Private
You can designate which databases each entity will synchronized with.  For each entity you want to synchronize, add an item to the entity's UserInfo, using the key `CloudCoreScope` and following values:
* `public` = pushed to public database
* `private` = synchronized with private (or shared) database
* 'public,private' = both

### Why Both?
Maintaining two copies of a record means we get all the benefits of a private (and sharable) record, while also automatically maintaining a fully updated public copy.

## Maskable Attributes
You can designate attributes in your managed objects to be masked during upload and/or download.  For each attribute you want to mask, add an item to the attribute's UserInfo, using the key `CloudCoreMasks` and following values:
* `upload` = ignored during modify operations
* `download` = ignored during fetch operations
* `upload,download` = both

## Cacheable Assets
By default, CloudCore will transform assets in your CloudKit records into binary data attributes in your Core Data objects.

But when you're working with very large files, such as photos, audio, or video, this default mode isn't optimal.

* Uploading large files can take a long time, and sync will fail if not completed timely.
* To optimize a user's device storage, you may want to downloading large files on-demand.

Cacheable Assets addresses these requirements by leveraging Maskable Attributes to ignore asset fields during sync, and then enabling push and pull of asset fields using long-lived operations.

In order to manage cache state, assets must be stored in their own special entity type in your existing schema, which comform to the CloudCoreCacheable protocol.  This protocol defines a number of attributes required to manage cache state:

```swift
public protocol CloudCoreCacheable: CloudCoreType {        
        // fully masked
    var cacheStateRaw: String? { get set }
    var operationID: String? { get set }
    var uploadProgress: Double { get set }
    var downloadProgress: Double { get set }
    var lastErrorMessage: String? { get set }
        // sync'ed
    var remoteStatusRaw: String? { get set }
    var suffix: String? { get set }
}
```

The heart of CloudCoreCacheable is implemented using the following properties:

```swift
public extension CloudCoreCacheable {
    
    var cacheState: CacheState    
    var remoteStatus: RemoteStatus
    var url: URL
    
}
```

Once you've configured your Core Data schema to support cacheable assets, you can create and download them as needed.

When you create a new cacheable managed object, you must store its data at the file URL before saving it.  The default value of cacheState is "local" and the default value of remoteStatus is "pending". Once CloudCore pushes the new cacheable record, it sets the cacheState to "upload", which triggers a long-lived modify operation.  On completion, the cacheable managed object will have its cacheState set to "cached" and its remoteStatus set to "available".

When cacheable records are pulled from CloudKit, the asset field is ignored (because it is masked), and the cacheState will be "remote".  When the remoteStatus is "available", you can trigger a long-lived fetch operation by setting the cacheState to "download" and saving the object.  Once completed, the cacheable object will have its cacheState set to "cached", and the data will be locally available at the file URL.

Note that cacheState represents a state machine.
```
(**new**) => local -> (push) -> upload -> uploading -> cached
(pull) => remote -> **download** -> downloading -> cached
```

### Important
See the Example app for specific details.  Note, specifically, that I **need to override awakeFromInsert and prepareForDeletion** for my cacheable managed object type Datafile.  If anyone has ideas on how to push this critical implementation detail into CloudCore itself, let me know! 

## CloudKit Sharing
CloudCore has built-in support for CloudKit Sharing.  There are several additional steps you must take to enable it in your application.

1. Add the CKSharingSupported key, with value true, to your info.plist

2. Implement the appropriate delegate(… userDidAcceptCloudKitShare), something like…

```swift
func windowScene(_ windowScene: UIWindowScene, 
				 userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
  let acceptShareOperation = CKAcceptSharesOperation(shareMetadatas: [cloudKitShareMetadata])
  acceptShareOperation.qualityOfService = .userInitiated
  acceptShareOperation.perShareCompletionBlock = { meta, share, error in
    CloudCore.pull(rootRecordID: meta.rootRecordID, container: self.persistentContainer, error: nil) { }
  }
  acceptShareOperation.acceptSharesCompletionBlock = { error in
    // N/A
  }
  CKContainer(identifier: cloudKitShareMetadata.containerIdentifier).add(acceptShareOperation)
}
```

OR

```swift
func application(_ application: UIApplication,
                 userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
  let acceptShareOperation = CKAcceptSharesOperation(shareMetadatas: [cloudKitShareMetadata])
  acceptShareOperation.qualityOfService = .userInitiated
  acceptShareOperation.perShareCompletionBlock = { meta, share, error in
    CloudCore.pull(rootRecordID: meta.rootRecordID, container: self.persistentContainer, error: nil) { }
  }
  acceptShareOperation.acceptSharesCompletionBlock = { error in
    // N/A
  }
  CKContainer(identifier: cloudKitShareMetadata.containerIdentifier).add(acceptShareOperation)
}
```

Note that when a user accepts a share, the app does not receive a remote notification of changes from iCloud, and so it must specifically pull the shared record in.

3. Use a CloudCoreSharingController to configure a UICloudSharingController for presentation

4. When a user wants to delete an object, your app must distinguish between the owner and a sharer, and either delete the object or the share.

## Example application
You can find example application at [Example](/Example/) directory, which has been updated to demonstrate sharing, maskable attributes, and cacheable assets.

**How to run it:**
1. Set Bundle Identifier.
2. Check that embedded binaries has a correct path (you can remove and add again CloudCore.framework).
3. If you're using simulator, login at iCloud on it.

**How to use it:**
* **+** button adds new object to local storage (that will be automatically synced to Cloud)
* **Share* button presents the CloudKit Sharing UI
* **refresh** button calls `pull` to fetch data from Cloud. That is only useful for simulators because Simulator unable to receive push notifications
* Use [CloudKit dashboard](https://icloud.developer.apple.com/dashboard/) to make changes and see it at application, and make change in application and see ones in dashboard. Don't forget to refresh dashboard's page because it doesn't update data on-the-fly.

## Tests
CloudKit objects can't be mocked up, that's why there are 2 different types of tests:

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

- [ ] Add methods to clear local cache and remote database
- [ ] Add error resolving for `limitExceeded` error (split saves by relationships).

## Authors

deeje cooley, [deeje.com](http://www.deeje.com/)
- refactored into Pull/Push termonology
- added offline sync via NSPersistentHistory
- added CloudKit Sharing support
- added Maskable Attributes
- added Cacheable Assets

Vasily Ulianov, [va...@me.com](http://www.google.com/recaptcha/mailhide/d?k=01eFEpy-HM-qd0Vf6QGABTjw==&c=JrKKY2bjm0Bp58w7zTvPiQ==)
Open for hire / relocation.
- implemented version 1 and 2, with dynamic mapping between CoreData and CloudKit

Oleg Müller
- added full support for CoreData relationships
