//
//  AppCache.swift
//  Triage
//
//  Created by Francis Li on 11/14/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import UIKit

class AppCache {
    static func cachedFile(from urlString: String?, completionHandler: @escaping (URL?, Error?) -> Void) {
        guard let urlString = urlString else { return }
        DispatchQueue.global().async {
            var url: URL?
            if urlString.starts(with: "/") {
                let request = ApiClient.shared.urlRequest(for: urlString)
                url = request.url
            } else {
                url = URL(string: urlString)
            }
            if let url = url {
                // check if we have in cache or not...
                do {
                    let fileManager = FileManager.default
                    let cacheDirURL = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                    let destURL = cacheDirURL.appendingPathComponent(url.lastPathComponent, isDirectory: false)
                    if !fileManager.fileExists(atPath: destURL.path) {
                        // download into cache location
                        if urlString.starts(with: "/") {
                            let request = ApiClient.shared.urlRequest(for: urlString)
                            let task = ApiClient.shared.download(request: request) { (url, response, error) in
                                guard let response = response as? HTTPURLResponse else { return }
                                if let error = error {
                                    completionHandler(nil, error)
                                } else if let url = url, response.statusCode == 200 {
                                    do {
                                        try fileManager.moveItem(at: url, to: destURL)
                                        completionHandler(destURL, nil)
                                    } catch {
                                        completionHandler(nil, error)
                                    }
                                } else {
                                    completionHandler(nil, ApiClientError.unexpected)
                                }
                            }
                            task.resume()
                        } else {
                            let data = try Data(contentsOf: url)
                            fileManager.createFile(atPath: destURL.path, contents: data, attributes: nil)
                            completionHandler(destURL, nil)
                        }
                    } else {
                        completionHandler(destURL, nil)
                    }
                } catch {
                    completionHandler(nil, error)
                }
                return
            }
            completionHandler(nil, nil)
        }
    }

    static func cachedImage(from urlString: String?, completionHandler: @escaping (UIImage?, Error?) -> Void) {
        guard let urlString = urlString else { return }
        cachedFile(from: urlString) { (url, error) in
            if let error = error {
                completionHandler(nil, error)
            } else if let url = url {
                do {
                    let data = try Data(contentsOf: url)
                    let image = UIImage(data: data)
                    completionHandler(image, nil)
                } catch {
                    completionHandler(nil, error)
                }
            } else {
                completionHandler(nil, nil)
            }
        }
    }

    static func cache(fileURL: URL, filename: String) -> URL? {
        if let cacheFileURL = URL(string: filename) {
            do {
                let fileManager = FileManager.default
                let cacheDirURL = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                let destURL = cacheDirURL.appendingPathComponent(cacheFileURL.lastPathComponent, isDirectory: false)
                try fileManager.moveItem(at: fileURL, to: destURL)
                return destURL
            } catch {
                print(error)
            }
        }
        return nil
    }
}
