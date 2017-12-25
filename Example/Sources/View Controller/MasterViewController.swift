//
//  MasterViewController.swift
//  CloudTest2
//
//  Created by Vasily Ulianov on 14.02.17.
//  Copyright © 2017 Vasily Ulianov. All rights reserved.
//

import UIKit
import CoreData
import CloudCore

class MasterViewController: UITableViewController {

	private var tableDataSource: MasterTableViewDataSource!
	
	var mockAddNewOrganization: Organization?
	let context = persistentContainer.viewContext
	
	// MARK: - UIViewController methods

	override func viewDidLoad() {
		super.viewDidLoad()
		
		let fetchRequest: NSFetchRequest<Organization> = Organization.fetchRequest()
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: "sort", ascending: true)]
		tableDataSource = MasterTableViewDataSource(fetchRequest: fetchRequest, context: context, sectionNameKeyPath: nil, delegate: self, tableView: tableView)
		tableView.dataSource = tableDataSource
		try! tableDataSource.performFetch()
		
		self.clearsSelectionOnViewWillAppear = true

		self.navigationItem.rightBarButtonItem = editButtonItem
	}
	
	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		
		// Save on editing end
		if !editing {
			try! context.save()
		}
	}
	
	@IBAction func addButtonClicked(_ sender: UIBarButtonItem) {
		ModelFactory.insertOrganizationWithEmployees(context: context)
		try! context.save()
	}
	
	@IBAction func refreshValueChanged(_ sender: UIRefreshControl) {
		CloudCore.fetchAndSave(to: persistentContainer, error: { (error) in
			print("⚠️ FetchAndSave error: \(error)")
			DispatchQueue.main.async {
				sender.endRefreshing()
			}
		}) {
			DispatchQueue.main.async {
				sender.endRefreshing()
			}
		}
	}
	
	// MARK: - Segues

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let cell = sender as? UITableViewCell, let indexPath = tableView.indexPath(for: cell), let detailVC = segue.destination as? DetailViewController {
			let organization = tableDataSource.object(at: indexPath)
			detailVC.organizationID = organization.objectID
			detailVC.title = organization.name
		}
	}

	override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
		return .delete
	}
	
}

extension MasterViewController: FRCTableViewDelegate {
	
	func frcTableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "RightDetail", for: indexPath)
		let organization = tableDataSource.object(at: indexPath)
		
		cell.textLabel?.text = organization.name
		
		let employeesCount = organization.employees?.count ?? 0
		cell.detailTextLabel?.text = String(employeesCount) + " employees"
		
		return cell
	}
	
}

fileprivate class MasterTableViewDataSource: FRCTableViewDataSource<Organization> {
	
	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		let context = frc.managedObjectContext
		
		switch editingStyle {
		case .delete: context.delete(object(at: indexPath))
		default: return
		}
	}
	
}
