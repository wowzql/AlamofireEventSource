//
//  Alamofire+EventSource.swift
//  AlamofireEventSource
//
//  Created by Daniel Clelland on 7/08/20.
//

import Foundation
import Alamofire

extension Session {
    
    struct RequestConvertible: URLRequestConvertible {
        let url: URLConvertible
        let method: HTTPMethod
        let parameters: Parameters?
        let encoding: ParameterEncoding
        let headers: HTTPHeaders?
        let requestModifier: RequestModifier?

        func asURLRequest() throws -> URLRequest {
            var request = try URLRequest(url: url, method: method, headers: headers)
            try requestModifier?(&request)

            return try encoding.encode(request, with: parameters)
        }
    }
    struct RequestEncodableConvertible<Parameters: Encodable>: URLRequestConvertible {
        let url: URLConvertible
        let method: HTTPMethod
        let parameters: Parameters?
        let encoder: ParameterEncoder
        let headers: HTTPHeaders?
        let requestModifier: RequestModifier?

        func asURLRequest() throws -> URLRequest {
            var request = try URLRequest(url: url, method: method, headers: headers)
            try requestModifier?(&request)

            return try parameters.map { try encoder.encode($0, into: request) } ?? request
        }
    }
    
    public func eventSourceRequest<Parameters: Encodable>(_ convertible: URLConvertible,
                      method: HTTPMethod = .get,
                      parameters: Parameters? = nil,
                      encoding: ParameterEncoding = URLEncoding.default,
                      headers: HTTPHeaders? = nil,
                      interceptor: RequestInterceptor? = nil,
                      requestModifier: RequestModifier? = nil,
                      lastEventID: String? = nil) -> DataStreamRequest {
        
        let convertible = RequestEncodableConvertible(url: convertible,
                        method: method,
                        parameters: parameters,
                        encoder: URLEncodedFormParameterEncoder.default,
                        headers: headers,
                        requestModifier: requestModifier)
    
        
        return streamRequest(convertible,
                             automaticallyCancelOnStreamError: false,
                             interceptor: interceptor)

    }
}

extension DataStreamRequest {
    
    public struct EventSource {
        public let event: EventSourceEvent
        public let token: CancellationToken
        public func cancel() {
            token.cancel()
        }
    }
    
    public enum EventSourceEvent {
        case message(EventSourceMessage)
        case complete(Completion)
    }

    @discardableResult public func responseEventSource(using serializer: EventSourceSerializer = EventSourceSerializer(), on queue: DispatchQueue = .main, handler: @escaping (EventSource) -> Void) -> DataStreamRequest {
        return responseStream(using: serializer, on: queue) { stream in
            switch stream.event {
            case .stream(let result):
                for message in try result.get() {
                    handler(EventSource(event: .message(message), token: stream.token))
                }
            case .complete(let completion):
                handler(EventSource(event: .complete(completion), token: stream.token))
            }
        }
    }
}

extension DataStreamRequest {
    
    public struct DecodableEventSource<T: Decodable> {
        public let event: DecodableEventSourceEvent<T>
        public let token: CancellationToken
        public func cancel() {
            token.cancel()
        }
    }
    
    public enum DecodableEventSourceEvent<T: Decodable> {
        case message(DecodableEventSourceMessage<T>)
        case complete(Completion)
    }

    @discardableResult public func responseDecodableEventSource<T: Decodable>(using serializer: DecodableEventSourceSerializer<T> = DecodableEventSourceSerializer(), on queue: DispatchQueue = .main, handler: @escaping (DecodableEventSource<T>) -> Void) -> DataStreamRequest {
        return responseStream(using: serializer, on: queue) { stream in
            switch stream.event {
            case .stream(let result):
                for message in try result.get() {
                    handler(DecodableEventSource(event: .message(message), token: stream.token))
                }
            case .complete(let completion):
                handler(DecodableEventSource(event: .complete(completion), token: stream.token))
            }
        }
    }
}
