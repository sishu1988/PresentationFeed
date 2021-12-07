//
//  HTTPClient.swift
//  AlokFeed
//
//  Created by Alok Sinha on 2021-11-01.
//

import Foundation

public enum HTTPClientResult {
    case success(Data, HTTPURLResponse)
    case failure(Error)
}

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}
