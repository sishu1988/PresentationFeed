//
//  XCTestCase+MemoryLeak.swift
//  AlokFeedTests
//
//  Created by Alok Sinha on 2021-11-29.
//

import XCTest

extension XCTestCase {
    
    func trackMemoryLeaks(_ object: AnyObject, file: StaticString = #file, line: UInt = #line) {
        addTeardownBlock { [weak object] in
            XCTAssertNil(object, "sut object has not been deallocated")
        }
    }
}
