//
//  DetailViewController.swift
//  CloudTest2
//
//  Created by Vasily Ulianov on 14.02.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import UIKit
import CoreData
import CloudCore

class DetailViewController: UITableViewController {

	var organizationID: NSManagedObjectID!
	let context = persistentContainer.viewContext
	
	private var tableDataSource: DetailTableDataSource!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let fetchRequest: NSFetchRequest<Employee> = Employee.fetchRequest()
		fetchRequest.predicate = NSPredicate(format: "organization == %@", organizationID)
		
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
		
		tableDataSource = DetailTableDataSource(fetchRequest: fetchRequest, context: context, sectionNameKeyPath: nil, delegate: self, tableView: tableView)
		tableView.dataSource = tableDataSource
		try! tableDataSource.performFetch()
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(add(_:)))
        let renameButton = UIBarButtonItem(title: "Rename", style: .plain, target: self, action: #selector(rename(_:)))
        navigationItem.setRightBarButtonItems([addButton, renameButton], animated: false)
	}
    
	@objc private func add(_ sender: UIBarButtonItem) {
        persistentContainer.performBackgroundTask { (moc) in
            moc.name = CloudCore.config.pushContextName

            let employee = ModelFactory.insertEmployee(context: moc)
            let organization = try? moc.existingObject(with: self.organizationID) as! Organization
            employee.organization = organization
            
            try? moc.save()
        }
	}
	
	@objc private func rename(_ sender: UIBarButtonItem) {
        let newTitle = ModelFactory.newCompanyName()
        persistentContainer.performBackgroundTask { (moc) in
            moc.name = CloudCore.config.pushContextName

            let organization = try? moc.existingObject(with: self.organizationID) as! Organization
            organization?.name = newTitle
            
            try? moc.save()
        }
        self.title = newTitle
	}

}

extension DetailViewController: FRCTableViewDelegate {
	
	func frcTableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Employee", for: indexPath) as! EmployeeTableViewCell
		let employee = tableDataSource.object(at: indexPath)
		
		cell.nameLabel.text = employee.name
		
		if let imageData = employee.photoData, let image = UIImage(data: imageData) {
			cell.photoImageView.image = image
		} else {
			cell.photoImageView.image = nil
		}
		
		var departmentText = employee.department ?? "No"
		departmentText += " department"
		cell.departmentLabel.text = departmentText
		
		var miniText = "Since "
		if let workingSince = employee.workingSince {
			miniText += DateFormatter.localizedString(from: workingSince, dateStyle: .medium, timeStyle: .none)
		} else {
			miniText += "unknown date"
		}
		
		cell.sinceLabel.text = miniText
		
		return cell
	}
	
}

extension DetailViewController {
    
    @available(iOS 11.0, *)
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteTitle = NSLocalizedString("Delete", comment: "Delete action")
        let deleteAction = UIContextualAction(style: .destructive, title: deleteTitle,
                                              handler: { [weak self] action, view, completionHandler in
                                                
                                                let anObject = self?.tableDataSource.object(at: indexPath)
                                                let objectID = anObject?.objectID
                                                
                                                persistentContainer.performBackgroundTask { (moc) in
                                                    moc.name = CloudCore.config.pushContextName
                                                    if let objectToDelete = try? moc.existingObject(with: objectID!) {
                                                        moc.delete(objectToDelete)
                                                        try? moc.save()
                                                    }
                                                }
                                                
                                                completionHandler(true)
        })
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        return configuration
    }
    
}

fileprivate class DetailTableDataSource: FRCTableViewDataSource<Employee> {
    
}
