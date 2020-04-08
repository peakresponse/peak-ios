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
}

class ApiClient {
    static var shared: ApiClient = ApiClient(baseURL: "https://natriage.org")! {
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
        return request
    }
    
    private func completionHandler<T>(request: URLRequest, data: Data?, response: URLResponse?, error: Error?, completionHandler: @escaping (T?, Error?) -> Void) {
        if let error = error {
            completionHandler(nil, error)
        } else {
            if let response = response as? HTTPURLResponse {
                if response.statusCode >= 200 && response.statusCode < 300 {
                    if let data = data {
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
                } else {
                    completionHandler(nil, ApiClientError.unexpected)
                }
            } else {
                completionHandler(nil, ApiClientError.unexpected)
            }
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
    
    // MARK: - Sessions
    
    func login(email: String, password: String, completionHandler: @escaping (Error?) -> Void) -> URLSessionTask {
        return POST(path: "/login", body: [
            "email": email,
            "password": password
        ]) { (_: Any?, error) in
            completionHandler(error)
        }
    }
    
    func logout(completionHandler: @escaping () -> Void) {
        session.reset(completionHandler: completionHandler)
    }
 
    func me(completionHandler: @escaping ([String: Any]?, Error?) -> Void) -> URLSessionTask {
        return GET(path: "/api/users/me", completionHandler: completionHandler)
    }
    
    // MARK: - Agencies

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

    // MARK: - Observations

    func createObservation(_ data: [String: Any], completionHandler: @escaping ([String: Any]?, Error?) -> Void) -> URLSessionTask {
        return POST(path: "/api/observations", body: data, completionHandler: completionHandler)
    }
    
    // MARK: - Patients
    
    func getPatients(completionHandler: @escaping ([[String: Any]]?, Error?) -> Void) -> URLSessionTask {
        return GET(path: "/api/patients", completionHandler: completionHandler)
    }

    func getPatient(idOrPin: String, completionHandler: @escaping ([String: Any]?, Error?) -> Void) -> URLSessionTask {
        return GET(path: "/api/patients/\(idOrPin)", completionHandler: completionHandler)
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
}
