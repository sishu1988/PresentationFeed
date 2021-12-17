//
//  FeedStore.swift
//  PresentationFeed
//
//  Created by Alok Sinha on 2021-12-17.
//

import Foundation

public protocol FeedStore {
    typealias DeleteCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    
    func deleteCacheFeed(completion: @escaping (Error?) -> Void)
    func insert(_ items : [LocalFeedItem], timeStamp: Date, completion: @escaping InsertionCompletion)
}

public struct LocalFeedItem: Equatable {
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
