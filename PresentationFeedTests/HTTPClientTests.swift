//
//  HTTPClientTests.swift
//  AlokFeedTests
//
//  Created by Alok Sinha on 2021-11-26.
//

import XCTest
@testable import PresentationFeed

class HTTPClientTests: XCTestCase {
    
    //    func test_getFromURL_createsDataTaskWithURL() {
    //        let url = URL(string: "https://a-url.com")!
    //        let session = URLSessionSpy()
    //        let sut = URLSessionHttpClient(session: session)
    //        sut.get(from: url) { _ in}
    //        XCTAssertEqual(session.receivedURLs, [url])
    //    }
    
    func test_getFromURL_ResumeDataTaskWithURL() {
        let url = URL(string: "https://a-url.com")!
        let sut = URLSessionHTTPClient()
        sut.get(from: url) {_ in}
        // XCTAssertEqual(task.resumeCount, 1)
    }
    
    func test_getFromURL_performsGetRequest() {
        let url = anyURL()
        let error = NSError(domain: "any error", code: 1)
        URLProtocolStub.stub(url: anyURL(), error: error)
        let exp = expectation(description: "wait for completion")

        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }
        
        let sut = makeSUT()
        sut.get(from: url) { _ in }
        wait(for: [exp], timeout: 2.0)
    }
    
    func test_getFromURL_failsOnRequestError() {
        let error = NSError(domain: "any error", code: 1)
        URLProtocolStub.stub(url: anyURL(), error: error)
        let expectation = expectation(description: "wait for completion")
        let sut = makeSUT()
        
        sut.get(from: anyURL()) { result in
            switch result {
            case let .failure( receivedError as NSError):
                XCTAssertEqual(receivedError.domain, error.domain)
                XCTAssertEqual(receivedError.code, error.code)
            default:
                XCTFail("This should not happen")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func test_getFromURL_successOnDataAndHTTPResponseAndNilError() {
        let data = Data()
        let response = HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)
        URLProtocolStub.stub(url: anyURL(), data: data, response: response, error: nil)
        let expectation = expectation(description: "wait for completion")
        let sut = makeSUT()
        
        sut.get(from: anyURL()) { result in
            switch result {
            case let .success(receivedData, receivedResponse):
                XCTAssertEqual(receivedData, data)
                XCTAssertEqual(receivedResponse.statusCode, response?.statusCode)
            default:
                XCTFail("This should not happen")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    override func tearDown() {
        super.tearDown()
        URLProtocol.unregisterClass(URLProtocolStub.self)
    }
    
    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(URLProtocolStub.self)
        URLProtocolStub.stub = nil
        URLProtocolStub.requestObserver = nil
    }
    
    // MARK: - Helpers
    
    private func makeSUT()-> HTTPClient {
        let sut = URLSessionHTTPClient()
        trackMemoryLeaks(sut)
        return sut
    }
    
    private func anyURL()-> URL {
        URL(string: "https://a-url.com")!
    }
}

class URLProtocolStub: URLProtocol {
    var receivedURLs = [URL]()
    
    struct Stub {
        let error: Error?
        let data : Data?
        let response: HTTPURLResponse?
    }
    
    static var stub: Stub?
    
    static var requestObserver: ((URLRequest) -> Void)?
    
    static func stub(url: URL, data: Data? = nil, response: HTTPURLResponse? = nil, error: Error? = nil) {
        stub = Stub(error: error, data: data, response: response)
    }
    
    override class func canInit(with request: URLRequest) -> Bool {
        requestObserver?(request)
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let stub = URLProtocolStub.stub else {
            return
        }
        
        if let error = stub.error {
            client?.urlProtocol(self, didFailWithError: error)
        }
        
        if let data = stub.data {
            client?.urlProtocol(self, didLoad: data)
        }
        
        if let response = stub.response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        
        client?.urlProtocolDidFinishLoading(self)
    }
    
    static func observeRequests(observer: @escaping (URLRequest) -> Void) {
        requestObserver = observer
    }
    
    override func stopLoading() {}
}


