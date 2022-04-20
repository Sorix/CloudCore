//
//  CloudCoreCacheable.swift
//  CloudCore
//
//  Created by deeje cooley on 4/16/22.
//

import Foundation
import CoreData

public enum CacheState: String {
    case local
    case upload         // -> uploading -> cached
    case uploading
    
    case remote
    case download       // -> downloading -> cached
    case downloading
    
    case unload         // -> remote
    
    case cached
}

public enum RemoteStatus: String {
    case pending
    case available
}

public protocol CloudCoreCacheable: CloudCoreType {
    
        // usually hardcoded in the class
    var assetFieldName: String { get }
    
        // fully masked
    var cacheStateRaw: String? { get set }
    var operationID: String? { get set }
    var uploadProgress: Double { get set }
    var downloadProgress: Double { get set }
    
        // sync'ed
    var remoteStatusRaw: String? { get set }
    var suffix: String? { get set }
    
}

public extension CloudCoreCacheable {
    
    var assetFieldName: String {
        return "assetData"
    }
    
    var cacheState: CacheState {
        get {
            return cacheStateRaw == nil ? .remote : CacheState(rawValue: cacheStateRaw!)!
        }
        set {
            cacheStateRaw = newValue.rawValue
        }
    }
    
    var remoteStatus: RemoteStatus {
        get {
            return remoteStatusRaw == nil ? .pending : RemoteStatus(rawValue: remoteStatusRaw!)!
        }
        set {
            remoteStatusRaw = newValue.rawValue
        }
    }
    
    var localAvailable: Bool {
        let availableStates: [CacheState] = [.local, .upload, .uploading, .cached]
        
        return availableStates.contains(cacheState)
    }
    
    var readyToDownload: Bool {
        return remoteStatus == .available && cacheState == .remote
    }
    
    var progress: Double {
        switch cacheState {
        case .uploading:
            return uploadProgress
        case .downloading:
            return downloadProgress
        default:
            return 0
        }
    }
    
    var urlPath: String {
        let cacheDirectory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first
        
        return cacheDirectory! + "/" + recordName! + "." + (suffix ?? "")
    }
    
    var url: URL {
        return URL(fileURLWithPath: urlPath)
    }
    
}
