//
//  Datafile+CloudCoreCacheable.swift
//  CloudCoreExample
//
//  Created by deeje cooley on 4/18/22.
//  Copyright © 2022 Vasily Ulianov. All rights reserved.
//

import CoreData
import CloudKit
import CloudCore

extension Datafile: CloudCoreCacheable {
    
    override public func awakeFromInsert() {
        super.awakeFromInsert()
        
        recordName = UUID().uuidString      // want this precomputed so that url is functional
    }
    
    override public func prepareForDeletion() {
        removeLocal()
    }
    
}
