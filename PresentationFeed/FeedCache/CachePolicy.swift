//
//  CachePolicy.swift
//  PresentationFeed
//
//  Created by Alok Sinha on 2021-12-19.
//


public final class CachePolicy {
    
    private init() {}
    
    static var maxAge: Int {
        7
    }
    
    static func validate(timeStamp: Date, against date: Date)-> Bool {
        let calander = Calendar(identifier: .gregorian)
        guard let maxCacheAge = calander.date(byAdding: .day, value: maxAge, to: timeStamp) else {
            return false
        }
        
        print("date is \(date)")
        print("maxCacheAge is \(maxCacheAge)")

        return date < maxCacheAge
    }
}
