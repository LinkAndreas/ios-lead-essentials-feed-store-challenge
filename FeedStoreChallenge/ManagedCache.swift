//
//  ManagedCache+CoreDataClass.swift
//  FeedStoreChallenge
//
//  Created by Andreas Link on 13.06.21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//
//

import Foundation
import CoreData

@objc(ManagedCache)
internal class ManagedCache: NSManagedObject {
	@NSManaged internal var timestamp: Date
	@NSManaged internal var feed: NSOrderedSet

	static func fetch(in context: NSManagedObjectContext) throws -> ManagedCache? {
		let request = NSFetchRequest<ManagedCache>(entityName: String(describing: ManagedCache.self))
		return try context.fetch(request).first
	}
}
