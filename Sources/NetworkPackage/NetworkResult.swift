//
//  NetworkResult.swift
//  quranreadlistenmemorize
//
//  Created by Remzi YILDIRIM on 11/9/20.
//  Copyright © 2020 Remzi YILDIRIM. All rights reserved.
//

import Foundation

public enum NetworkResult<T> {
    case progress(_ written: String, _ expected: String, _ progress: Float)
    case success(T)
    case failure(BackEndAPIError)
}

// MARK: - BackEndAPIError
extension NetworkResult {
    public enum BackEndAPIError: Error {
        // The Server returned no data
        case missingDataError
        // The Server returned wrong data
        case parseDataError
        // Can't connect to the server (maybe offline?)
        case connectionError(_ error: Error)
        // The server responded with a non 200 status code
        case serverError(_ error: Error)
    }
}
