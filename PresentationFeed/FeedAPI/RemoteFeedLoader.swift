//
//  RemoteFeedLoader.swift
//  AlokFeed
//
//  Created by Alok Sinha on 2021-11-01.
//

import Foundation

class RemoteFeedLoader: FeedLoader {
    
    private let client: HTTPClient
    private let url : URL
    
    enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    //    enum Result: Equatable {
    //        case success([FeedItem])
    //        case failure(Error)
    //    }
    
    typealias Result = LoadFeedResult
    
    init(client: HTTPClient, url: URL) {
        self.client = client
        self.url = url
    }
    
    func loadFeed(completion: @escaping (Result) -> Void) {
        client.get(from: url) { [weak self] result in
            guard self != nil else { return }
            switch result {
            case .success( let data, let response):
                do {
                    let items =  try FeedItemMapper.map(data, from: response)
                    completion(.success(items.toModels()))
                } catch {
                    completion(.failure(error))
                }
            case .failure:
                completion(.failure(RemoteFeedLoader.Error.connectivity))
            }
        }
    }
}

struct Root: Decodable {
    let items: [RemoteFeedItem]
}

struct RemoteFeedItem : Codable {
    let id: UUID
    let description: String?
    let location: String?
    let imageURL: URL
    
    enum CodingKeys: String, CodingKey {
        case id, description, location, imageURL = "image"
    }
    
    var item: FeedItem {
       FeedItem(id: id, description: description, location: location, imageURL: imageURL)
    }
}

class FeedItemMapper {
    struct Root: Decodable {
        let items: [RemoteFeedItem]
    }
    
    private static var OK_200: Int {
        200
    }
    
    static func map(_ data: Data, from response: HTTPURLResponse) throws -> [RemoteFeedItem] {
        guard response.statusCode == OK_200, let root = try? JSONDecoder().decode(Root.self, from: data) else {
            throw RemoteFeedLoader.Error.invalidData
        }
        
        return root.items
    }
}

private extension Array where Element == RemoteFeedItem {
    func toModels()-> [FeedItem] {
        return map { FeedItem(id: $0.id, description: $0.description, location: $0.location, imageURL: $0.imageURL) }
    }
}
