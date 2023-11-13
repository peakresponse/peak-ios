//
//  ApiClient.swift
//  Triage
//
//  Created by Francis Li on 3/6/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import Foundation
import Starscream

enum ApiClientError: Error {
    case csrf
    case unauthorized
    case forbidden
    case unexpected
    case notFound
    case disconnected
}

class ApiClient {
    var session: URLSession
    let baseURL: URL

    public required init?(baseURL: String) {
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = HTTPCookieStorage.shared
        config.httpShouldSetCookies = true
        config.httpCookieAcceptPolicy = .always
        session = URLSession(configuration: config)
        if let baseURL = URL(string: baseURL) {
            self.baseURL = baseURL
        } else {
            return nil
        }
    }

    open func invalidate() {
        session.invalidateAndCancel()
    }

    // MARK: - HTTP request helpers

    func urlRequest(for path: String, params: [String: Any]? = nil,
                    method: String = "GET", body: Any? = nil) -> URLRequest {
        var url: URL
        if path.starts(with: "http") {
            url = URL(string: path)!
        } else {
            var components = URLComponents()
            components.path = path
            if let params = params, method == "GET" {
                var queryItems = [URLQueryItem]()
                for (name, value) in params {
                    queryItems.append(URLQueryItem(name: name, value: String(describing: value)))
                }
                components.queryItems = queryItems
            }
            url = components.url(relativeTo: baseURL)!
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            // swiftlint:disable:next force_try
            request.httpBody = try! JSONSerialization.data(withJSONObject: body, options: [])
        } else if let params = params, method == "POST" {
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            var components = URLComponents()
            var queryItems = [URLQueryItem]()
            for (name, value) in params {
                queryItems.append(URLQueryItem(name: name, value: String(describing: value)))
            }
            components.queryItems = queryItems
            request.httpBody = components.query?.data(using: .utf8)
        }
        return request
    }

    private func completionHandler<T>(request: URLRequest, data: Data?, response: URLResponse?, error: Error?,
                                      completionHandler: @escaping (URLRequest, URLResponse?, T?, Error?) -> Void) {
        if let error = error {
            completionHandler(request, response, nil, error)
        } else {
            if let response = response as? HTTPURLResponse {
                if response.statusCode >= 200 && response.statusCode < 300 {
                    if let data = data, data.count > 0 {
                        if let dataBlob = data as? T {
                            completionHandler(request, response, dataBlob, error)
                        } else {
                            do {
                                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? T {
                                    completionHandler(request, response, json, nil)
                                } else {
                                    completionHandler(request, response, nil, ApiClientError.unexpected)
                                }
                            } catch {
                                completionHandler(request, response, nil, error)
                            }
                        }
                    } else {
                        completionHandler(request, response, nil, nil)
                    }
                } else if response.statusCode == 401 {
                    completionHandler(request, response, nil, ApiClientError.unauthorized)
                } else if response.statusCode == 403 {
                    completionHandler(request, response, nil, ApiClientError.forbidden)
                } else if response.statusCode == 404 {
                    completionHandler(request, response, nil, ApiClientError.notFound)
                } else {
                    completionHandler(request, response, nil, ApiClientError.unexpected)
                }
            } else {
                completionHandler(request, response, nil, ApiClientError.unexpected)
            }
        }
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    func WS<T>(path: String, params: [String: Any]? = nil,
               completionHandler: @escaping (WebSocket, T?, Error?) -> Void) -> WebSocket {
        var components = URLComponents()
        components.path = path
        if let params = params {
            var queryItems = [URLQueryItem]()
            for (name, value) in params {
                queryItems.append(URLQueryItem(name: name, value: String(describing: value)))
            }
            components.queryItems = queryItems
        }
        let urlString = baseURL.absoluteString
        let baseURL = URL(string: "ws\(urlString[urlString.index(urlString.startIndex, offsetBy: 4)...])")!
        let url = components.url(relativeTo: baseURL)!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let subdomain = AppSettings.subdomain {
            request.setValue(subdomain, forHTTPHeaderField: "X-Agency-Subdomain")
        }
        let socket = WebSocket(request: request)
        socket.callbackQueue = DispatchQueue.global(qos: .background)
        socket.onEvent = { [weak self] event in
            objc_sync_enter(socket)
            var data: Data?
            switch event {
            case .connected(let headers):
                print("websocket is connected to \(urlString): \(headers)")
                self?.pingWebSocket(socket: socket)
            case .disconnected(let reason, let code):
                print("websocket is disconnected from \(urlString): \(reason) with code: \(code)")
                completionHandler(socket, nil, ApiClientError.disconnected)
            case .text(let text):
                data = text.data(using: .utf8)
            case .binary(let payload):
                data = payload
            case .ping:
                break
            case .pong:
                completionHandler(socket, nil, nil)
            case .viabilityChanged:
                break
            case .reconnectSuggested:
                break
            case .cancelled:
                break
            case .error(let error):
                completionHandler(socket, nil, error)
            case .peerClosed:
                print("websocket peer closed from \(urlString)")
                completionHandler(socket, nil, ApiClientError.disconnected)
            @unknown default:
                break
            }
            if let data = data {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? T {
                        completionHandler(socket, json, nil)
                    } else {
                        completionHandler(socket, nil, ApiClientError.unexpected)
                    }
                } catch {
                    completionHandler(socket, nil, error)
                }
            }
            objc_sync_exit(socket)
        }
        return socket
    }

    private func pingWebSocket(socket: WebSocket) {
        objc_sync_enter(socket)
        socket.write(ping: Data()) { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                self?.pingWebSocket(socket: socket)
            }
        }
        objc_sync_exit(socket)
    }

    func GET<T>(path: String, params: [String: Any]? = nil,
                completionHandler: @escaping (URLRequest, URLResponse?, T?, Error?) -> Void) -> URLSessionTask {
        let request = urlRequest(for: path, params: params)
        return session.dataTask(with: request, completionHandler: { (data, response, error) in
            self.completionHandler(request: request, data: data, response: response, error: error, completionHandler: completionHandler)
        })
    }

    func POST<T>(path: String, params: [String: Any]? = nil, body: Any? = nil,
                 completionHandler: @escaping (URLRequest, URLResponse?, T?, Error?) -> Void) -> URLSessionTask {
        let request = urlRequest(for: path, params: params, method: "POST", body: body)
        return session.dataTask(with: request, completionHandler: { (data, response, error) in
            self.completionHandler(request: request, data: data, response: response, error: error, completionHandler: completionHandler)
        })
    }

    func PUT<T>(path: String, params: [String: Any]? = nil, body: Any? = nil,
                completionHandler: @escaping (URLRequest, URLResponse?, T?, Error?) -> Void) -> URLSessionTask {
        let request = urlRequest(for: path, params: params, method: "PUT", body: body)
        return session.dataTask(with: request, completionHandler: { (data, response, error) in
            self.completionHandler(request: request, data: data, response: response, error: error, completionHandler: completionHandler)
        })
    }

    func PATCH<T>(path: String, params: [String: Any]? = nil, body: Any? = nil,
                  completionHandler: @escaping (URLRequest, URLResponse?, T?, Error?) -> Void) -> URLSessionTask {
        let request = urlRequest(for: path, params: params, method: "PATCH", body: body)
        return session.dataTask(with: request, completionHandler: { (data, response, error) in
            self.completionHandler(request: request, data: data, response: response, error: error, completionHandler: completionHandler)
        })
    }

    func DELETE<T>(path: String, params: [String: Any]? = nil,
                   completionHandler: @escaping (URLRequest, URLResponse?, T?, Error?) -> Void) -> URLSessionTask {
        let request = urlRequest(for: path, params: params, method: "DELETE")
        return session.dataTask(with: request, completionHandler: { (data, response, error) in
            self.completionHandler(request: request, data: data, response: response, error: error, completionHandler: completionHandler)
        })
    }

    func download(request: URLRequest, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask {
        return session.downloadTask(with: request, completionHandler: completionHandler)
    }

    // swiftlint:disable:next force_try
    static let linkRE = try! NSRegularExpression(pattern: #"<([^>]+)>; rel="([^"]+)""#,
                                                 options: [.caseInsensitive])

    static func parseLinkHeader(from response: URLResponse?) -> [String: String]? {
        if let response = response as? HTTPURLResponse, let link = response.allHeaderFields["Link"] as? String {
            let matches = linkRE.matches(in: link, options: [], range: NSRange(location: 0, length: link.count))
            var links: [String: String] = [:]
            for match in matches {
                if let urlRange = Range(match.range(at: 1), in: link),
                   let typeRange = Range(match.range(at: 2), in: link) {
                    let url = String(link[urlRange])
                    let type = String(link[typeRange])
                    links[type] = url
                }
            }
            return links
        }
        return nil
    }
}
