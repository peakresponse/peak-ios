//
//  ApiClient.swift
//  Triage
//
//  Created by Francis Li on 11/1/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import Foundation

enum ApiClientError: Error {
    case csrf
    case unauthorized
    case forbidden
    case unexpected
    case notFound
}

class ApiClient {
    static var shared: ApiClient = ApiClient(baseURL: "https://peakweb.ngrok.io")! {
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

    func urlRequest(for path: String, data: Data? = nil, params: [String: Any]? = nil, method: String = "GET", body: Any? = nil) -> URLRequest {
        var components = URLComponents()
        components.path = path
        if let params = params {
            var queryItems = [URLQueryItem]()
            for (name, value) in params {
                queryItems.append(URLQueryItem(name: name, value: String(describing: value)))
            }
            components.queryItems = queryItems
        }
        let url = components.url(relativeTo: baseURL)!
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try! JSONSerialization.data(withJSONObject: body, options: [])
        }
        if let subdomain = AppSettings.subdomain {
            request.setValue(subdomain, forHTTPHeaderField: "X-Agency-Subdomain")
        }
        return request
    }
    
    private func completionHandler<T>(request: URLRequest, data: Data?, response: URLResponse?, error: Error?, completionHandler: @escaping (T?, Error?) -> Void) {
        if let error = error {
            completionHandler(nil, error)
        } else {
            if let response = response as? HTTPURLResponse {
                if response.statusCode >= 200 && response.statusCode < 300 {
                    if let data = data, data.count > 0 {
                        if let dataBlob = data as? T {
                            completionHandler(dataBlob, error)
                        } else {
                            do {
                                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? T {
                                    completionHandler(json, nil)
                                } else {
                                    completionHandler(nil, ApiClientError.unexpected)
                                }
                            } catch {
                                completionHandler(nil, error)
                            }
                        }
                    } else {
                        completionHandler(nil, nil)
                    }
                } else if response.statusCode == 401 {
                    completionHandler(nil, ApiClientError.unauthorized)
                } else if response.statusCode == 403 {
                    completionHandler(nil, ApiClientError.forbidden)
                } else if response.statusCode == 404 {
                    completionHandler(nil, ApiClientError.notFound)
                } else {
                    completionHandler(nil, ApiClientError.unexpected)
                }
            } else {
                completionHandler(nil, ApiClientError.unexpected)
            }
        }
    }

    func WS<T>(path: String, params: [String: Any]? = nil, completionHandler: @escaping (URLSessionWebSocketTask, T?, Error?) -> Void) -> URLSessionWebSocketTask {
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
        let task = session.webSocketTask(with: request)
        pingWebSocket(task: task, completionHandler: completionHandler)
        receiveFromWebSocket(task: task, completionHandler: completionHandler)
        return task
    }

    private func pingWebSocket<T>(task: URLSessionWebSocketTask, completionHandler: @escaping (URLSessionWebSocketTask, T?, Error?) -> Void) {
        guard task.closeCode == .invalid else { return }
        task.sendPing { [weak self] (error) in
            objc_sync_enter(task)
            if let error = error {
                completionHandler(task, nil, error)
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                    self?.pingWebSocket(task: task, completionHandler: completionHandler)
                }
            }
            objc_sync_exit(task)
        }
    }
    
    private func receiveFromWebSocket<T>(task: URLSessionWebSocketTask, completionHandler: @escaping (URLSessionWebSocketTask, T?, Error?) -> Void) {
        guard task.closeCode == .invalid else { return }
        task.receive { [weak self] (result) in
            objc_sync_enter(task)
            switch result {
            case .failure(let error):
                completionHandler(task, nil, error)
            case .success(let message):
                var data: Data?
                switch message {
                case .string(let text):
                    data = text.data(using: .utf8)
                case .data(data):
                    break
                default:
                    break
                }
                if let data = data {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? T {
                            completionHandler(task, json, nil)
                        } else {
                            completionHandler(task, nil, ApiClientError.unexpected)
                        }
                    } catch {
                        completionHandler(task, nil, error)
                    }
                }
                self?.receiveFromWebSocket(task: task, completionHandler: completionHandler)
            }
            objc_sync_exit(task)
        }
    }

    func GET<T>(path: String, params: [String: Any]? = nil, completionHandler: @escaping (T?, Error?) -> Void) -> URLSessionTask {
        let request = urlRequest(for: path, params: params)
        return session.dataTask(with: request, completionHandler: { (data, response, error) in
            self.completionHandler(request: request, data: data, response: response, error: error, completionHandler: completionHandler)
        })
    }
    
    func POST<T>(path: String, params: [String: Any]? = nil, data: Data? = nil, body: Any? = nil, completionHandler: @escaping (T?, Error?) -> Void) -> URLSessionTask {
        let request = urlRequest(for: path, data: data, params: params, method: "POST", body: body)
        return session.dataTask(with: request, completionHandler: { (data, response, error) in
            self.completionHandler(request: request, data: data, response: response, error: error, completionHandler: completionHandler)
        })
    }
    
    func PUT<T>(path: String, params: [String: Any]? = nil, data: Data? = nil, body: Any? = nil, completionHandler: @escaping (T?, Error?) -> Void) -> URLSessionTask {
        let request = urlRequest(for: path, data: data, params: params, method: "PUT", body: body)
        return session.dataTask(with: request, completionHandler: { (data, response, error) in
            self.completionHandler(request: request, data: data, response: response, error: error, completionHandler: completionHandler)
        })
    }
    
    func PATCH<T>(path: String, params: [String: Any]? = nil, data: Data? = nil, body: Any? = nil, completionHandler: @escaping (T?, Error?) -> Void) -> URLSessionTask {
        let request = urlRequest(for: path, data: data, params: params, method: "PATCH", body: body)
        return session.dataTask(with: request, completionHandler: { (data, response, error) in
            self.completionHandler(request: request, data: data, response: response, error: error, completionHandler: completionHandler)
        })
    }

    // MARK: - Sessions
    
    func login(email: String, password: String, completionHandler: @escaping ([String: Any]?, Error?) -> Void) -> URLSessionTask {
        return POST(path: "/login", body: [
            "email": email,
            "password": password
        ]) { (data, error) in
            completionHandler(data, error)
        }
    }
    
    func logout(completionHandler: @escaping () -> Void) {
        session.reset(completionHandler: completionHandler)
    }
 
    func me(completionHandler: @escaping ([String: Any]?, Error?) -> Void) -> URLSessionTask {
        return GET(path: "/api/users/me", completionHandler: completionHandler)
    }
    
    // MARK: - Agencies

    func connect(completionHandler: @escaping (URLSessionWebSocketTask, [String: Any]?, Error?) -> Void) -> URLSessionWebSocketTask {
        return WS(path: "/agency", completionHandler: completionHandler)
    }

    func getAgencies(search: String? = nil, completionHandler: @escaping ([[String: Any]]?, Error?) -> Void) -> URLSessionTask {
        var params: [String: String] = [:]
        if let search = search, !search.isEmpty {
            params["search"] = search
        }
        return GET(path: "/api/agencies", params: params, completionHandler: completionHandler)
    }

    // MARK: - Facilities

    func getFacilities(lat: String, lng: String, search: String? = nil, type: String? = nil, completionHandler: @escaping ([[String: Any]]?, Error?) -> Void) -> URLSessionTask {
        var params = ["lat": lat, "lng": lng]
        if let search = search, !search.isEmpty {
            params["search"] = search
        }
        if let type = type, !type.isEmpty {
            params["type"] = type
        }
        return GET(path: "/api/facilities", params: params, completionHandler: completionHandler)
    }
    
    // MARK: - Patients

    func getPatients(sceneId: String, completionHandler: @escaping ([[String: Any]]?, Error?) -> Void) -> URLSessionTask {
        let params = ["sceneId": sceneId]
        return GET(path: "/api/patients", params: params, completionHandler: completionHandler)
    }

    func getPatient(idOrPin: String, completionHandler: @escaping ([String: Any]?, Error?) -> Void) -> URLSessionTask {
        return GET(path: "/api/patients/\(idOrPin)", completionHandler: completionHandler)
    }
    
    func createOrUpdatePatient(data: [String: Any], completionHandler: @escaping ([String: Any]?, Error?) -> Void) -> URLSessionTask {
        return POST(path: "/api/patients", body: data, completionHandler: completionHandler)
    }

    // MARK: - Scenes

    func connect(sceneId: String, completionHandler: @escaping (URLSessionWebSocketTask, [String: Any]?, Error?) -> Void) -> URLSessionWebSocketTask {
        return WS(path: "/scene", params: ["id": sceneId], completionHandler: completionHandler)
    }

    func createScene(data: [String: Any], completionHandler: @escaping ([String: Any]?, Error?) -> Void) -> URLSessionTask {
        return POST(path: "/api/scenes", body: data, completionHandler: completionHandler)
    }

    func getScene(sceneId: String, completionHandler: @escaping ([String: Any]?, Error?) -> Void) -> URLSessionTask {
        return GET(path: "/api/scenes/\(sceneId)", completionHandler: completionHandler)
    }
    
    func getScenes(completionHandler: @escaping ([[String: Any]]?, Error?) -> Void) -> URLSessionTask {
        return GET(path: "/api/scenes", completionHandler: completionHandler)
    }

    func closeScene(sceneId: String, completionHandler: @escaping ([String: Any]?, Error?) -> Void) -> URLSessionTask {
        return PATCH(path: "/api/scenes/\(sceneId)/close", completionHandler: completionHandler)
    }

    func joinScene(sceneId: String, completionHandler: @escaping ([String: Any]?, Error?) -> Void) -> URLSessionTask {
        return PATCH(path: "/api/scenes/\(sceneId)/join", completionHandler: completionHandler)
    }
    
    func leaveScene(sceneId: String, completionHandler: @escaping ([String: Any]?, Error?) -> Void) -> URLSessionTask {
        return PATCH(path: "/api/scenes/\(sceneId)/leave", completionHandler: completionHandler)
    }

    // MARK: - Uploads

    func upload(contentType: String, completionHandler: @escaping ([String: Any]?, Error?) -> Void) -> URLSessionTask {
        return POST(path: "/api/uploads", body: [
            "blob": [
                "content_type": contentType
            ]
        ]) { [weak self] (response: [String: Any]?, error: Error?) in
            var response = response
            if var directUpload = response?["direct_upload"] as? [String: Any], let url = directUpload["url"] as? String {
                if url.starts(with: "/") {
                    let request = self?.urlRequest(for: url)
                    if let url = request?.url {
                        directUpload["url"] = url.absoluteString
                        response?["direct_upload"] = directUpload
                    }
                }
            }
            completionHandler(response, error)
        }
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
        return session.uploadTask(with: request, fromFile: fileURL) { (data, response, error) in
            completionHandler(error)
        }
    }

    func upload(fileURL: URL, completionHandler: @escaping ([String: Any]?, Error?) -> Void) -> URLSessionTask {
        return upload(contentType: fileURL.contentType) { [weak self] (response, error) in
            if let error = error {
                completionHandler(nil, error)
            } else if let response = response,
                let directUpload = response["direct_upload"] as? [String: Any],
                let urlString = directUpload["url"] as? String, let url = URL(string: urlString),
                let headers = directUpload["headers"] as? [String: Any] {
                let task = self?.upload(fileURL: fileURL, toURL: url, headers: headers) { (error) in
                    if let error = error {
                        completionHandler(nil, error)
                    } else {
                        completionHandler(response, nil)
                    }
                }
                task?.resume()
            }
        }
    }

    // MARK: - Utils
    
    func geocode(lat: String, lng: String, completionHandler: @escaping ([String: Any]?, Error?) -> Void) -> URLSessionTask {
        return GET(path: "/api/utils/geocode", params: ["lat": lat, "lng": lng], completionHandler: completionHandler)
    }
}
