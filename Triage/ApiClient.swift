//
//  ApiClient.swift
//  Triage
//
//  Created by Francis Li on 11/1/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import Foundation
import Keys
import Starscream

enum ApiClientError: Error {
    case csrf
    case unauthorized
    case forbidden
    case unexpected
    case notFound
    case disconnected
}

// swiftlint:disable type_body_length file_length
class ApiClient {
    static var shared: ApiClient = ApiClient(baseURL: TriageKeys().apiClientServerUrl)! {
        willSet {
            shared.invalidate()
        }
    }

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

    func urlRequest(for path: String, data: Data? = nil, params: [String: Any]? = nil,
                    method: String = "GET", body: Any? = nil) -> URLRequest {
        var url: URL
        if path.starts(with: "http") {
            url = URL(string: path)!
        } else {
            var components = URLComponents()
            components.path = path
            if let params = params {
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
        }
        if let subdomain = AppSettings.subdomain {
            request.setValue(subdomain, forHTTPHeaderField: "X-Agency-Subdomain")
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
        if let subdomain = AppSettings.subdomain {
            request.setValue(subdomain, forHTTPHeaderField: "X-Agency-Subdomain")
        }
        let socket = WebSocket(request: request)
        socket.onEvent = { [weak self] event in
            objc_sync_enter(socket)
            var data: Data?
            switch event {
            case .connected(let headers):
                print("websocket is connected: \(headers)")
                self?.pingWebSocket(socket: socket)
            case .disconnected(let reason, let code):
                print("websocket is disconnected: \(reason) with code: \(code)")
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

    func POST<T>(path: String, params: [String: Any]? = nil, data: Data? = nil, body: Any? = nil,
                 completionHandler: @escaping (URLRequest, URLResponse?, T?, Error?) -> Void) -> URLSessionTask {
        let request = urlRequest(for: path, data: data, params: params, method: "POST", body: body)
        return session.dataTask(with: request, completionHandler: { (data, response, error) in
            self.completionHandler(request: request, data: data, response: response, error: error, completionHandler: completionHandler)
        })
    }

    func PUT<T>(path: String, params: [String: Any]? = nil, data: Data? = nil, body: Any? = nil,
                completionHandler: @escaping (URLRequest, URLResponse?, T?, Error?) -> Void) -> URLSessionTask {
        let request = urlRequest(for: path, data: data, params: params, method: "PUT", body: body)
        return session.dataTask(with: request, completionHandler: { (data, response, error) in
            self.completionHandler(request: request, data: data, response: response, error: error, completionHandler: completionHandler)
        })
    }

    func PATCH<T>(path: String, params: [String: Any]? = nil, data: Data? = nil, body: Any? = nil,
                  completionHandler: @escaping (URLRequest, URLResponse?, T?, Error?) -> Void) -> URLSessionTask {
        let request = urlRequest(for: path, data: data, params: params, method: "PATCH", body: body)
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

    // MARK: - Sessions

    func login(email: String, password: String, completionHandler: @escaping (URLRequest, URLResponse?, [String: Any]?, Error?) -> Void) -> URLSessionTask {
        return POST(path: "/login", body: [
            "email": email,
            "password": password
        ]) { (request, response, data, error) in
            completionHandler(request, response, data, error)
        }
    }

    func logout(completionHandler: @escaping () -> Void) {
        session.reset(completionHandler: completionHandler)
    }

    func me(completionHandler: @escaping (URLRequest, URLResponse?, [String: Any]?, Error?) -> Void) -> URLSessionTask {
        return GET(path: "/api/users/me", completionHandler: completionHandler)
    }

    // MARK: - Agencies

    func connect(completionHandler: @escaping (WebSocket, [String: Any]?, Error?) -> Void) -> WebSocket {
        return WS(path: "/agency", completionHandler: completionHandler)
    }

    func getAgencies(search: String? = nil, completionHandler: @escaping (URLRequest, URLResponse?, [[String: Any]]?, Error?) -> Void) -> URLSessionTask {
        var params: [String: String] = [:]
        if let search = search, !search.isEmpty {
            params["search"] = search
        }
        return GET(path: "/api/agencies", params: params, completionHandler: completionHandler)
    }

    // MARK: - Assignments

    func createAssignment(data: [String: Any], completionHandler: @escaping (URLRequest, URLResponse?, [String: Any]?, Error?) -> Void) -> URLSessionTask {
        return POST(path: "/api/assignments", body: data, completionHandler: completionHandler)
    }

    // MARK: - Facilities

    func getFacilities(lat: String, lng: String, search: String? = nil, type: String? = nil,
                       completionHandler: @escaping (URLRequest, URLResponse?, [[String: Any]]?, Error?) -> Void) -> URLSessionTask {
        var params = ["lat": lat, "lng": lng]
        if let search = search, !search.isEmpty {
            params["search"] = search
        }
        if let type = type, !type.isEmpty {
            params["type"] = type
        }
        return GET(path: "/api/facilities", params: params, completionHandler: completionHandler)
    }

    // MARK: - Incidents

    func getIncidents(vehicleId: String? = nil, search: String? = nil,
                      completionHandler: @escaping (URLRequest, URLResponse?, [[String: Any]]?, Error?) -> Void) -> URLSessionTask {
        var params: [String: Any] = [:]
        if let vehicleId = vehicleId {
            params["vehicleId"] = vehicleId
        }
        if let search = search {
            params["search"] = search
        }
        return GET(path: "/api/incidents", params: params, completionHandler: completionHandler)
    }

    // MARK: - Lists

    func getLists(completionHandler: @escaping (URLRequest, URLResponse?, [String: Any]?, Error?) -> Void) -> URLSessionTask {
        return GET(path: "/api/lists/all", completionHandler: completionHandler)
    }

    // MARK: - Patients

    func getPatients(sceneId: String, completionHandler: @escaping (URLRequest, URLResponse?, [[String: Any]]?, Error?) -> Void) -> URLSessionTask {
        let params = ["sceneId": sceneId]
        return GET(path: "/api/patients", params: params, completionHandler: completionHandler)
    }

    func getPatient(idOrPin: String, completionHandler: @escaping (URLRequest, URLResponse?, [String: Any]?, Error?) -> Void) -> URLSessionTask {
        return GET(path: "/api/patients/\(idOrPin)", completionHandler: completionHandler)
    }

    func createOrUpdatePatient(data: [String: Any], completionHandler: @escaping (URLRequest, URLResponse?, [String: Any]?, Error?) -> Void) -> URLSessionTask {
        return POST(path: "/api/patients", body: data, completionHandler: completionHandler)
    }

    // MARK: - Scenes

    func connect(sceneId: String,
                 completionHandler: @escaping (WebSocket, [String: Any]?, Error?) -> Void) -> WebSocket {
        return WS(path: "/scene", params: ["id": sceneId], completionHandler: completionHandler)
    }

    func createScene(data: [String: Any], completionHandler: @escaping (URLRequest, URLResponse?, [String: Any]?, Error?) -> Void) -> URLSessionTask {
        return POST(path: "/api/scenes", body: data, completionHandler: completionHandler)
    }

    func updateScene(data: [String: Any],
                     completionHandler: @escaping (URLRequest, URLResponse?, [String: Any]?, Error?) -> Void) -> URLSessionTask {
        return PATCH(path: "/api/scenes", body: data, completionHandler: completionHandler)
    }

    func getScene(sceneId: String, completionHandler: @escaping (URLRequest, URLResponse?, [String: Any]?, Error?) -> Void) -> URLSessionTask {
        return GET(path: "/api/scenes/\(sceneId)", completionHandler: completionHandler)
    }

    func getScenes(completionHandler: @escaping (URLRequest, URLResponse?, [[String: Any]]?, Error?) -> Void) -> URLSessionTask {
        return GET(path: "/api/scenes", completionHandler: completionHandler)
    }

    func closeScene(sceneId: String, completionHandler: @escaping (URLRequest, URLResponse?, [String: Any]?, Error?) -> Void) -> URLSessionTask {
        return PATCH(path: "/api/scenes/\(sceneId)/close", completionHandler: completionHandler)
    }

    func joinScene(sceneId: String, completionHandler: @escaping (URLRequest, URLResponse?, [String: Any]?, Error?) -> Void) -> URLSessionTask {
        return PATCH(path: "/api/scenes/\(sceneId)/join", completionHandler: completionHandler)
    }

    func addScenePin(sceneId: String, data: [String: Any],
                     completionHandler: @escaping (Error?) -> Void) -> URLSessionTask {
        return POST(path: "/api/scenes/\(sceneId)/pins", body: data, completionHandler: { (_, _, _: [String: Any]?, error) in
            completionHandler(error)
        })
    }

    func removeScenePin(sceneId: String, scenePinId: String, completionHandler: @escaping (Error?) -> Void) -> URLSessionTask {
        return DELETE(path: "/api/scenes/\(sceneId)/pins/\(scenePinId)") { (_, _, _: [String: Any]?, error) in
            completionHandler(error)
        }
    }

    func leaveScene(sceneId: String, completionHandler: @escaping (URLRequest, URLResponse?, [String: Any]?, Error?) -> Void) -> URLSessionTask {
        return PATCH(path: "/api/scenes/\(sceneId)/leave", completionHandler: completionHandler)
    }

    func transferScene(sceneId: String, userId: String, agencyId: String, completionHandler: @escaping (Error?) -> Void) -> URLSessionTask {
        return PATCH(path: "/api/scenes/\(sceneId)/transfer", body: [
            "userId": userId,
            "agencyId": agencyId
        ], completionHandler: { (_, _, _: [String: Any]?, error: Error?) in
            completionHandler(error)
        })
    }

    // MARK: - Responders

    func getResponders(sceneId: String, completionHandler: @escaping (URLRequest, URLResponse?, [[String: Any]]?, Error?) -> Void) -> URLSessionTask {
        return GET(path: "/api/responders", params: ["sceneId": sceneId], completionHandler: completionHandler)
    }

    func assignResponder(responderId: String, role: String?, completionHandler: @escaping (Error?) -> Void) -> URLSessionTask {
        return PATCH(path: "/api/responders/\(responderId)/assign", body: [
            "role": role != nil ? role as Any : NSNull()
        ], completionHandler: { (_, _, _: [String: Any]?, error: Error?) in
            completionHandler(error)
        })
    }

    // MARK: - Uploads

    func upload(fileName: String, contentType: String, completionHandler: @escaping (URLRequest, URLResponse?, [String: Any]?, Error?) -> Void) -> URLSessionTask {
        return POST(path: "/api/assets", body: [
            "blob": [
                "content_type": contentType,
                "signed_id": fileName
            ]
        ]) { [weak self] (request, response, data: [String: Any]?, error: Error?) in
            var data = data
            if var directUpload = data?["direct_upload"] as? [String: Any], let url = directUpload["url"] as? String {
                if url.starts(with: "/") {
                    let request = self?.urlRequest(for: url)
                    if let url = request?.url {
                        directUpload["url"] = url.absoluteString
                        data?["direct_upload"] = directUpload
                    }
                }
            }
            completionHandler(request, response, data, error)
        }
    }

    func upload(fileName: String, fileURL: URL, completionHandler: @escaping (URLRequest, URLResponse?, [String: Any]?, Error?) -> Void) -> URLSessionTask {
        return upload(fileName: fileName, contentType: fileURL.contentType, completionHandler: completionHandler)
    }

    func upload(fileURL: URL, toURL: URL, headers: [String: Any]? = nil, completionHandler: @escaping (Error?) -> Void) -> URLSessionTask {
        var request = URLRequest(url: toURL)
        request.httpMethod = "PUT"
        if toURL.absoluteString.starts(with: baseURL.absoluteString) {
            if let subdomain = AppSettings.subdomain {
                request.setValue(subdomain, forHTTPHeaderField: "X-Agency-Subdomain")
            }
        }
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value as? String, forHTTPHeaderField: key)
            }
        }
        return session.uploadTask(with: request, fromFile: fileURL) { (_, _, error) in
            completionHandler(error)
        }
    }

    // MARK: - Utils

    func geocode(lat: String, lng: String, completionHandler: @escaping (URLRequest, URLResponse?, [String: Any]?, Error?) -> Void) -> URLSessionTask {
        return GET(path: "/api/utils/geocode", params: ["lat": lat, "lng": lng], completionHandler: completionHandler)
    }

    // MARK: - Vehicles

    func getVehicles(completionHandler: @escaping (URLRequest, URLResponse?, [[String: Any]]?, Error?) -> Void) -> URLSessionTask {
        return GET(path: "/api/demographics/vehicles", completionHandler: completionHandler)
    }
}
