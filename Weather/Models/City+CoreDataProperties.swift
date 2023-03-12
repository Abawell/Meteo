//
//  City+CoreDataProperties.swift
//  Weather
//
//  Created by Jérôme Cabanis on 10/03/2023.
//
//

import Foundation
import CoreData


extension City {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<City> {
        return NSFetchRequest<City>(entityName: "City")
    }

	@NSManaged public var id: UUID
    @NSManaged public var name: String
	@NSManaged public var state: String?
	@NSManaged public var country: String
    @NSManaged public var lat: Double
    @NSManaged public var lon: Double
}

extension City: CityPosition {
	public var latitude: Double {
		return lat
	}

	public var longitude: Double {
		return lon
	}

	var location: String {
		let countryName = (Locale.current as NSLocale).localizedString(forCountryCode: country) ?? country
		if let state {
			return "\(state) - \(countryName)"
		} else {
			return countryName
		}
	}
}
