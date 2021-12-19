//
//  LoadFeedFromCache.swift
//  PresentationFeedTests
//
//  Created by Alok Sinha on 2021-12-18.
//

import XCTest
import PresentationFeed

class LoadFeedFromCache: XCTestCase {
    
    func test_init_doesNotMessageStoreOnInit() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.receivedMessages,[])
    }
    
    func test_load_requestCacheRetrival() {
        let (sut, store) = makeSUT()
        sut.load() { _ in}
        XCTAssertEqual(store.receivedMessages,[.retrieve])
    }
    
    func test_load_failsOnRetrievalError() {
        let (sut, store) = makeSUT()
        var receivedError: Error?
        let retrievalError = anyNSError()
        let exp = expectation(description: "wait for load completion")
        sut.load() { result in
            switch result {
            case let .failure(error):
                receivedError = error
            default:
                XCTFail("Expected failure got \(result) instead")
            }
            
            exp.fulfill()
        }
        
        store.completeRetrieve(with: retrievalError)
        
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(receivedError as NSError?, retrievalError)
    }
    
    func test_load_deliversNoImageOnEmptyCache() {
        let (sut, store) = makeSUT()
        
        let exp = expectation(description: "wait for load completion")
        var receivedImages: [FeedImage]?
        
        sut.load() { result in
            switch result {
            case let .success(images):
                receivedImages = images
            default:
                XCTFail("Expected Success got \(result) instead")
            }
            exp.fulfill()
        }
        
        store.completeRetrievalWithEmptyCache()
        
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(receivedImages, [])
    }
    
    func test_load_retunsFeedOnLessThanSevenDaysOldcache() {
        let fixedCurrentDate = Date()
        let lessThan7DaysOld = fixedCurrentDate.add(-7).addingTimeInterval(1)
        
        let (sut, store) = makeSUT( timestamp: { fixedCurrentDate})
        
        let exp = expectation(description: "wait for load completion")

        var receivedImages: [FeedImage]?
        
        sut.load() { result in
            switch result {
            case let .success(images):
                receivedImages = images
            default:
                XCTFail("Expected Success got \(result) instead")
            }
            exp.fulfill()
        }
        
        let localFeed = [uniqeImage]
        
        store.complete(with: localFeed.toLocal(), and: lessThan7DaysOld)
        
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(receivedImages, localFeed)
    }
    
    func test_load_retunsFeedOnSevenDaysOldcache() {
        let fixedCurrentDate = Date()
        let lessThan7DaysOld = fixedCurrentDate.add(-7)
        
        let (sut, store) = makeSUT( timestamp: { fixedCurrentDate})
        
        let exp = expectation(description: "wait for load completion")

        var receivedImages: [FeedImage]?
        
        sut.load() { result in
            switch result {
            case let .success(images):
                receivedImages = images
            default:
                XCTFail("Expected Success got \(result) instead")
            }
            exp.fulfill()
        }
        
        let localFeed = [uniqeImage]
        
        store.complete(with: localFeed.toLocal(), and: lessThan7DaysOld)
        
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(receivedImages, [])
    }
    
    func test_load_retunsFeedOnMoreThanSevenDaysOldcache() {
        let fixedCurrentDate = Date()
        let lessThan7DaysOld = fixedCurrentDate.add(-7).add(-1)
        
        let (sut, store) = makeSUT( timestamp: { fixedCurrentDate})
        
        let exp = expectation(description: "wait for load completion")
        
        var receivedImages: [FeedImage]?
        
        sut.load() { result in
            switch result {
            case let .success(images):
                receivedImages = images
            default:
                XCTFail("Expected Success got \(result) instead")
            }
            exp.fulfill()
        }
        
        let localFeed = [uniqeImage]
        store.complete(with: localFeed.toLocal(), and: lessThan7DaysOld)
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(receivedImages, [])
    }
    
    func test_load_hasNoSideEffectOnRetrievalError() {
        let (sut, store) = makeSUT()
        sut.load() { _ in }
        store.completeRetrieve(with: anyNSError())
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_hasNoSideEffectOnEmptyCache() {
        let (sut, store) = makeSUT()
        sut.load() { _ in }
        store.completeRetrievalWithEmptyCache()
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_hasNoSideEffectOnLessThanSevenDaysOldCache() {
        let fixedCurrentDate = Date()
        let lessThan7DaysOld = fixedCurrentDate.add(-7).addingTimeInterval(1)
        
        let (sut, store) = makeSUT( timestamp: { fixedCurrentDate})
    
        
        sut.load() { _ in }
        
        let localFeed = [uniqeImage]
        
        store.complete(with: localFeed.toLocal(), and: lessThan7DaysOld)
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_hasNoSideEffectOnSevenDaysOldCache() {
        let fixedCurrentDate = Date()
        let lessThan7DaysOld = fixedCurrentDate.add(-7)
        
        let (sut, store) = makeSUT( timestamp: { fixedCurrentDate})
    
        
        sut.load() { _ in }
        
        let localFeed = [uniqeImage]
        
        store.complete(with: localFeed.toLocal(), and: lessThan7DaysOld)
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_hasNoSideEffectOnMoreThanSevenDaysOldCache() {
        let fixedCurrentDate = Date()
        let lessThan7DaysOld = fixedCurrentDate.add(-7).addingTimeInterval(-1)
        
        let (sut, store) = makeSUT( timestamp: { fixedCurrentDate})
    
        
        sut.load() { _ in }
        
        let localFeed = [uniqeImage]
        
        store.complete(with: localFeed.toLocal(), and: lessThan7DaysOld)
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
            let store = FeedStoreSpy()
            var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)

            var receivedResults = [LocalFeedLoader.LoadResult]()
            sut?.load { receivedResults.append($0) }

            sut = nil
            store.completeRetrievalWithEmptyCache()
            XCTAssertTrue(receivedResults.isEmpty)
        }
    
    // MARK:- Helpers
    
    private func makeSUT(timestamp : @escaping () -> Date = Date.init) -> (LocalFeedLoader, FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: timestamp)
        return (sut, store)
    }
    
    private var uniqeImage: FeedImage  {
        FeedImage(id: UUID(), description: "desc", location: "loc", imageURL: anyURL())
    }
    
    private func anyNSError() -> NSError {
        NSError(domain: "Test", code: 404)
    }
    
    private func anyURL()-> URL {
        return URL(string: "https://a-anyurl.com")!
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


private extension Date {
    func add(_ days: Int)-> Date {
        Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
    
    func add(_ seconds: TimeInterval)-> Date {
        self + seconds
    }
}
