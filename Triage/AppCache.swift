//
//  AppCache.swift
//  Triage
//
//  Created by Francis Li on 11/14/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import UIKit

class AppCache {
    static func cachedImage(from urlString: String, completionHandler: @escaping (UIImage?, Error?) -> Void) {
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
                    let destURL = cacheDirURL.appendingPathComponent(String(url.path.dropFirst()), isDirectory: false)
                    var image: UIImage?
                    if fileManager.fileExists(atPath: destURL.path) {
                        let data = try Data(contentsOf: destURL)
                        image = UIImage(data: data)
                    } else {
                        // download into cache location
                        let data = try Data(contentsOf: url)
                        image = UIImage(data: data)
                        if image != nil {
                            try fileManager.createDirectory(atPath: destURL.deletingLastPathComponent().path, withIntermediateDirectories: true, attributes: nil)
                            fileManager.createFile(atPath: destURL.path, contents: data, attributes: nil)
                        }
                    }
                    completionHandler(image, nil)
                } catch {
                    completionHandler(nil, error)
                }
            }
            completionHandler(nil, nil)
        }
    }

    static func cache(fileURL: URL, pathPrefix: String, filename: String) {
        do {
            let fileManager = FileManager.default
            let cacheDirURL = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let destURL = cacheDirURL.appendingPathComponent(pathPrefix, isDirectory: true).appendingPathComponent(filename, isDirectory: false)
            try fileManager.createDirectory(atPath: destURL.deletingLastPathComponent().path, withIntermediateDirectories: true, attributes: nil)
            try fileManager.moveItem(at: fileURL, to: destURL)
        } catch {
            print(error)
        }
    }
}
