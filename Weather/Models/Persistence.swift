//
//  Persistence.swift
//  Weather
//
//  Created by Jérôme Cabanis on 10/03/2023.
//

import CoreData

class Persistence {

	static let shared = Persistence()

	private lazy var container: NSPersistentContainer = {
		let container = NSPersistentContainer(name: "Weather")
		container.loadPersistentStores(completionHandler: { (storeDescription, error) in
			if let error = error as NSError? {
				// Replace this implementation with code to handle the error appropriately.
				// fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

				/*
				 Typical reasons for an error here include:
				 * The parent directory does not exist, cannot be created, or disallows writing.
				 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
				 * The device is out of space.
				 * The store could not be migrated to the current model version.
				 Check the error message to determine what the actual problem was.
				 */
				fatalError("Unresolved error \(error), \(error.userInfo)")
			}
		})
		return container
	}()

	private lazy var context: NSManagedObjectContext = {
		return container.viewContext
	}()

	lazy var fetchedResultsController: NSFetchedResultsController<City> = {
		let request = City.fetchRequest()
		let nameSort = NSSortDescriptor(key: #keyPath(City.name), ascending: true)
		let stateSort = NSSortDescriptor(key: #keyPath(City.state), ascending: true)
		let countrySort = NSSortDescriptor(key: #keyPath(City.country), ascending: true)
		request.sortDescriptors = [nameSort, stateSort, countrySort]
		let fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
		return fetchedResultsController
	}()

	init() {
	}

	func load(handler: @escaping (Error?) -> Void) {
		context.perform { [self] in
			do {
				try fetchedResultsController.performFetch()
				DispatchQueue.main.async {
					handler(nil)
				}
			} catch {
				print("Fetching error: \(error.localizedDescription)")
				DispatchQueue.main.async {
					handler(error)
				}
			}
		}
	}

	private func save() {
		guard context.hasChanges else { return }
		do {
			try context.save()
		} catch {
			// Replace this implementation with code to handle the error appropriately.
			// fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
			let nserror = error as NSError
			fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
		}
	}

	func addCity(_ cityInfo: CityInfo) -> City? {
		do {
			// Verify the city is not already in the store
			let testFetch = City.fetchRequest()
			testFetch.predicate = NSPredicate(format: "%K == %@ AND %K == %@ AND %K == %@", #keyPath(City.name), cityInfo.name, #keyPath(City.state), cityInfo.state ?? "", #keyPath(City.country), cityInfo.country)
			let result = try context.fetch(testFetch)
			if !result.isEmpty { return nil }	// Already exist

			let city = City(context: context)
			city.id = UUID()
			city.name = cityInfo.name
			city.state = cityInfo.state ?? ""
			city.country = cityInfo.country
			city.lat = cityInfo.lat
			city.lon = cityInfo.lon
			save()
			return city
		} catch {
			print(error.localizedDescription)
			return nil
		}
	}

	func delete(_ city: City) {
		context.delete(city)
		save()
	}
}
