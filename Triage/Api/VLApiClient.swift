//
//  VLApiClient.swift
//  Triage
//
//  Created by Francis Li on 3/4/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import Foundation
import Keys
import Starscream

// swiftlint:disable type_body_length file_length
class VLApiClient: ApiClient {
    static var shared: VLApiClient = VLApiClient(baseURL: TriageKeys().vitaLinkApiClientServerUrl)! {
        willSet {
            shared.invalidate()
        }
    }

    // MARK: - Sessions

    func login(completionHandler: @escaping (URLRequest, URLResponse?, Error?) -> Void) -> URLSessionTask {
        return GET(path: "/auth/peak") { (request, response, _: [String: Any]?, error) in
            if let response = response as? HTTPURLResponse {
                if response.statusCode == 200, let url = response.url, url.path == "/oauth/authorize", let query = url.query {
                    var components = URLComponents()
                    components.query = query
                    if let queryItems = components.queryItems {
                        var data: [String: String] = [:]
                        for queryItem in queryItems {
                            data[queryItem.name] = queryItem.value ?? ""
                        }
                        let task = PRApiClient.shared.authorize(data: data, completionHandler: completionHandler)
                        task.resume()
                        return
                    }
                }
            }
            completionHandler(request, response, error ?? ApiClientError.unexpected)
        }
    }

    func connect(completionHandler: @escaping (WebSocket, [String: Any]?, Error?) -> Void) -> WebSocket {
        return WS(path: "/user", completionHandler: completionHandler)
    }

    func logout(completionHandler: @escaping () -> Void) {
        session.reset(completionHandler: completionHandler)
    }

    // MARK: - Ringdowns

    func sendRingdown(payload: [String: Any],
                      completionHandler: @escaping (URLRequest, URLResponse?, [String: Any]?, Error?) -> Void) -> URLSessionTask {
        return POST(path: "/api/ringdowns", body: payload, completionHandler: completionHandler)
    }

    func setRingdownStatus(id: String, status: RingdownStatus, dateTime: Date,
                           completionHandler: @escaping (URLRequest, URLResponse?, [String: Any]?, Error?) -> Void) -> URLSessionTask {
        return PATCH(path: "/api/ringdowns/\(id)/deliveryStatus", body: [
            "deliveryStatus": status.rawValue,
            "dateTimeLocal": dateTime.asISO8601String()
        ], completionHandler: completionHandler)
    }
}
