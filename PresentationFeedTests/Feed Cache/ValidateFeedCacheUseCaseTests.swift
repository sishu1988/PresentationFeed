//
//  ValidateFeedCacheUseCaseTests.swift
//  PresentationFeedTests
//
//  Created by Alok Sinha on 2021-12-19.
//

import XCTest
import PresentationFeed

class ValidateFeedCacheUseCaseTests: XCTestCase {

    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.receivedMessages, [])
    }

    func test_validateCache_deletesCacheOnRetrievalError() {
        let (sut, store) = makeSUT()

        sut.validateCache()
        store.completeRetrieve(with: anyNSError())

        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
    }
    
    func test_load_doesNotDeleteTheCacheOnEmptyCache() {
        let (sut, store) = makeSUT()

        sut.validateCache()
        store.completeRetrievalWithEmptyCache()

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_validate_doesNotDeleteOnLessThanSevenDaysOldCache() {
        let fixedCurrentDate = Date()
        let lessThan7DaysOld = fixedCurrentDate.add(-7).addingTimeInterval(1)
        
        let (sut, store) = makeSUT( timestamp: { fixedCurrentDate})
    
        let localFeed = [uniqeImage]
        
        sut.validateCache()
        store.complete(with: localFeed.toLocal(), and: lessThan7DaysOld)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_validate_deletesOnSevenDaysOldCache() {
        let fixedCurrentDate = Date()
        let lessThan7DaysOld = fixedCurrentDate.add(-7)
        
        let (sut, store) = makeSUT( timestamp: { fixedCurrentDate})
    
        let localFeed = [uniqeImage]
        
        sut.validateCache()
        
        store.complete(with: localFeed.toLocal(), and: lessThan7DaysOld)
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
    }
    
    func test_validate_deletesOnMoreThanSevenDaysOldCache() {
        let fixedCurrentDate = Date()
        let lessThan7DaysOld = fixedCurrentDate.add(-7).addingTimeInterval(-1)
        
        let (sut, store) = makeSUT( timestamp: { fixedCurrentDate})
        
        let localFeed = [uniqeImage]
        
        sut.validateCache()
        
        store.complete(with: localFeed.toLocal(), and: lessThan7DaysOld)
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
    }
    
    // MARK:- Helpers
    
    private func makeSUT(timestamp : @escaping () -> Date = Date.init) -> (LocalFeedLoader, FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: timestamp)
        return (sut, store)
    }
    
    private func anyNSError() -> NSError {
        NSError(domain: "Test", code: 404)
    }
    
    private var uniqeImage: FeedImage  {
        FeedImage(id: UUID(), description: "desc", location: "loc", imageURL: anyURL())
    }
    
    private func anyURL()-> URL {
        return URL(string: "https://a-anyurl.com")!
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
