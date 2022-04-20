//
//  EmployeeTableViewCell.swift
//  CloudCoreExample
//
//  Created by Vasily Ulianov on 13/12/2017.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import UIKit

class EmployeeTableViewCell: UITableViewCell {
	
	@IBOutlet weak var photoImageView: UIImageView!
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var departmentLabel: UILabel!
	@IBOutlet weak var sinceLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
	
    override func prepareForReuse() {
        super.prepareForReuse()
        
        photoImageView.image = nil
        progressView.progress = 0
        progressView.isHidden = true
    }
    
}
