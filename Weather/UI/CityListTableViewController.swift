//
//  ViewController.swift
//  Meteo
//
//  Created by Jérôme Cabanis on 09/03/2023.
//

import UIKit

class CityListTableViewController: UITableViewController {

	override func viewDidLoad() {
		super.viewDidLoad()

		title = NSLocalizedString("Weather", comment: "App name")
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
}

// MARK: - AddCityViewControllerDelegate
extension CityListTableViewController: AddCityViewControllerDelegate {
	
	func addCityViewController(_ controller: AddCityViewController, didSelect city: CityInfo) {
		Persistence.shared.addCity(city)
	}
}

