//
//  CityInfoTableViewCell.swift
//  Weather
//
//  Created by Jérôme Cabanis on 12/03/2023.
//

import UIKit
import OpenWeather

class CityInfoTableViewCell: UITableViewCell {

	@IBOutlet private var nameLabel: UILabel!
	@IBOutlet private var detailsLabel: UILabel!

	var city: CityInfo? {
		didSet {
			guard let city else { return }
			nameLabel.text = city.name
			detailsLabel.text =  city.location
		}
	}

}
