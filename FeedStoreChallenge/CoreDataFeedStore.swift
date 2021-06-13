//
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import CoreData

public final class CoreDataFeedStore: FeedStore {
	private static let modelName = "FeedStore"
	private static let model = NSManagedObjectModel(name: modelName, in: Bundle(for: CoreDataFeedStore.self))

	private let container: NSPersistentContainer
	private let context: NSManagedObjectContext

	struct ModelNotFound: Error {
		let modelName: String
	}

	public init(storeURL: URL) throws {
		guard let model = CoreDataFeedStore.model else {
			throw ModelNotFound(modelName: CoreDataFeedStore.modelName)
		}

		container = try NSPersistentContainer.load(
			name: CoreDataFeedStore.modelName,
			model: model,
			url: storeURL
		)
		context = container.newBackgroundContext()
	}

	public func retrieve(completion: @escaping RetrievalCompletion) {
		context.perform {
			let request = NSFetchRequest<ManagedCache>(entityName: String(describing: ManagedCache.self))
			let results = try! self.context.fetch(request)
			if let cache = results.first {
				completion(.found(feed: cache.feed.toLocal(), timestamp: cache.timestamp))
			} else {
				completion(.empty)
			}
		}
	}

	public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
		context.perform {
			let newCache = ManagedCache(context: self.context)
			newCache.timestamp = timestamp
			newCache.feed = feed.toManaged(context: self.context)
			try! self.context.save()
			completion(nil)
		}
	}

	public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
		fatalError("Must be implemented")
	}
}

private extension NSOrderedSet {
	func toLocal() -> [LocalFeedImage] {
		array
			.compactMap { $0 as? ManagedFeedImage }
			.map { managedFeedImage in
				return LocalFeedImage(
					id: managedFeedImage.id,
					description: managedFeedImage.imageDescription,
					location: managedFeedImage.location,
					url: managedFeedImage.url
				)
			}
	}
}

private extension Array where Element == LocalFeedImage {
	func toManaged(context: NSManagedObjectContext) -> NSOrderedSet {
		return NSOrderedSet(
			array: map { localFeedImage in
				let managedFeedImage = ManagedFeedImage(context: context)
				managedFeedImage.id = localFeedImage.id
				managedFeedImage.imageDescription = localFeedImage.description
				managedFeedImage.location = localFeedImage.location
				managedFeedImage.url = localFeedImage.url
				return managedFeedImage
			}
		)
	}
}
