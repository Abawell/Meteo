//
//  CityTableViewCell.swift
//  Weather
//
//  Created by Jérôme Cabanis on 11/03/2023.
//

import UIKit

class CityTableViewCell: UITableViewCell {

	@IBOutlet private var nameLabel: UILabel!
	@IBOutlet private var detailsLabel: UILabel!
	@IBOutlet private var containerView: UIView!
	@IBOutlet private var descriptionLabel: UILabel!
	@IBOutlet private var tempLabel: UILabel!
	@IBOutlet private var iconImageView: UIImageView!

	override func awakeFromNib() {
		super.awakeFromNib()
		containerView.layer.borderColor = UIColor.lightGray.cgColor
		containerView.layer.borderWidth = 1
		containerView.layer.cornerRadius = 15
		iconImageView.tintColor = .white
		prepareForReuse()
		setSelected(false, animated: false)
	}

	override func prepareForReuse() {
		descriptionLabel.text = " "
		tempLabel.text = " "
		iconImageView.image = nil
	}

	override func setSelected(_ selected: Bool, animated: Bool) {
		let color: UIColor
		if #available(iOS 13.0, *) {
			color = selected ? .systemGray4 : .systemBackground
		} else {
			color = selected ? .groupTableViewBackground : .white
		}
		containerView.backgroundColor = color
	}

	override func setHighlighted(_ highlighted: Bool, animated: Bool) {
		let color: UIColor
		if #available(iOS 13.0, *) {
			color = highlighted ? .secondarySystemBackground : .systemBackground
		} else {
			color = highlighted ? .groupTableViewBackground : .white
		}
		containerView.backgroundColor = color
	}

	var city: City? {
		didSet {
			guard let city else { return }

			nameLabel.text = city.name
			detailsLabel.text = city.location
		}
	}

	var weather: Weather? {
		didSet {
			guard let weather else { return }
			print("updated")
			descriptionLabel.text = weather.formattedDescription
			iconImageView.image = UIImage(named: weather.icon)
			let kelvin = Measurement(value: weather.temp, unit: UnitTemperature.kelvin)
			let formatter = MeasurementFormatter()
			let numberFormatter = NumberFormatter()
			numberFormatter.maximumFractionDigits = 0
			formatter.numberFormatter = numberFormatter
			tempLabel.text = formatter.string(from: kelvin)
		}
	}

}
