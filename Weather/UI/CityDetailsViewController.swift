//
//  CityDetailsViewController.swift
//  Meteo
//
//  Created by Jérôme Cabanis on 09/03/2023.
//

import UIKit
import OpenWeather

class CityDetailsViewController: UIViewController {

	var city: City? = nil

	@IBOutlet private var nameLabel: UILabel!
	@IBOutlet private var detailsLabel: UILabel!
	@IBOutlet private var iconImageView: UIImageView!
	@IBOutlet private var descriptionLabel: UILabel!
	@IBOutlet private var tempLabel: UILabel!
	@IBOutlet private var separator1: UIView!
	@IBOutlet private var separator2: UIView!
	@IBOutlet private var separator3: UIView!
	@IBOutlet private var separator4: UIView!
	@IBOutlet private var tempValueLabel: UILabel!
	@IBOutlet private var minTempLabel: UILabel!
	@IBOutlet private var minTempValueLabel: UILabel!
	@IBOutlet private var maxTempLabel: UILabel!
	@IBOutlet private var maxTempValueLabel: UILabel!
	@IBOutlet private var feltTempLabel: UILabel!
	@IBOutlet private var feltTempValueLabel: UILabel!
	@IBOutlet private var pressureLabel: UILabel!
	@IBOutlet private var pressureValueLabel: UILabel!
	@IBOutlet private var humidityLabel: UILabel!
	@IBOutlet private var humidityValueLabel: UILabel!
	@IBOutlet private var windLabel: UILabel!
	@IBOutlet private var windSpeedValueLabel: UILabel!
	@IBOutlet private var gustsValueLabel: UILabel!
	@IBOutlet private var compassView: UIView!
	@IBOutlet private var windArrowImageView: UIImageView!
	@IBOutlet private var northLabel: UILabel!
	@IBOutlet private var southLabel: UILabel!
	@IBOutlet private var eastLabel: UILabel!
	@IBOutlet private var westLabel: UILabel!

	private var weather: Weather?

    override func viewDidLoad() {
        super.viewDidLoad()

		windArrowImageView.image = windArrowImageView.image?.withRenderingMode(.alwaysTemplate)
		northLabel.text = NSLocalizedString("North", comment: "N")
		southLabel.text = NSLocalizedString("South", comment: "S")
		eastLabel.text = NSLocalizedString("East", comment: "E")
		westLabel.text = NSLocalizedString("West", comment: "W")

		if let city {
			OpenWeatherController.addObserver(self, for: city)
			weather = OpenWeatherController.getWeather(for: city)
		}
		updateControls()
	}

	deinit {
		if let city {
			OpenWeatherController.removeObserver(self, for: city)
		}
	}

	private func updateControls() {

		if let city {
			nameLabel.text = city.name
			detailsLabel.text = city.location
		} else {
			nameLabel.text = "--"
			detailsLabel.text = nil
		}

		if let weather {
			iconImageView.image = UIImage(named: weather.icon)
			descriptionLabel.text = weather.formattedDescription

			let numberFormatter = NumberFormatter()
			numberFormatter.maximumFractionDigits = 0

			separator1.isHidden = false
			separator2.isHidden = false
			separator3.isHidden = false
			separator4.isHidden = false

			let formatter = MeasurementFormatter()
			formatter.numberFormatter = numberFormatter
			tempLabel.text = NSLocalizedString("Temp", comment: "Temperatures")
			tempValueLabel.text = formatter.string(from: Measurement<UnitTemperature>(value: weather.temp, unit: .kelvin))
			minTempLabel.text = NSLocalizedString("Min", comment: "Min:")
			minTempValueLabel.text = formatter.string(from: Measurement<UnitTemperature>(value: weather.tempMin, unit: .kelvin))
			maxTempLabel.text = NSLocalizedString("Max", comment: "Max:")
			maxTempValueLabel.text = formatter.string(from: Measurement<UnitTemperature>(value: weather.tempMax, unit: .kelvin))
			feltTempLabel.text = NSLocalizedString("FeelsLike", comment: "Perceived:")
			feltTempValueLabel.text = formatter.string(from: Measurement<UnitTemperature>(value: weather.feelsLike, unit: .kelvin))

			pressureLabel.text = NSLocalizedString("Pressure", comment: "Pressure")
			pressureValueLabel.text = formatter.string(from: Measurement<UnitPressure>(value: weather.pressure, unit: .hectopascals))
			humidityLabel.text = NSLocalizedString("Humidity", comment: "Humidity")
			humidityValueLabel.text = "\(weather.humidity) %"

			compassView.isHidden = false
			windLabel.text = NSLocalizedString("Wind", comment: "Wind")
			windSpeedValueLabel.text = formatter.string(from: Measurement<UnitSpeed>(value: weather.windSpeed, unit: .metersPerSecond))
			let angle = weather.windDeg * .pi / 180.0
			windArrowImageView.transform = CGAffineTransform(rotationAngle: angle)
			if #available(iOS 13.0, *) {
				windArrowImageView.tintColor = .label
			}

			if let gusts = weather.windGust {
				gustsValueLabel.isHidden = false
				let gustsText = formatter.string(from: Measurement<UnitSpeed>(value: gusts, unit: .metersPerSecond))
				gustsValueLabel.text = String(format: NSLocalizedString("Gusts", comment: "Gusts at %@"), gustsText)
			} else {
				gustsValueLabel.isHidden = true
			}
		} else {
			descriptionLabel.text = nil
			separator1.isHidden = true
			separator2.isHidden = true
			separator3.isHidden = true
			separator4.isHidden = true
			tempLabel.text = nil
			tempValueLabel.text = nil
			minTempLabel.text = nil
			minTempValueLabel.text = nil
			maxTempLabel.text = nil
			maxTempValueLabel.text = nil
			feltTempLabel.text = nil
			feltTempValueLabel.text = nil
			pressureLabel.text = nil
			pressureValueLabel.text = nil
			humidityLabel.text = nil
			humidityValueLabel.text = nil
			windLabel.text = nil
			compassView.isHidden = true
			windSpeedValueLabel.text = nil
			gustsValueLabel.text = nil
		}
	}
}

extension CityDetailsViewController: OpenWeatherObserver {
	func openWeather(weather: Weather, for position: any CityCoordinates) {
		self.weather = weather
		updateControls()
	}
}
