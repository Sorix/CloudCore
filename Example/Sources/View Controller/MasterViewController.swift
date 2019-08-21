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
	}
    
	@IBAction func addButtonClicked(_ sender: UIBarButtonItem) {
        persistentContainer.performBackgroundTask { (moc) in
            moc.name = CloudCore.config.pushContextName
            ModelFactory.insertOrganizationWithEmployees(context: moc)
            try! moc.save()
        }
	}
	
	@IBAction func refreshValueChanged(_ sender: UIRefreshControl) {
		CloudCore.pull(to: persistentContainer, error: { (error) in
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

	override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
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

extension MasterViewController {

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

fileprivate class MasterTableViewDataSource: FRCTableViewDataSource<Organization> {
		
}

