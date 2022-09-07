//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Ivan Slavov on 1.09.22.
//

import Foundation

public enum LoadFeedResult {
    case success([FeedItem])
    case failure(Error)
}

public protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
