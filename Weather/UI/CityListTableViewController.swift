//
//  ViewController.swift
//  Meteo
//
//  Created by Jérôme Cabanis on 09/03/2023.
//

import UIKit
import CoreData
import OpenWeather

class CityListTableViewController: UITableViewController {

	private var fetchedResultsController: NSFetchedResultsController<City>!

	override func viewDidLoad() {
		super.viewDidLoad()

		title = NSLocalizedString("Weather", comment: "App name")
		navigationItem.backButtonTitle = NSLocalizedString("Cities", comment: "Cities")

		fetchedResultsController = Persistence.shared.fetchedResultsController
		fetchedResultsController.delegate = self

		Persistence.shared.load { [self] error in
			if let error {
				let alert = UIAlertController(title: NSLocalizedString("Error", comment: "Error"), message: error.localizedDescription, preferredStyle: .alert)
				alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default))
				present(alert, animated: true)
			} else {
				if let cities = fetchedResultsController.fetchedObjects, !cities.isEmpty {
					for city in cities {
						OpenWeatherController.addObserver(self, for: city)
					}
				}
				tableView.reloadData()
			}
		}
	}

	deinit {
		OpenWeatherController.removeObserver(self)
	}

	// MARK: - Navigation

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		switch segue.identifier {
		case "AddCity":
			if let navController = segue.destination as? UINavigationController,
			   let controller = navController.viewControllers.first as? AddCityViewController {
				controller.delegate = self
			}

		case "Details":
			if let navController = segue.destination as? UINavigationController,
			   let controller = navController.viewControllers.first as? CityDetailsViewController,
			   let indexPath = tableView.indexPathForSelectedRow
			{
				controller.city = fetchedResultsController.object(at: indexPath)
			}

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
		let city = fetchedResultsController.object(at: indexPath)
		cell.city = city
		cell.weather = OpenWeatherController.getWeather(for: city)
		return cell
	}

	override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		let deleteAction = UIContextualAction(style: .destructive, title: NSLocalizedString("Delete", comment: "Delete")) { [unowned self] action, sourceView, completionHandler in
			let city = fetchedResultsController.object(at: indexPath)
			OpenWeatherController.removeObserver(self, for: city)
			Persistence.shared.delete(city)
			completionHandler(true)
		}
		return UISwipeActionsConfiguration(actions: [deleteAction])
	}

}

// MARK: - AddCityViewControllerDelegate
extension CityListTableViewController: AddCityViewControllerDelegate {
	
	func addCityViewController(_ controller: AddCityViewController, didSelect cityInfo: CityInfo) {
		if let city = Persistence.shared.addCity(cityInfo) {
			OpenWeatherController.addObserver(self, for: city)
		}
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

extension CityListTableViewController: OpenWeatherObserver {
	func openWeather(weather: Weather, for position: any CityCoordinates) {
		guard let city = fetchedResultsController.fetchedObjects?.first(where: {
			$0.longitude == position.longitude && $0.latitude == position.latitude
		}) else { return }
		if let indexPath = fetchedResultsController.indexPath(forObject: city),
		   let cell = tableView.cellForRow(at: indexPath) as? CityTableViewCell
		{
			cell.weather = weather
		}
	}
}
