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

	var detailViewController: DetailViewController? = nil
	var managedObjectContext: NSManagedObjectContext? = nil
	
	var _fetchedResultsController: NSFetchedResultsController<Event>? = nil

	// MARK: - CloudCore
	
	// Force refresh data from iCloud
	@IBAction func refreshButton(_ sender: UIBarButtonItem) {
		NSLog(">> (CloudCore.fetchAndSave) Started updating from iCloud")
		CloudCore.fetchAndSave(container: persistentContainer, error: { (error) in
			print(error)
		}) {
			NSLog("<< (CloudCore.fetchAndSave) Fetch from iCloud completed")
		}
	}
	
	func insertNewObject(_ sender: Any) {
		let context = self.fetchedResultsController.managedObjectContext
		let newEvent = Event(context: context)
		
		// If appropriate, configure the new managed object.
		newEvent.timestamp = NSDate()
		newEvent.asset = UIImageJPEGRepresentation(#imageLiteral(resourceName: "TestImage"), 0.8) as NSData?

		let subevent = Subevent(context: context)
		subevent.timestamp = NSDate()
		subevent.event = newEvent
		
		try! context.save()
	}
	
	// MARK: - UIViewController methods
	
	override func viewDidLoad() {
		super.viewDidLoad()

		let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewObject(_:)))
		self.navigationItem.rightBarButtonItem = addButton
		if let split = self.splitViewController {
		    let controllers = split.viewControllers
		    self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
		}
	}

	override func viewWillAppear(_ animated: Bool) {
		self.clearsSelectionOnViewWillAppear = self.splitViewController!.isCollapsed
		super.viewWillAppear(animated)
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	// MARK: - Segues

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "showDetail" {
		    if let indexPath = self.tableView.indexPathForSelectedRow {
		    let object = self.fetchedResultsController.object(at: indexPath)
		        let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
		        controller.detailItem = object
		        controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
		        controller.navigationItem.leftItemsSupplementBackButton = true
		    }
		}
	}

	// MARK: - Table View

	override func numberOfSections(in tableView: UITableView) -> Int {
		return self.fetchedResultsController.sections?.count ?? 0
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let sectionInfo = self.fetchedResultsController.sections![section]
		return sectionInfo.numberOfObjects
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
		let event = self.fetchedResultsController.object(at: indexPath)
		self.configureCell(cell, withEvent: event)
		return cell
	}

	override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return true
	}

	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		if editingStyle == .delete {
		    let context = self.fetchedResultsController.managedObjectContext
		    context.delete(self.fetchedResultsController.object(at: indexPath))
			try! context.save()
		}
	}

	func configureCell(_ cell: UITableViewCell, withEvent event: Event) {
		cell.textLabel!.text = event.timestamp!.description
	}
}

