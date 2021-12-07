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
            guard let self = self else { return }
            switch result {
            case .success( let data, let response):
                return completion(self.map(data, from: response))
            case .failure:
                completion(.failure(RemoteFeedLoader.Error.connectivity))
            }
        }
    }
    
    private func map(_ data : Data, from response: HTTPURLResponse) -> Result {
        guard let root = try? JSONDecoder().decode(Root.self, from: data), response.statusCode == 200 else {
            return  .failure(RemoteFeedLoader.Error.invalidData)
        }
        return .success(root.items.map { $0.item })
    }
}

struct Root: Decodable {
    let items: [Item]
}

struct Item : Codable {
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
