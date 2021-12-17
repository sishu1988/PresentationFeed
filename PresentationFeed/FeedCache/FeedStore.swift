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
    func insert(_ items : [FeedItem], timeStamp: Date, completion: @escaping InsertionCompletion)
}
