//
//  Weather.swift
//  Weather
//
//  Created by Jérôme Cabanis on 11/03/2023.
//

import UIKit

public struct Weather: Decodable {
	public let date: Date
	public let icon: String
	public let description: String
	public let temp: Double
	public let feelsLike: Double
	public let tempMin: Double
	public let tempMax: Double
	public let pressure: Double
	public let humidity: Int
	public let windSpeed: Double
	public let windDeg: Double
	public let windGust: Double?

	private struct NestedWeather: Decodable {
		let icon: String
		let description: String
	}

	private enum CodingKeys: CodingKey {

		case dt
		case weather
		case main
		case wind

		enum MainCodingKeys: CodingKey {
			case temp
			case feels_like
			case temp_min
			case temp_max
			case pressure
			case humidity
		}

		enum WindCodingKeys: CodingKey {
			case speed
			case deg
			case gust
		}
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		let timestamp = try container.decode(Int.self, forKey: .dt)
		self.date = Date(timeIntervalSince1970: TimeInterval(timestamp))

		let weather = try container.decode([NestedWeather].self, forKey: .weather).first!
		self.icon = weather.icon
		self.description = weather.description

		let mainContainer = try container.nestedContainer(keyedBy: CodingKeys.MainCodingKeys.self, forKey: .main)
		self.temp = try mainContainer.decode(Double.self, forKey: .temp)
		self.feelsLike = try mainContainer.decode(Double.self, forKey: .feels_like)
		self.tempMin = try mainContainer.decode(Double.self, forKey: .temp_min)
		self.tempMax = try mainContainer.decode(Double.self, forKey: .temp_max)
		self.pressure = try mainContainer.decode(Double.self, forKey: .pressure)
		self.humidity = Int(try mainContainer.decode(Double.self, forKey: .humidity))

		let windContainer = try container.nestedContainer(keyedBy: CodingKeys.WindCodingKeys.self, forKey: .wind)
		self.windSpeed = try windContainer.decode(Double.self, forKey: .speed)
		self.windDeg = try windContainer.decode(Double.self, forKey: .deg)
		self.windGust = try windContainer.decodeIfPresent(Double.self, forKey: .gust)
	}

	public var formattedDescription: String {
		return description.prefix(1).capitalized + description.dropFirst()
	}
}
