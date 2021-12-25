//
//  AlokFeedTests.swift
//  AlokFeedTests
//
//  Created by Alok Sinha on 2021-10-30.
//

import XCTest
import PresentationFeed

class HTTPClientSpy: HTTPClient {
    
    var requestedURL: [URL] = []
    
    var completion: ((HTTPClientResult) -> Void)?
    
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        self.completion = completion
        requestedURL.append(url)
    }
    
    func complete(with error: Error) {
        completion?(.failure(error))
    }
    
    func complete(with statusCode: Int, and data: Data = Data()) {
        let response = HTTPURLResponse(url: requestedURL.first!, statusCode: statusCode, httpVersion: nil, headerFields: nil)
        completion?(.success(data, response!))
    }
}

class RemoteFeedLoaderTests: XCTestCase {
    
    func test_init_doesNotLoadDataFromURL() {
        let (_, client) = makeSUT()
        XCTAssertTrue(client.requestedURL.isEmpty)
    }
    
    func test_load_requestDataFromURL() {
        let url = URL(string: "https://a-url.com")!
        let (sut , client) = makeSUT()
        sut.load { _  in}
        XCTAssertEqual(client.requestedURL, [url])
    }
    
    func test_loadTwice_requestFromURLTwice() {
        let url = URL(string: "https://a-url.com")!
        let (sut , client) = makeSUT()
        sut.load { _ in}
        sut.load { _ in}
        XCTAssertEqual(client.requestedURL, [url, url])
    }
    
    func test_load_deliversErrorOnClientError() {
        
        let (sut , client) = makeSUT()
        expect(sut, expectedResult: .failure(RemoteFeedLoader.Error.connectivity)) {
            let error = NSError(domain: "Test", code: 404)
            client.complete(with: error)
        }
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut , client) = makeSUT()
        expect(sut, expectedResult: .failure(RemoteFeedLoader.Error.invalidData)) {
            client.complete(with: 400)
        }
    }
    
    func test_load_deliverErrorOn200HTTPResponseWithInvalidJson() {
        let (sut , client) = makeSUT()
        expect(sut, expectedResult: .failure(RemoteFeedLoader.Error.invalidData)) {
            client.complete(with: 200 , and: "Invalid data".data(using: .utf8)!)
        }
    }
    
    func test_load_deliverErrorOn200HTTPResponseWithEmptyJson() {
        let (sut , client) = makeSUT()
        expect(sut, expectedResult: .success([])) {
            client.complete(with: 200 , and: "{\"items\" : []}".data(using: .utf8)!)
        }
    }
    
    func test_load_deliverErrorOn200HTTPResponseWithJsonItems() {
        
        let item1 = makeItem(id: UUID(), imageURL: URL(string: "https://a-url.com")!)
        let item2 = makeItem(id: UUID(),  description: "description", location: "location", imageURL: URL(string: "https://a-url.com")!)
        
       
        let itemJSON = ["items": [item1.json, item2.json]]
        let json = try! JSONSerialization.data(withJSONObject: itemJSON)

        let (sut , client) = makeSUT()
       
        expect(sut, expectedResult: .success([item1.model, item2.model])) {
            client.complete(with: 200 , and: json)
        }
    }
    
    private func expect(_ sut: RemoteFeedLoader, expectedResult: RemoteFeedLoader.Result, action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "wait to load")
        
        sut.load { result in
            
            switch (result, expectedResult) {
            case let (.success(result), .success(expectedResult)):
                XCTAssertEqual(result, expectedResult, file: file, line: line)
            case let (.failure(result as RemoteFeedLoader.Error), .failure(expectedResult as RemoteFeedLoader.Error)):
                XCTAssertEqual(result, expectedResult, file: file, line: line)
            default:
                XCTFail("expected \(expectedResult) got \(result)")
            }
            
            exp.fulfill()
        }
        
        action()
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
        var capturedResult = [RemoteFeedLoader.Result]()
        let client = HTTPClientSpy()
        var sut: RemoteFeedLoader? = RemoteFeedLoader(client: client, url: URL(string: "https://a-url.com")!)
        sut?.load { capturedResult.append($0)}
        sut = nil
        client.complete(with: 200)
        XCTAssertTrue(capturedResult.isEmpty)
    }

    
    // MARK: - Helpers
    
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (RemoteFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(client: client, url: URL(string: "https://a-url.com")!)
        trackMemoryLeaks(sut)
        trackMemoryLeaks(client)
        return (sut, client)
    }
    
    private func makeItem(id: UUID, description: String? = nil, location : String? = nil , imageURL: URL) -> (model: FeedImage, json: [String: Any]) {
        let item  = FeedImage(id: id, description: description, location: location, imageURL: imageURL)
        let itemJosn = [
            "id": item.id.uuidString,
            "description": item.description,
            "location": item.location,
            "image" : item.url.absoluteString
        ].reduce(into: [String: Any]()) { partialResult, e in
            if let value = e.value {
                partialResult[e.key] = value
            }
        }
        return (item, itemJosn as [String : Any])
    }
}
