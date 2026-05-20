//
//  Network.swift
//  MobilityStations
//
//  Created by Bern on 2026/5/20.
//

import Foundation

enum HTTP {
    enum Method: String { case get = "GET", post = "POST", put = "PUT", delete = "DELETE" }
    typealias Parameters = [String: String]
}

struct Request {
    enum Encoding { case query, json }
}

protocol EndpointType { var path: String { get } }

protocol Requestable {
    var encoding: Request.Encoding { get }
    var httpMethod: HTTP.Method { get }
    var endpoint: EndpointType { get }
    var parameters: HTTP.Parameters { get }
}

protocol HTTPClientProtocol {
    func data(for request: URLRequest) async throws -> Data
}

final class URLSessionHTTPClient: HTTPClientProtocol {
    func data(for request: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw AppError.badStatusCode(httpResponse.statusCode)
        }

        return data
    }
}

extension String {
    func asURL() throws -> URL {
        guard let url = URL(string: self),
              let scheme = url.scheme?.lowercased(), (scheme == "http" || scheme == "https"),
              let host = url.host, !host.isEmpty else {
            throw AppError.invalidURL
        }
        return url
    }
}

enum Network {
    struct Server {
        let baseURL: URL
        static func basic(baseURL: URL) -> Server { Server(baseURL: baseURL) }
    }

    struct Service {
        let server: Server
        private let httpClient: HTTPClientProtocol
        private let decoder: JSONDecoder

        init(
            server: Server,
            httpClient: HTTPClientProtocol = URLSessionHTTPClient(),
            decoder: JSONDecoder = JSONDecoder()
        ) {
            self.server = server
            self.httpClient = httpClient
            self.decoder = decoder
        }

        func request<T: Decodable>(_ requestable: Requestable) async throws -> T {
            let urlRequest = try makeURLRequest(from: requestable)

            do {
                let data = try await httpClient.data(for: urlRequest)
                do {
                    return try decoder.decode(T.self, from: data)
                } catch {
                    throw AppError.decodingFailed(error.localizedDescription)
                }
            } catch let appError as AppError {
                throw appError
            } catch {
                throw AppError.transportError(error)
            }
        }
    }
}

private extension Network.Service {
    func makeURLRequest(from requestable: Requestable) throws -> URLRequest {
        let baseURL = server.baseURL.appendingPathComponent(requestable.endpoint.path)
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)

        if requestable.encoding == .query, requestable.httpMethod == .get, !requestable.parameters.isEmpty {
            components?.queryItems = requestable.parameters.map {
                URLQueryItem(name: $0.key, value: $0.value)
            }
        }

        guard let url = components?.url else {
            throw AppError.invalidURL
        }

        var request = URLRequest(
            url: url,
            cachePolicy: .reloadIgnoringLocalCacheData,
            timeoutInterval: 15
        )
        request.httpMethod = requestable.httpMethod.rawValue

        if requestable.httpMethod != .get, requestable.encoding == .json, !requestable.parameters.isEmpty {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: requestable.parameters, options: [])
        }

        return request
    }
}
