//
//  LocalFeedLoader.swift
//  PresentationFeed
//
//  Created by Alok Sinha on 2021-12-17.
//

import Foundation

public class CachePolicy {
    private let currentDate: () -> Date
    
    var maxAge: Int {
        7
    }
    
    public init(currentDate: @escaping () -> Date) {
        self.currentDate = currentDate
    }
    
    func validate(timeStamp: Date)-> Bool {
        let calander = Calendar(identifier: .gregorian)
        guard let maxCacheAge = calander.date(byAdding: .day, value: maxAge, to: timeStamp) else {
            return false
        }
        return currentDate() < maxCacheAge
    }
    
    
}

public class LocalFeedLoader: FeedLoader {
    
    private let store: FeedStore
    private let currentDate: () -> Date
    public typealias LoadResult = LoadFeedResult
    private let cachePolicy: CachePolicy
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
        self.cachePolicy = CachePolicy(currentDate: currentDate)
    }
    
    public func save(_ feed: [FeedImage], completion: @escaping (Error?) -> Void) {
        
        store.deleteCacheFeed { [weak self] error in
            guard let self = self else { return }
            if let deletionError = error {
                completion(deletionError)
            } else {
                self.cache(feed, completion: completion)
            }
        }
    }
    
    private func cache(_ feed: [FeedImage], completion:  @escaping (Error?) -> Void) {
        store.insert(feed.toLocal(), timeStamp: self.currentDate()) { [weak self] error in
            guard self != nil else { return }
            completion(error)
        }
    }
    
    public func load(completion: @escaping (LoadResult)-> Void ) {
        store.retrive { [weak self ]result in
            guard let self = self else { return }
            
            switch result {
            case .found(let feed, let timeStamp) where self.cachePolicy.validate(timeStamp: timeStamp):
                completion(.success(feed.toModels()))
            case .failure(let error):
                completion(.failure(error))
            case .empty:
                completion(.success([]))
            case .found:
                completion(.success([]))
            }
        }
    }
    
    public func validateCache() {
        self.store.retrive { [weak self] result in
            guard let self = self else { return }
            switch result {
            
            case let .found(_, timeStamp) where !self.cachePolicy.validate(timeStamp: timeStamp):
                self.store.deleteCacheFeed(completion: { _ in
                    //
                })
            case .failure( _):
                self.store.deleteCacheFeed(completion: { _ in
                    //
                })
            default:
                break
            }
        }
    }
}


private extension Array where Element == FeedImage {
    func toLocal()-> [LocalFeedImage] {
        return map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, imageURL: $0.url)}
    }
}

private extension Array where Element == LocalFeedImage {
    func toModels()-> [FeedImage] {
        return map { FeedImage(id: $0.id, description: $0.description, location: $0.location, imageURL: $0.imageURL)}
    }
}
