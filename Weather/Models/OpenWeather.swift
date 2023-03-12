//
//  OpenWeather.swift
//  Weather
//
//  Created by Jérôme Cabanis on 10/03/2023.
//

import Foundation

// setup(appId:) must be called before any other functions

// Call requestCities to get a list of cities from a city name
// Add a observer to get weather infomation for a specific city position
// call getWeather(for:) to get the last weather information for a city position
// the observer callback function is called automaticaly every 5mn

// Time interval between two weather information updates
private let UpdateTimeInterval: TimeInterval = 60 * 5		// 5mn

public protocol OpenWeatherObserver: AnyObject {
	func openWeather(weather: Weather, for position: any CityPosition)
}

public class OpenWeather {
	private static let shared = OpenWeather()
	private init() {}

	static func setup(appId: String) {
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
	private struct PositionRef: CityPosition {
		let latitude: Double
		let longitude: Double

		init(_ position: any CityPosition) {
			self.latitude = position.latitude
			self.longitude = position.longitude
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

	private var registry = [PositionRef: CityWeather]()
	private var timer: Timer?

	public static func getWeather(for position: any CityPosition) -> Weather? {
		return shared.getWeather(for: position)
	}

	private func getWeather(for position: any CityPosition) -> Weather? {
		return registry[PositionRef(position)]?.lastWeather
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

	public static func addObserver(_ observer: OpenWeatherObserver, for position: any CityPosition) {
		shared.addObserver(observer, for: position)
	}

	private func addObserver(_ observer: OpenWeatherObserver, for position: any CityPosition) {
		let positionRef = PositionRef(position)
		let cityWeather = registry[positionRef] ?? {
			let cityWeather = CityWeather()
			registry[positionRef] = cityWeather
			return cityWeather
		}()
		cityWeather.append(observer)
		startTimer()
		if cityWeather.lastWeather == nil {
			getWeatherAsyncronously(for: positionRef)
		}
	}

	public static func removeObserver(_ observer: OpenWeatherObserver, for position: (any CityPosition)? = nil) {
		shared.removeObserver(observer, for: position)
	}
	
	private func removeObserver(_ observer: OpenWeatherObserver, for position: (any CityPosition)?) {
		if let position {
			let positionRef = PositionRef(position)
			guard let cityWeather = registry[positionRef] else { return }
			cityWeather.remove(observer)
			if cityWeather.observers.isEmpty {
				registry.removeValue(forKey: positionRef)
			}
		} else {
			// As the registry could be modified, loop on a copy of keys
			for position in Array(registry.keys) {
				let cityWeather = registry[position]!
				cityWeather.remove(observer)
				if cityWeather.observers.isEmpty {
					registry.removeValue(forKey: position)
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
		for position in registry.keys {
			getWeatherAsyncronously(for: position)
		}
	}

	private func getWeatherAsyncronously(for position: PositionRef) {
		let lang = Locale.current.languageCode ?? "en"
		guard let url = URL(string: "https://api.openweathermap.org/data/2.5/weather?lat=\(position.latitude)&lon=\(position.longitude)&lang=\(lang)&appId=\(appId)")
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
					if let cityWeather = self.registry[position] {
						cityWeather.lastWeather = weather
						for observer in cityWeather.observers {
							observer.ref?.openWeather(weather: weather, for: position)
						}
					}
				}
			}
		}
		task.resume()
	}
}
