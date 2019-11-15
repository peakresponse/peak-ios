//
//  URL+Extensions.swift
//  Triage
//
//  Created by Francis Li on 11/14/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import Foundation
import MobileCoreServices

extension URL {
    var contentType: String {
        let fileExtension: CFString = pathExtension as CFString
        if let extUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, nil)?.takeUnretainedValue(),
            let mimeUTI = UTTypeCopyPreferredTagWithClass(extUTI, kUTTagClassMIMEType) {
            return mimeUTI.takeUnretainedValue() as String
        }
        return "application/octet-stream"
    }
}
