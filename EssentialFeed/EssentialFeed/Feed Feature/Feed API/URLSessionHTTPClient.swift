//
//  URLSessionHTTPClient.swift
//  EssentialFeed
//
//  Created by Ivan Slavov on 5.09.22.
//

import Foundation

public class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    } 
    
    private struct UnexpectedValueRepresentation: Error {}

    public func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { data, responce, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = data, let responce = responce as? HTTPURLResponse {
                completion(.success(data, responce))
            } else {
                completion(.failure(UnexpectedValueRepresentation()))
            }
        }.resume()
    }
}
