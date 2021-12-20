//
//  LocalFeedLoader.swift
//  PresentationFeed
//
//  Created by Alok Sinha on 2021-12-17.
//

import Foundation

public class LocalFeedLoader: FeedLoader {
    
    private let store: FeedStore
    private let currentDate: () -> Date
    public typealias LoadResult = LoadFeedResult
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    public func save(_ feed: [FeedImage], completion: @escaping (Error?) -> Void) {
        
        store.deleteCachedFeed { [weak self] error in
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
        store.retrieve { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .found(let feed, let timeStamp) where CachePolicy.validate(timeStamp: timeStamp, against: self.currentDate()):
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

        self.store.retrieve { [weak self] result in
           
            print("date is \(self!.currentDate())")

            guard let self = self else { return }
            
            switch result {
            case let .found(_, timeStamp) where !CachePolicy.validate(timeStamp: timeStamp, against: self.currentDate()):
                self.store.deleteCachedFeed(completion: { _ in
                    //
                })
            case .failure( _):
                self.store.deleteCachedFeed(completion: { _ in
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
