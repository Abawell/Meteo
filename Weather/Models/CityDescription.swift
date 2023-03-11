//
//  CityDescription.swift
//  Weather
//
//  Created by Jérôme Cabanis on 11/03/2023.
//

import Foundation

protocol CityDescription {
	var name: String { get }
	var state: String? { get }
	var country: String { get }
	var lat: Double { get }
	var lon: Double { get }
}

extension CityDescription {
	var location: String {
		let countryName = (Locale.current as NSLocale).localizedString(forCountryCode: country) ?? country
		if let state {
			return "\(state) - \(countryName)"
		} else {
			return country
		}
	}
}
