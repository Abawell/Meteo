//
//  CityTableViewCell.swift
//  Weather
//
//  Created by Jérôme Cabanis on 11/03/2023.
//

import UIKit

class CityTableViewCell: UITableViewCell {

	@IBOutlet private var containerView: UIView?
	@IBOutlet private var nameLabel: UILabel!
	@IBOutlet private var detailsLabel: UILabel!

	override func awakeFromNib() {
		super.awakeFromNib()
		if #available(iOS 13.0, *) {
			detailsLabel.textColor = .secondaryLabel
		} else {
			detailsLabel.textColor = .systemGray
		}
		if let containerView {
			if #available(iOS 13.0, *) {
				containerView.backgroundColor = .quaternarySystemFill
			} else {
				containerView.backgroundColor = .groupTableViewBackground
			}
			containerView.layer.borderColor = UIColor.lightGray.cgColor
			containerView.layer.borderWidth = 1
			containerView.layer.cornerRadius = 15
		}
	}

	var city: City? {
		didSet {
			guard let city else { return }

			nameLabel.text = city.name
			let country = (Locale.current as NSLocale).localizedString(forCountryCode: city.country) ?? city.country
			if let state = city.state {
				detailsLabel.text = "\(state) - \(country)"
			} else {
				detailsLabel.text = country
			}
		}
	}

	var cityInfo: CityInfo? {
		didSet {
			guard let city = cityInfo else { return }

			nameLabel.text = city.name
			let country = (Locale.current as NSLocale).localizedString(forCountryCode: city.country) ?? city.country
			if let state = city.state {
				detailsLabel.text = "\(state) - \(country)"
			} else {
				detailsLabel.text = country
			}
		}
	}
}
