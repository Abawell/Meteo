//
//  OpenWeatherController.swift
//  Weather
//
//  Created by Jérôme Cabanis on 10/03/2023.
//

import Foundation

///``OpenWeatherController`` is a global class with only static functions
///
///``OpenWeatherController/setup(appId:)`` must be called before any other functions
///
///Call ``OpenWeatherController/requestCities(withName:handler:)`` to get a list of cities matching a city name
///
///To get all weather updates for a city from its coordinates, register an ``OpenWeatherObserver`` with ``OpenWeatherController/addObserver(_:for:)``.
///Call ``OpenWeatherController/getWeather(for:)`` to get the lastest weather information for a city from its coordinates.
///The observer callback function is called automatically every 5 minures

/// Time interval between two weather information updates
private let UpdateTimeInterval: TimeInterval = 60 * 5		// 5mn

public protocol OpenWeatherObserver: AnyObject {
	func openWeather(weather: Weather, for coordinates: any CityCoordinates)
}

public class OpenWeatherController {
	private static let shared = OpenWeatherController()
	private init() {}

	/// Setup the framework. Must be called before any other functions
	/// - Parameter appId: the openweathermap.org API key
	public static func setup(appId: String) {
		shared.appId = appId
	}

	private var appId = ""

	//MARK: - RequestCities

	private var currentRequestCitiesTask: URLSessionTask?

	/// Get a list of cities from a city name.
	/// - Parameters:
	///   - cityName: The name of the city to search
	///   - handler: Returns asynchronously a list of up to 5 cities matching the name
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
	private struct CoordinateRef: CityCoordinates, Hashable {
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

	/// Get the lastest weather information for a city from its coordinates.
	/// - Parameter coordinates: The city coordinates
	/// - Returns: The weather informations or `nil` if this information is not yet known
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


	/// Register an ``OpenWeatherObserver`` to get all weather information updates for a city from its coordinates
	/// - Parameters:
	///   - observer: An ``OpenWeatherObserver``
	///   - coordinates: City coordinates to observe
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

	/// Unregister an ``OpenWeatherObserver``.
	/// - Parameters:
	///   - observer: The ``OpenWeatherObserver`` to unregister
	///   - coordinates: City coordinates. If not nil, only updates for these coordinates are removed. If nil, all the update for this observer are removed.
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
