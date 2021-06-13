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
		let context = self.context
		context.perform {
			do {
				if let existingCache = try ManagedCache.fetch(in: context) {
					completion(.found(feed: existingCache.feed.toLocal(), timestamp: existingCache.timestamp))
				} else {
					completion(.empty)
				}
			} catch {
				completion(.failure(error))
			}
		}
	}

	public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
		let context = self.context
		context.perform {
			if let existingCache = try? ManagedCache.fetch(in: context) {
				context.delete(existingCache)
			}

			let newCache = ManagedCache(context: context)
			newCache.timestamp = timestamp
			newCache.feed = feed.toManaged(context: context)
			try! context.save()
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
