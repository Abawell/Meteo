//
//  AddCityViewController.swift
//  Weather
//
//  Created by Jérôme Cabanis on 10/03/2023.
//

// Dans un soucis d'économie du nombre de requêtes vers le serveur, la recherche des villes
// ne se fait pas en continu, mais lors de l'appuie sur le bouton Rechercher.

import UIKit

protocol AddCityViewControllerDelegate: AnyObject {
	func addCityViewController(_ controller: AddCityViewController, didSelect city: CityInfo)
}

class AddCityViewController: UITableViewController {

	weak var delegate: AddCityViewControllerDelegate?

	private let geocoding = Geocoding()
	private var cities = [CityInfo]()
	private var askForName = true

	private var searchController: UISearchController!

    override func viewDidLoad() {
        super.viewDidLoad()

		searchController = UISearchController(searchResultsController: nil)
		searchController.searchResultsUpdater = self
		searchController.delegate = self
		searchController.searchBar.delegate = self
		searchController.dimsBackgroundDuringPresentation = false
		searchController.hidesNavigationBarDuringPresentation = false
		if #available(iOS 13.0, *) {
			searchController.automaticallyShowsCancelButton = false
		}
		searchController.searchBar.sizeToFit()

		definesPresentationContext = true

		navigationItem.searchController = searchController
		navigationItem.hidesSearchBarWhenScrolling = false
		searchController.searchBar.becomeFirstResponder()

		geocoding.delegate = self
    }

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		searchController.isActive = true
	}

	@IBAction func onCancel(_ sender: UIBarButtonItem) {
		presentingViewController?.dismiss(animated: true)
	}

	private func searchCity(named: String) {

	}

	// MARK: - Table view data source/delegate

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return cities.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CityCell", for: indexPath)

		let city = cities[indexPath.row]
		cell.textLabel?.text = city.name
		let country = (Locale.current as NSLocale).localizedString(forCountryCode: city.country) ?? city.country
		if let state = city.state {
			cell.detailTextLabel?.text = "\(state) - \(country)"
		} else {
			cell.detailTextLabel?.text = country
		}
        return cell
    }

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let city = cities[indexPath.row]
		delegate?.addCityViewController(self, didSelect: city)
		presentingViewController?.dismiss(animated: true)
	}

	override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		if askForName { return NSLocalizedString("CityName", comment: "Please enter a city name") }
		if cities.isEmpty { return NSLocalizedString("NotFound", comment: "No results found") }
		return nil
	}
}

// MARK: - UISearchBarDelegate
extension AddCityViewController: UISearchBarDelegate {
	func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
		if let name = searchBar.text, !name.isEmpty {
			cities = []
			tableView.reloadData()
			geocoding.requestCities(withName: name)
		}
	}
}

extension AddCityViewController: UISearchControllerDelegate {
	func didPresentSearchController(_ searchController: UISearchController) {
		DispatchQueue.main.async { [weak self] in
			self?.searchController.searchBar.becomeFirstResponder()
		}
	 }
}

// MARK: - UISearchResultsUpdating
extension AddCityViewController: UISearchResultsUpdating {
	func updateSearchResults(for searchController: UISearchController) {
		// Done on searchBarSearchButtonClicked
	}
}

// MARK: - Geocoding delegate
extension AddCityViewController: GeocodingDelegate {
	func geocoding(_ geocoding: Geocoding, didFindCities cities: [CityInfo]) {
		// Using a Set to get unicity of the city (same name, country and state)
		self.cities = Set(cities).sorted()
		askForName = false
		tableView.reloadData()
	}

	func geocoding(_ geocoding: Geocoding, error: Error) {
		let alert = UIAlertController(title: NSLocalizedString("Error", comment: "Error"), message: error.localizedDescription, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel))
		present(alert, animated: true)
		askForName = true
		tableView.reloadData()
	}
}
