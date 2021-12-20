//
//  CacheFeedUseCase.swift
//  PresentationFeedTests
//
//  Created by Alok Sinha on 2021-12-16.
//

import XCTest
import PresentationFeed

class FeedStoreSpy: FeedStore {
  
    var deleteCacheFeedCallCount = 0
    typealias DeleteCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    typealias RetrievalCompletion = (RetrieveCachedFeedResult) -> Void

    var deleteCompletions : [DeleteCompletion] = []
    var insertCompletions : [InsertionCompletion] = []
    var retrievalCompletions : [RetrievalCompletion] = []

    var insertions: [(items: [LocalFeedImage], timeStamp: Date)] = []
    
    var receivedMessages = [ReceivedMessage]()
    
    enum ReceivedMessage: Equatable {
        case deleteCachedFeed
        case insert([LocalFeedImage], Date)
        case retrieve

    }
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        deleteCompletions.append(completion)
        deleteCacheFeedCallCount = 1
        receivedMessages.append(.deleteCachedFeed)
    }
    
    func insert(_ feed : [LocalFeedImage], timeStamp: Date, completion: @escaping InsertionCompletion) {
        insertions.append((feed, timeStamp))
        receivedMessages.append(.insert(feed, timeStamp))
        insertCompletions.append(completion)
    }
    
    func completionInsertion(with error: Error) {
        insertCompletions[0](error)
    }
    
    func completionDeletion(with error: Error) {
        deleteCompletions[0](error)
    }
    
    func completionDeletionSuccesfully() {
        deleteCompletions[0](nil)
    }
    
    func completionInsertionSuccesfully() {
        insertCompletions[0](nil)
    }
    
    func retrieve(completion: @escaping RetrievalCompletion) {
       retrievalCompletions.append(completion)
        receivedMessages.append(.retrieve)
    }
    
    func completeRetrieve(with error: Error) {
        retrievalCompletions[0](.failure(error))
    }
    
    func completeRetrievalWithEmptyCache() {
        retrievalCompletions[0](.empty)
    }
    
    func complete(with feed: [LocalFeedImage], and date: Date) {
        retrievalCompletions[0](.found(feed: feed, timestamp: date))
    }
}

class CacheFeedUseCase: XCTestCase {
    
    func test_init_doesNotDeleteCache() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.receivedMessages,[])
    }
    
    func test_save_requestsCacheDeletion() {
        let (sut, store) = makeSUT()
        sut.save([uniqeImage]) { _ in }
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        
        sut.save([uniqeImage]) { _ in }
        store.completionDeletion(with : anyNSError())
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }
    
    func test_save_requestNewCacheInsertionWithTimestampOnSuccessfulDeletion() {
        let timeStamp = Date()
        let (sut, store) = makeSUT(timestamp: { timeStamp })
        let items = [uniqeImage]
        let localFeedItems = items.map { LocalFeedImage (id: $0.id, description: $0.description, location: $0.location, imageURL: $0.url)}
        sut.save(items) { _ in }
        store.completionDeletionSuccesfully()
        
        XCTAssertEqual(store.insertions.count, 1)
        XCTAssertEqual(store.insertions.first?.items, localFeedItems)
        XCTAssertEqual(store.insertions.first?.timeStamp, timeStamp)
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed , .insert(localFeedItems, timeStamp)])
    }
    
    func test_save_failsDeletionError() {
        let (sut, store) = makeSUT()
        let deletionError = anyNSError()
        var receivedError: Error?
        let exp = expectation(description: "wait for completion")
        sut.save([uniqeImage]) { error in
            receivedError = error
            exp.fulfill()
        }
        
        store.completionDeletion(with: deletionError)
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(receivedError as NSError?, deletionError)
    }
    
    func test_save_failsOnInsertionError() {
        let (sut, store) = makeSUT()
        let insertionError = anyNSError()
        var receivedError: Error?
        let exp = expectation(description: "wait for completion")
        
        sut.save([uniqeImage]) { error in
            receivedError = error
            exp.fulfill()
        }
        store.completionDeletionSuccesfully()
        store.completionInsertion(with: insertionError)
        
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(receivedError as NSError?, insertionError)
    }
    
    func test_save_succeedsOnSuccessfulCacheInsertion() {
        let (sut, store) = makeSUT()
        var receivedError: Error?
        
        let exp = expectation(description: "wait for completion")
        sut.save([uniqeImage]) { error in
            receivedError = error
            exp.fulfill()
        }
        
        store.completionDeletionSuccesfully()
        store.completionInsertionSuccesfully()
        
        wait(for: [exp], timeout: 1.0)
        XCTAssertNil(receivedError)
    }
    
    func test_save_doesNotDeliverDeletionErrorWhenSUThasbeendellocated() {
        
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        let deletionError = anyNSError()
        var receivedError: Error?
        
        sut?.save([uniqeImage]) { error in
            receivedError = error
        }
        sut = nil
        store.completionDeletion(with: deletionError)
        
        XCTAssertNil(receivedError)
    }
    
    func test_save_doesNotDeliverInsertionErrorWhenSUThasbeendellocated() {
        
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        let insertionError = anyNSError()
        var receivedError: Error?
        
        sut?.save([uniqeImage ]) { error in
            receivedError = error
        }
        
        store.completionDeletionSuccesfully()

        sut = nil
        store.completionInsertion(with: insertionError)
        
        XCTAssertNil(receivedError)
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
    
    private func anyURL()-> URL {
        return URL(string: "https://a-anyurl.com")!
    }
    
    private func anyNSError() -> NSError {
        NSError(domain: "Test", code: 404)
    }
}
