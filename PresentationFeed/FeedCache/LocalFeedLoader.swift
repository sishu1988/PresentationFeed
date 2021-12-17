//
//  LocalFeedLoader.swift
//  PresentationFeed
//
//  Created by Alok Sinha on 2021-12-17.
//

import Foundation

public class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    public func save(_ items: [FeedItem], completion: @escaping (Error?) -> Void) {
        
        store.deleteCacheFeed { [weak self] error in
            guard let self = self else { return }
            if let deletionError = error {
                completion(deletionError)
            } else {
                self.cache(items, completion: completion)
            }
        }
    }
    
    private func cache(_ items: [FeedItem], completion:  @escaping (Error?) -> Void) {
        store.insert(items.toLocal(), timeStamp: self.currentDate()) { [weak self] error in
            guard self != nil else { return }
            completion(error)
        }
    }
}


private extension Array where Element == FeedItem {
    func toLocal()-> [LocalFeedItem] {
        return map {LocalFeedItem(id: $0.id, description: $0.description, location: $0.location, imageURL: $0.imageURL)}
    }
}
