//
//  FeedItem.swift
//  AlokFeed
//
//  Created by Alok Sinha on 2021-10-30.
//

import Foundation

public struct FeedImage: Equatable {
    public let id: UUID
    public let description: String?
    public let location: String?
    public let url: URL
    
    public init(id: UUID,
                description: String?,
                location: String?,
                imageURL: URL) {
        
        self.id = id
        self.description = description
        self.location = location
        self.url = imageURL
    }
}

public enum LoadFeedResult {
    case success([FeedImage])
    case failure(Error)
}

//extension LoadFeedResult: Equatable where Error: Equatable {
//    
//}

public protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
