//
//  OpenWeatherController.swift
//  Weather
//
//  Created by Jérôme Cabanis on 10/03/2023.
//

import Foundation

// setup(appId:) must be called before any other functions

// Call requestCities to get a list of cities from a city name
// Add a observer to get weather infomation for a specific city coordinates
// call getWeather(for:) to get the last weather information for a city coordinates
// the observer callback function is called automaticaly every 5mn

// Time interval between two weather information updates
private let UpdateTimeInterval: TimeInterval = 60 * 5		// 5mn

public protocol OpenWeatherObserver: AnyObject {
	func openWeather(weather: Weather, for coordinates: any CityCoordinates)
}

public class OpenWeatherController {
	private static let shared = OpenWeatherController()
	private init() {}

	public static func setup(appId: String) {
		shared.appId = appId
	}

	private var appId = ""

	//MARK: - RequestCities

	private var currentRequestCitiesTask: URLSessionTask?

	public static func requestCities(withName cityName: String, handler: @escaping ([CityInfo]?,Error?) -> Void) {
		shared.requestCities(withName: cityName, handler: handler)
	}

	private func requestCities(withName cityName: String, handler: @escaping ([CityInfo]?,Error?) -> Void) {
		if cityName.isEmpty { return }

		currentRequestCitiesTask?.cancel()

		guard
			let name = cityName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
			let url = URL(string: "http://api.openweathermap.org/geo/1.0/direct?q=\(name)&limit=5&appid=\(appId)")
		else { return }

		let task = URLSession.shared.dataTask(with: url) { data, response, error in
			DispatchQueue.main.async {
				if let error {
					if let error = error as? URLError, error.code == .cancelled { return }
					handler(nil, error)
				} else if let data {
					do {
						let cities = try JSONDecoder().decode([CityInfo].self, from: data)
						handler(cities, nil)
					} catch {
						handler(nil, error)
					}
				}
			}
		}

		currentRequestCitiesTask = task
		task.resume()
	}

	//MARK: - Weather observation

	// Needed to keep a weak reference to the observer
	private struct ObserverRef {
		weak var ref: OpenWeatherObserver?
	}

	// Needed because a protocol cannot be used as a dictionnary key
	private struct CoordinateRef: CityCoordinates {
		let latitude: Double
		let longitude: Double

		init(_ coordinates: any CityCoordinates) {
			self.latitude = coordinates.latitude
			self.longitude = coordinates.longitude
		}
	}

	private class CityWeather {
		private(set) var observers = [ObserverRef]()
		var lastWeather: Weather?

		func append(_ observer: OpenWeatherObserver) {
			if observers.contains(where: {$0.ref === observer }) {
				return	// already added
			}
			observers.append(ObserverRef(ref: observer))
		}

		func remove(_ observer: OpenWeatherObserver) {
			let newObservers = observers.filter { $0.ref != nil && $0.ref !== observer }
			if newObservers.count != observers.count {
				observers = newObservers
			}
		}

		func clean() {
			let newObservers = observers.filter { $0.ref != nil }
			if newObservers.count != observers.count {
				observers = newObservers
			}
		}
	}

	private var registry = [CoordinateRef: CityWeather]()
	private var timer: Timer?

	public static func getWeather(for coordinates: any CityCoordinates) -> Weather? {
		return shared.getWeather(for: coordinates)
	}

	private func getWeather(for coordinates: any CityCoordinates) -> Weather? {
		return registry[CoordinateRef(coordinates)]?.lastWeather
	}

	// Clean the registry to remove unused observer
	private func clean() {
		let keys = registry.keys
		for key in keys {
			let cityWeather = registry[key]!
			cityWeather.clean()
			if cityWeather.observers.isEmpty {
				registry.removeValue(forKey: key)
			}
		}
	}

	public static func addObserver(_ observer: OpenWeatherObserver, for coordinates: any CityCoordinates) {
		shared.addObserver(observer, for: coordinates)
	}

	private func addObserver(_ observer: OpenWeatherObserver, for coordinates: any CityCoordinates) {
		let coordinateRef = CoordinateRef(coordinates)
		let cityWeather = registry[coordinateRef] ?? {
			let cityWeather = CityWeather()
			registry[coordinateRef] = cityWeather
			return cityWeather
		}()
		cityWeather.append(observer)
		startTimer()
		if cityWeather.lastWeather == nil {
			getWeatherAsyncronously(for: coordinateRef)
		}
	}

	public static func removeObserver(_ observer: OpenWeatherObserver, for coordinates: (any CityCoordinates)? = nil) {
		shared.removeObserver(observer, for: coordinates)
	}
	
	private func removeObserver(_ observer: OpenWeatherObserver, for coordinates: (any CityCoordinates)?) {
		if let coordinates {
			let coordinateRef = CoordinateRef(coordinates)
			guard let cityWeather = registry[coordinateRef] else { return }
			cityWeather.remove(observer)
			if cityWeather.observers.isEmpty {
				registry.removeValue(forKey: coordinateRef)
			}
		} else {
			// As the registry could be modified, loop on a copy of keys
			for coordinates in Array(registry.keys) {
				let cityWeather = registry[coordinates]!
				cityWeather.remove(observer)
				if cityWeather.observers.isEmpty {
					registry.removeValue(forKey: coordinates)
				}
			}
		}
		checkTimer()
	}

	// Start the timer if needed
	private func startTimer() {
		if timer != nil { return }
		let timer = Timer.scheduledTimer(timeInterval: UpdateTimeInterval, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: true)
		timer.tolerance = 30
		self.timer = timer
	}

	// Check if the timer can be stop
	private func checkTimer() {
		if registry.isEmpty, let timer {
			timer.invalidate()
			self.timer = nil
		}
	}

	@objc private func fireTimer() {
		clean()
		for coordinates in registry.keys {
			getWeatherAsyncronously(for: coordinates)
		}
	}

	private func getWeatherAsyncronously(for coordinates: CoordinateRef) {
		let lang = Locale.current.languageCode ?? "en"
		guard let url = URL(string: "https://api.openweathermap.org/data/2.5/weather?lat=\(coordinates.latitude)&lon=\(coordinates.longitude)&lang=\(lang)&appId=\(appId)")
		else { return }
		let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
			if let data {
				let weather: Weather
				do {
					weather = try JSONDecoder().decode(Weather.self, from: data)
				} catch {
					print(error.localizedDescription)
					return
				}
				DispatchQueue.main.async { [weak self] in
					guard let self else { return }
					if let cityWeather = self.registry[coordinates] {
						cityWeather.lastWeather = weather
						for observer in cityWeather.observers {
							observer.ref?.openWeather(weather: weather, for: coordinates)
						}
					}
				}
			}
		}
		task.resume()
	}
}
