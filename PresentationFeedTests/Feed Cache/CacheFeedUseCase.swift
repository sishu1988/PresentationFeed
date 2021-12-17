//
//  CacheFeedUseCase.swift
//  PresentationFeedTests
//
//  Created by Alok Sinha on 2021-12-16.
//

import XCTest
import PresentationFeed

class FeedStore {
    var deleteCacheFeedCallCount = 0
    typealias DeleteCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void

    var deleteCompletions : [DeleteCompletion] = []
    var insertCompletions : [InsertionCompletion] = []

    var insertions: [(items: [FeedItem], timeStamp: Date)] = []
    
    var receivedMessages = [ReceivedMessage]()
    
    enum ReceivedMessage: Equatable {
        case deleteCachedFeed
        case insert([FeedItem], Date)
    }
    
    func deleteCacheFeed(completion: @escaping (Error?) -> Void)  {
        deleteCompletions.append(completion)
        deleteCacheFeedCallCount = 1
        receivedMessages.append(.deleteCachedFeed)
    }
    
    func insert(_ items : [FeedItem], timeStamp: Date, completion: @escaping InsertionCompletion) {
        insertions.append((items, timeStamp))
        receivedMessages.append(.insert(items, timeStamp))
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
}

class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    
    init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    func save(_ items: [FeedItem], completion: @escaping (Error?) -> Void) {
        
        store.deleteCacheFeed { [unowned self] error in
            if error == nil {
                self.store.insert(items, timeStamp: currentDate(), completion: completion)
            } else {
                completion(error)
            }
        }
    }
}

class CacheFeedUseCase: XCTestCase {
    
    func test_init_doesNotDeleteCache() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.receivedMessages,[])
    }
    
    func test_save_requestsCacheDeletion() {
        let (sut, store) = makeSUT()
        sut.save([uniqeItems]) { _ in }
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        
        sut.save([uniqeItems]) { _ in }
        store.completionDeletion(with : anyNSError())
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }
    
    func test_save_requestNewCacheInsertionWithTimestampOnSuccessfulDeletion() {
        let timeStamp = Date()
        let (sut, store) = makeSUT(timestamp: { timeStamp })
        let items = [uniqeItems]
        sut.save(items) { _ in }
        store.completionDeletionSuccesfully()
        
        XCTAssertEqual(store.insertions.count, 1)
        XCTAssertEqual(store.insertions.first?.items, items)
        XCTAssertEqual(store.insertions.first?.timeStamp, timeStamp)
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed , .insert(items, timeStamp)])
    }
    
    func test_save_failsDeletionError() {
        let (sut, store) = makeSUT()
        let deletionError = anyNSError()
        var receivedError: Error?
        let exp = expectation(description: "wait for completion")
        sut.save([uniqeItems]) { error in
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
        
        sut.save([uniqeItems]) { error in
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
        sut.save([uniqeItems]) { error in
            receivedError = error
            exp.fulfill()
        }
        
        store.completionDeletionSuccesfully()
        store.completionInsertionSuccesfully()
        
        wait(for: [exp], timeout: 1.0)
        XCTAssertNil(receivedError)
    }
    
    // MARK:- Helpers
    
    private func makeSUT(timestamp : @escaping () -> Date = Date.init) -> (LocalFeedLoader, FeedStore) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store, currentDate: timestamp)
        return (sut, store)
    }
    
    private var uniqeItems: FeedItem  {
        FeedItem(id: UUID(), description: "desc", location: "loc", imageURL: anyURL())
    }
    
    private func anyURL()-> URL {
        return URL(string: "https://a-anyurl.com")!
    }
    
    private func anyNSError() -> NSError {
        NSError(domain: "Test", code: 404)
    }
}
