//
//  UIViewController+CloudKit.swift
//  CloudCore
//
//  Created by deeje cooley on 12/5/20.
//

#if os(iOS)

import UIKit
import CloudKit

extension UIViewController {
    
    public func iCloudAvailable(completion: @escaping ((Bool) -> Void)) {
        CloudCore.config.container.accountStatus { accountStatus, error in
            DispatchQueue.main.async {
                var title: String?
                var message: String?
                
                switch accountStatus {
                case .noAccount:
                    title = "Sign in to iCloud and\nenable iCloud Drive"
                    message = "On the Home screen, launch Settings, tap iCloud, and enter your Apple ID. Turn iCloud Drive on. If you don't have an iCloud account, tap Create a new Apple ID."
                    
                case .available:
                    completion(true)
                    
                case .couldNotDetermine:
                    title = "iCloud Unavailable"
                    message = "Could not determine the status of your iCloud account"
                    
                case .restricted:
                    title = "iCloud Restricted"
                    message = "You'll need permissions changed on your iCloud account"
                    
                @unknown default:
                    break
                }
                
                if let title = title, let message = message {
                    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in }))
                    self.present(alert, animated: true) {
                        completion(false)
                    }
                }
            }
        }
    }
    
}

#endif
