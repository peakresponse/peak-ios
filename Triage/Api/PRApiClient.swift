//
//  ApiClient.swift
//  Triage
//
//  Created by Francis Li on 11/1/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import CoreLocation
import Foundation
import Keys
import Starscream

// swiftlint:disable type_body_length file_length
class PRApiClient: ApiClient {
    static var shared: PRApiClient = PRApiClient(baseURL: TriageKeys().apiClientServerUrl)! {
        willSet {
            shared.invalidate()
        }
    }

    static let apiLevel = "3"

    override func urlRequest(for path: String, params: [String: Any]? = nil, method: String = "GET", body: Any? = nil) -> URLRequest {
        var request = super.urlRequest(for: path, params: params, method: method, body: body)
        request.setValue(PRApiClient.apiLevel, forHTTPHeaderField: "X-Api-Level")
        if let subdomain = AppSettings.subdomain {
            request.setValue(subdomain, forHTTPHeaderField: "X-Agency-Subdomain")
        }
        return request
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

    // MARK: - OAuth

    func authorize(data: [String: String], completionHandler: @escaping (URLRequest, URLResponse?, Error?) -> Void) -> URLSessionTask {
        return POST(path: "/oauth/authorize", params: data) { (request, response, _: Any?, error) in
            completionHandler(request, response, error)
        }
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

    func fetchFacilities(payload: [String: [String]], completionHandler: @escaping (URLRequest, URLResponse?, [[String: Any]]?, Error?) -> Void) -> URLSessionTask {
        return POST(path: "/api/facilities/fetch", body: payload, completionHandler: completionHandler)
    }

    // MARK: - Cities

    func getCities(search: String, lat: String? = nil, lng: String? = nil,
                   completionHandler: @escaping (URLRequest, URLResponse?, [[String: Any]]?, Error?) -> Void) -> URLSessionTask {
        var params = ["search": search]
        if let lat = lat, let lng = lng {
            params["lat"] = lat
            params["lng"] = lng
        }
        return GET(path: "/api/cities", params: params, completionHandler: completionHandler)
    }

    // MARK: - Forms

    func getForms(completionHandler: @escaping (URLRequest, URLResponse?, [[String: Any]]?, Error?) -> Void) -> URLSessionTask {
        return GET(path: "/api/demographics/forms", completionHandler: completionHandler)
    }

    // MARK: - Incidents

    func incidents(assignmentId: String, completionHandler: @escaping (WebSocket, [String: Any]?, Error?) -> Void) -> WebSocket {
        return WS(path: "/incidents", params: ["assignmentId": assignmentId ], completionHandler: completionHandler)
    }

    func getIncidents(vehicleId: String? = nil, search: String? = nil,
                      completionHandler: @escaping (URLRequest, URLResponse?, [String: Any]?, Error?) -> Void) -> URLSessionTask {
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

    // MARK: - Reports

    func createOrUpdateReport(data: [String: Any], completionHandler: @escaping (URLRequest, URLResponse?, [String: Any]?, Error?) -> Void) -> URLSessionTask {
        return POST(path: "/api/reports", body: data, completionHandler: completionHandler)
    }

    func getReports(incidentId: String, completionHandler: @escaping (URLRequest, URLResponse?, [String: Any]?, Error?) -> Void) -> URLSessionTask {
        return GET(path: "/api/reports", params: ["incidentId": incidentId], completionHandler: completionHandler)
    }

    // MARK: - Scenes

    func connect(sceneId: String,
                 completionHandler: @escaping (WebSocket, [String: Any]?, Error?) -> Void) -> WebSocket {
        return WS(path: "/scene", params: ["id": sceneId], completionHandler: completionHandler)
    }

    func createOrUpdateScene(data: [String: Any], completionHandler: @escaping (URLRequest, URLResponse?, [String: Any]?, Error?) -> Void) -> URLSessionTask {
        return POST(path: "/api/scenes", body: data, completionHandler: completionHandler)
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

    // MARK: - States

    func getStates(search: String, completionHandler: @escaping (URLRequest, URLResponse?, [[String: Any]]?, Error?) -> Void) -> URLSessionTask {
        return GET(path: "/api/states", params: ["search": search], completionHandler: completionHandler)
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
