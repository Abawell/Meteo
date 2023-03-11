//
//  ViewController.swift
//  Meteo
//
//  Created by Jérôme Cabanis on 09/03/2023.
//

import UIKit
import CoreData

class CityListTableViewController: UITableViewController {

	private var fetchedResultsController: NSFetchedResultsController<City>!

	override func viewDidLoad() {
		super.viewDidLoad()

		title = NSLocalizedString("Weather", comment: "App name")
		fetchedResultsController = Persistence.shared.fetchedResultsController
		fetchedResultsController.delegate = self
	}

	// MARK: - Navigation

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		switch segue.identifier {
		case "AddCity":
			if let navController = segue.destination as? UINavigationController,
			   let controller = navController.viewControllers.first as? AddCityViewController {
				controller.delegate = self
			}

			break
		default: break
		}
	}

	// MARK: - Table view data source/delegate
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		guard let sectionInfo = fetchedResultsController.sections?[section] else {
			return 0
		}
		return sectionInfo.numberOfObjects
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "CityCell", for: indexPath) as! CityTableViewCell
		cell.city = fetchedResultsController.object(at: indexPath)
		return cell
	}

	override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		let deleteAction = UIContextualAction(style: .destructive, title: NSLocalizedString("Delete", comment: "Delete")) { [unowned self] action, sourceView, completionHandler in
			let city = fetchedResultsController.object(at: indexPath)
			Persistence.shared.delete(city)
			completionHandler(true)
		}
		return UISwipeActionsConfiguration(actions: [deleteAction])
	}

}

// MARK: - AddCityViewControllerDelegate
extension CityListTableViewController: AddCityViewControllerDelegate {
	
	func addCityViewController(_ controller: AddCityViewController, didSelect city: CityInfo) {
		Persistence.shared.addCity(city)
	}
}

extension CityListTableViewController: NSFetchedResultsControllerDelegate {
	func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		tableView.beginUpdates()
	}

	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		tableView.endUpdates()
	}

	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
		switch type {
		case .insert:
			tableView.insertRows(at: [newIndexPath!], with: .fade)
		case .delete:
			tableView.deleteRows(at: [indexPath!], with: .fade)
		case .move:
			tableView.moveRow(at: indexPath!, to: newIndexPath!)
		case .update:
			tableView.reloadRows(at: [indexPath!], with: .none)
		@unknown default:
			tableView.reloadData()
		}
	}
}
