//
//  Geocoding.swift
//  Weather
//
//  Created by Jérôme Cabanis on 10/03/2023.
//

import Foundation

protocol GeocodingDelegate: AnyObject {
	func geocoding( _ geocoding: Geocoding, didFindCities: [CityInfo])
	func geocoding( _ geocoding: Geocoding, error: Error)
}

class Geocoding {

	weak var delegate: GeocodingDelegate?

	private let queue = OperationQueue()

	init() {
		queue.maxConcurrentOperationCount = 1
		queue.qualityOfService = .userInitiated
	}

	func requestCities(withName name: String) {
		if name.isEmpty { return }

		queue.cancelAllOperations()
		let operation = GeocodingOperation(cityName: name) { cities, error in
			// The delegate is called on the main thread
			DispatchQueue.main.async { [weak self] in
				guard let self else { return }
				if let cities {
					self.delegate?.geocoding(self, didFindCities: cities)
				} else if let error {
					self.delegate?.geocoding(self, error: error)
				}
			}
		}
		if let operation {
			queue.addOperation(operation)
		}
	}

}

private class GeocodingOperation: Operation {

	private var task: URLSessionTask?

	enum OperationState : Int {
		case ready
		case executing
		case finished
	}

	private var state : OperationState = .ready {
		willSet {
			willChangeValue(forKey: "isExecuting")
			willChangeValue(forKey: "isFinished")
		}
		didSet {
			didChangeValue(forKey: "isExecuting")
			didChangeValue(forKey: "isFinished")
		}
	}

	override var isReady: Bool { return state == .ready }
	override var isExecuting: Bool { return state == .executing }
	override var isFinished: Bool { return state == .finished }

	override func cancel() {
		super.cancel()
		task?.cancel()
	}

	init?(cityName: String, handler: @escaping ([CityInfo]?, Error?) -> Void) {
		guard
			let appid = Bundle.main.infoDictionary?["APP_ID"] as? String,
			let name = cityName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
			let url = URL(string: "http://api.openweathermap.org/geo/1.0/direct?q=\(name)&limit=5&appid=\(appid)")
		else { return nil }

		super.init()

		task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
			guard let self else { return }
			if !self.isCancelled {
				if let data {
					do {
						let cities = try JSONDecoder().decode([CityInfo].self, from: data)
						handler(cities, nil)
					} catch {
						handler(nil, error)
					}
				} else {
					handler(nil, error)
				}
			}
			self.state = .finished
		}
	}

	override func start() {
		if(self.isCancelled) {
			state = .finished
			return
		}

		state = .executing
		task?.resume()
	}
}
