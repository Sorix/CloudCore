//  FRCTableViewDataSource.swift
//  Gist from: https://gist.github.com/Sorix/987af88f82c95ff8c30b51b6a5620657

import UIKit
import CoreData

protocol FRCTableViewDelegate: class {
	func frcTableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
}

class FRCTableViewDataSource<FetchRequestResult: NSFetchRequestResult>: NSObject, UITableViewDataSource, NSFetchedResultsControllerDelegate {
	
	let frc: NSFetchedResultsController<FetchRequestResult>
	weak var tableView: UITableView?
	weak var delegate: FRCTableViewDelegate?
	
	init(fetchRequest: NSFetchRequest<FetchRequestResult>, context: NSManagedObjectContext, sectionNameKeyPath: String?) {
		frc = NSFetchedResultsController<FetchRequestResult>(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: sectionNameKeyPath, cacheName: nil)
		
		super.init()
		
		frc.delegate = self
	}
	
	convenience init(fetchRequest: NSFetchRequest<FetchRequestResult>, context: NSManagedObjectContext, sectionNameKeyPath: String?, delegate: FRCTableViewDelegate, tableView: UITableView) {
		self.init(fetchRequest: fetchRequest, context: context, sectionNameKeyPath: sectionNameKeyPath)
		
		self.delegate = delegate
		self.tableView = tableView
	}
	
	func performFetch() throws {
		try frc.performFetch()
	}
	
	func object(at indexPath: IndexPath) -> FetchRequestResult {
		return frc.object(at: indexPath)
	}
	
	// MARK: - UITableViewDataSource
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return frc.sections?.count ?? 0
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		guard let sections = frc.sections else { return 0 }
		
		return sections[section].numberOfObjects
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if let delegate = delegate {
			return delegate.frcTableView(tableView, cellForRowAt: indexPath)
		} else {
			return UITableViewCell()
		}
	}
	
	// MARK: - NSFetchedResultsControllerDelegate
	
	func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		tableView?.beginUpdates()
	}
	
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
		let sectionIndexSet = IndexSet(integer: sectionIndex)
		
		switch type {
		case .insert: tableView?.insertSections(sectionIndexSet, with: .automatic)
		case .delete: tableView?.deleteSections(sectionIndexSet, with: .automatic)
		case .update: tableView?.reloadSections(sectionIndexSet, with: .automatic)
		case .move: break
		}
	}
	
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
		switch type {
		case .insert:
			guard let newIndexPath = newIndexPath else { break }
			tableView?.insertRows(at: [newIndexPath], with: .automatic)
		case .delete:
			guard let indexPath = indexPath else { break }
			tableView?.deleteRows(at: [indexPath], with: .automatic)
		case .update:
			guard let indexPath = indexPath else { break }
			tableView?.reloadRows(at: [indexPath], with: .automatic)
		case .move:
			guard let indexPath = indexPath, let newIndexPath = newIndexPath else { return }
			tableView?.moveRow(at: indexPath, to: newIndexPath)
		}
	}
	
	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		tableView?.endUpdates()
	}
	
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { return nil }

}

