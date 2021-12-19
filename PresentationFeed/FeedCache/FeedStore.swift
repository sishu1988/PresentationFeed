//
//  FeedStore.swift
//  PresentationFeed
//
//  Created by Alok Sinha on 2021-12-17.
//

import Foundation

public enum RetrievalCacheResult {
    case empty
    case found([LocalFeedImage], Date)
    case failure(Error)
}

public protocol FeedStore {
    typealias DeleteCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    typealias RetrievalCompletion = (RetrievalCacheResult) -> Void

    func deleteCacheFeed(completion: @escaping DeleteCompletion)
    func insert(_ feed : [LocalFeedImage], timeStamp: Date, completion: @escaping InsertionCompletion)
    func retrive(completion: @escaping RetrievalCompletion)
}

public struct LocalFeedImage: Equatable {
    public let id: UUID
    public let description: String?
    public let location: String?
    public let imageURL: URL
    
    public init(id: UUID,
                description: String?,
                location: String?,
                imageURL: URL) {
        
        self.id = id
        self.description = description
        self.location = location
        self.imageURL = imageURL
    }
}
