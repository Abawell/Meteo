//
//  CityInfo.swift
//  Weather
//
//  Created by Jérôme Cabanis on 10/03/2023.
//

import Foundation

struct CityInfo: CityDescription, Decodable, Hashable, Equatable, Comparable {

	let name: String
	let state: String?
	let country: String
	let lat: Double
	let lon: Double

	enum CodingKeys: String, CodingKey {
		case name
		case state
		case country
		case lat
		case lon
		case localNames = "local_names"
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.state = try container.decodeIfPresent(String.self, forKey: .state)
		self.country = try container.decode(String.self, forKey: .country)
		self.lat = try container.decode(Double.self, forKey: .lat)
		self.lon = try container.decode(Double.self, forKey: .lon)

		var name = try container.decode(String.self, forKey: .name)
		// tries to get the local name if it exists
		if let localeNames = try container.decodeIfPresent([String:String].self, forKey: .localNames) {
			if let code = Locale.current.languageCode, let localName = localeNames[code] {
				name = localName
			}
		}
		self.name = name
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(name.lowercased())
		hasher.combine(state)
		hasher.combine(country)
	}

	static func == (lhs: CityInfo, rhs: CityInfo) -> Bool {
		return lhs.name.caseInsensitiveCompare(rhs.name) == .orderedSame && lhs.state == rhs.state && lhs.country == rhs.country
	}

	static func < (lhs: CityInfo, rhs: CityInfo) -> Bool {
		let nameCompare = lhs.name.localizedCompare(rhs.name)
		if nameCompare == .orderedAscending { return true }
		if nameCompare == .orderedDescending { return false }
		let stateCompare = (lhs.state ?? "").compare(rhs.state ?? "")
		if stateCompare == .orderedAscending { return true }
		if stateCompare == .orderedDescending { return false }
		return lhs.country < rhs.country
	}
}
