//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Ivan Slavov on 5.09.22.
//

import XCTest
import EssentialFeed

class URLSessionHTTPClientTests: XCTestCase {

    override func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequests()
    }
    
    override func tearDown() {
        super.tearDown()
        URLProtocolStub.stopInterceptingRequests()
    }
    
    func test_getFromURL_performsGETRequestsWithURL() {
        let url = anyURL()
        let exp = expectation(description: "Wait for request")
        
        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }
        makeSUT().get(from: url) { _ in}
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_getFromURL_failsOnRequestError() {
        let requestError = anyNSError()
        if let receivedError = resultErrorFor(data: nil, responce: nil, error: requestError) as NSError? {
            XCTAssertEqual(receivedError.domain, requestError.domain)
            XCTAssertEqual(receivedError.code, requestError.code)
        }
    }

    func test_getFromURL_failsOnAllInvalidRepresentationCases() {
        XCTAssertNotNil(resultErrorFor(data: nil, responce: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, responce: nonHTTPURLResponce(), error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), responce: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), responce: nil, error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, responce: nonHTTPURLResponce(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, responce: anyHTTPURLResponce(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), responce: nonHTTPURLResponce(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), responce: anyHTTPURLResponce(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), responce: nonHTTPURLResponce(), error: nil))
    }
    
    func test_getFromURL_suceedsOnHTTPURLResponceWithData() {
        let data = anyData()
        let responce = anyHTTPURLResponce()
        let receivedValues = resultValuesFor(data: data, responce: responce, error: nil)
        
        URLProtocolStub.stub(data: nil, response: responce, error: nil)

        XCTAssertEqual(receivedValues?.data, data)
        XCTAssertEqual(receivedValues?.responce.url, responce.url)
        XCTAssertEqual(receivedValues?.responce.statusCode, responce.statusCode)
    }
    
    func test_getFromURL_suceedsWithEmptyDataOnHTTPURLResponceWithNilData() {
        let responce = anyHTTPURLResponce()
        let receivedValues = resultValuesFor(data: nil, responce: responce, error: nil)
        
        URLProtocolStub.stub(data: nil, response: responce, error: nil)
        
        let emptyData = Data()
        XCTAssertEqual(receivedValues?.data, emptyData)
        XCTAssertEqual(receivedValues?.responce.url, responce.url)
        XCTAssertEqual(receivedValues?.responce.statusCode, responce.statusCode)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> HTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func resultValuesFor(data: Data?, responce: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> (data: Data, responce: HTTPURLResponse)? {
        let result = resultFor(data: data, responce: responce, error: error, file: file, line: line)
        
        switch result {
        case let .success(data, responce):
            return (data, responce)
        default:
            XCTFail("Expected success, got \(result) instead", file: file, line: line)
            return nil
        }
    }
    
    private func resultErrorFor(data: Data?, responce: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> Error? {
        let result = resultFor(data: data, responce: responce, error: error, file: file, line: line)
        
        switch result {
        case let .failure(error):
            return error
        default:
            XCTFail("Expected failure, got \(result) instead", file: file, line: line)
            return nil
        }
    }
    
    private func resultFor(data: Data?, responce: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> HTTPClientResult {
        URLProtocolStub.stub(data: data, response: responce, error: error)
        let sut = makeSUT(file: file, line: line)
        let exp = expectation(description: "Wait for completion")
        
        var receivedResult: HTTPClientResult!
        sut.get(from: anyURL()) { result in
            receivedResult = result
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        return receivedResult
    }
    
    private func anyURL() -> URL {
        return URL(string: "http://any-url.com")!
    }
    
    private func anyData() -> Data {
        return Data(_: "Any data".utf8)
    }
    
    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }
    
    private func anyHTTPURLResponce() -> HTTPURLResponse {
        return HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
    }
    
    private func nonHTTPURLResponce() -> URLResponse {
        return URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }
    
    private class URLProtocolStub: URLProtocol {
        private static var stub: Stub?
        private static var requestObserver: ((URLRequest) -> Void)?
        
        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }

        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            stub = Stub(data: data, response: response, error: error)
        }
        
        static func observeRequests(observer: @escaping (URLRequest) -> Void) {
            requestObserver = observer
        }
        
        static func startInterceptingRequests() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }

        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stub = nil
            requestObserver = nil
        }

        override class func canInit(with request: URLRequest) -> Bool {
            return true
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }

        override func startLoading() {
            if let requestObserver = URLProtocolStub.requestObserver {
                client?.urlProtocolDidFinishLoading(self)
                return requestObserver(request)
            }
            
            
            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }

            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }

            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }

            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}
    }
}
