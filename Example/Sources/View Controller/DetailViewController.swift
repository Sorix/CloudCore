//
//  DetailViewController.swift
//  CloudTest2
//
//  Created by Vasily Ulianov on 14.02.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import UIKit
import CoreData

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
		
		navigationItem.rightBarButtonItem = editButtonItem
	}
	
	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		
		if editing {
			let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(navAddButtonDidTap(_:)))
			navigationItem.setLeftBarButton(addButton, animated: animated)
			
			let renameButton = UIBarButtonItem(title: "Rename", style: .plain, target: self, action: #selector(navRenameButtonDidTap(_:)))
			navigationItem.setRightBarButtonItems([editButtonItem, renameButton], animated: animated)
		} else {
			navigationItem.setLeftBarButton(nil, animated: animated)
			navigationItem.setRightBarButtonItems([editButtonItem], animated: animated)
			try! context.save()
		}
	}
	
	@objc private func navAddButtonDidTap(_ sender: UIBarButtonItem) {
		let employee = ModelFactory.insertEmployee(context: context)
		let organization = context.object(with: organizationID) as! Organization
		employee.organization = organization
	}
	
	@objc private func navRenameButtonDidTap(_ sender: UIBarButtonItem) {
		let organization = context.object(with: organizationID) as! Organization
		organization.name = ModelFactory.newCompanyName()
		self.title = organization.name
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

fileprivate class DetailTableDataSource: FRCTableViewDataSource<Employee> {
	
	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		let context = frc.managedObjectContext
		
		switch editingStyle {
		case .delete: context.delete(object(at: indexPath))
		default: return
		}
	}
	
}
