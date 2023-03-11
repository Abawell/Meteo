//
//  OpenWeather.swift
//  Weather
//
//  Created by Jérôme Cabanis on 10/03/2023.
//

import Foundation

// Global class
// Add a observer to get weather infomation for a specific city
// call getWeather(for:) to get the last weather information for a city
// the observer callback function is called automaticaly every 5mn

protocol OpenWeatherObserver: AnyObject {
	func openWeather(weather: Weather, for city: City)
}

class OpenWeather {
	static let shared = OpenWeather()

	private init() {}

	//MARK: -

	// Neads to keep a weak reference to the observer
	private struct ObserverRef {
		weak var ref: OpenWeatherObserver?
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

	private var registry = [City: CityWeather]()
	private var timer: Timer?

	func getWeather(for city: City) -> Weather? {
		return registry[city]?.lastWeather
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

	func addObserver(_ observer: OpenWeatherObserver, for city: City) {
		let cityWeather = registry[city] ?? {
			let cityWeather = CityWeather()
			registry[city] = cityWeather
			return cityWeather
		}()
		cityWeather.append(observer)
		startTimer()
		if cityWeather.lastWeather == nil {
			getWeatherAsyncronously(for: city)
		}
	}

	func removeObserver(_ observer: OpenWeatherObserver, for city: City) {
		guard let cityWeather = registry[city] else { return }
		cityWeather.remove(observer)
		if cityWeather.observers.isEmpty {
			registry.removeValue(forKey: city)
		}
		checkTimer()
	}

	func removeObserver(_ observer: OpenWeatherObserver) {
		// As the registry could be modified, loop on a copy of keys
		for city in Array(registry.keys) {
			let cityWeather = registry[city]!
			cityWeather.remove(observer)
			if cityWeather.observers.isEmpty {
				registry.removeValue(forKey: city)
			}
		}
		checkTimer()
	}

	// Start the timer if needed
	private func startTimer() {
		if timer != nil { return }
		let timer = Timer.scheduledTimer(timeInterval: 60 * 5, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: true)		// 5mn
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
		print("fireTimer")
		clean()
		for city in registry.keys {
			getWeatherAsyncronously(for: city)
		}
	}

	private func getWeatherAsyncronously(for city: City) {
		let lang = Locale.current.languageCode ?? "en"
		guard
			let appid = Bundle.main.infoDictionary?["APP_ID"] as? String,
			let url = URL(string: "https://api.openweathermap.org/data/2.5/weather?lat=\(city.lat)&lon=\(city.lon)&lang=\(lang)&appid=\(appid)")
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
					if let cityWeather = self.registry[city] {
						cityWeather.lastWeather = weather
						for observer in cityWeather.observers {
							observer.ref?.openWeather(weather: weather, for: city)
						}
					}
				}
			}
		}
		task.resume()
	}
}
