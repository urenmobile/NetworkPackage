//
//  APIManager.swift
//  quranreadlistenmemorize
//
//  Created by Remzi YILDIRIM on 2/5/19.
//  Copyright © 2019 Remzi YILDIRIM. All rights reserved.
//

import Foundation

public class APIManager: NSObject {
    
    public static let shared = APIManager()

    public var completion: ((NetworkResult<(sourceUrl: URL, location: URL)>) -> Void)?
    
    private weak var dataTask: URLSessionDataTask?
    private weak var downloadTask: URLSessionDownloadTask?
    
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = URLRequest.CachePolicy.returnCacheDataElseLoad
        config.urlCache = URLCache.shared
        return URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue.main)
    }()
    
    private let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        return formatter
    }()
    
    // information function
    public func startDownloadProgress(with request: URLRequest) {
        downloadTask?.cancel()
        
        // Don't specify a completion handler here which prevent call the delegate
        downloadTask = session.downloadTask(with: request)
        downloadTask?.resume()
    }
    
    public func download(with request: URLRequest, completion: @escaping (NetworkResult<URL>) -> Void) {
        
        let task = session.downloadTask(with: request) { (url, response, error) in
            if let error = error {
                debugPrint("Error oldu: \(error)")
                completion(.failure(.serverError(error)))
            }
            
            guard let url = url else {
                completion(.failure(.missingDataError))
                return
            }
            
            // return temporary download location url
            completion(.success(url))
        }
        task.resume()
    }
    
    public func getDataWithNoCache<T: Decodable>(_ parseType: T.Type, request: URLRequest, completion: @escaping (NetworkResult<[T]>) -> Void) {
        
        let task = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                debugPrint("Error oldu: \(error)")
                completion(NetworkResult.failure(NetworkResult.BackEndAPIError.serverError(error)))
            }
            
            guard let data = data,
                let response = response as? HTTPURLResponse,
                (200...299).contains(response.statusCode) else {
                    debugPrint("Server Response Error)")
                    return }
            
            // Parse data
            do {
                let parsedObject = try JSONDecoder().decode([T].self, from: data)
                completion(.success(parsedObject))
                
            } catch let parsingError {
                debugPrint("Error: when parsing: \(parsingError)")
                completion(.failure(.parseDataError))
            }
        }
        task.resume()
        
    }
    
    public func getDataWithCache<T: Decodable>(_ parseType: T.Type, request: URLRequest, completion: @escaping (NetworkResult<[T]>) -> Void) {
        
        if let data = getFromCache(request: request) {
            // Parse data
            do {
                let parsedObject = try JSONDecoder().decode([T].self, from: data)
                completion(.success(parsedObject))
                
            } catch let parsingError {
                debugPrint("Error: when parsing: \(parsingError)")
                completion(.failure(.parseDataError))
            }
        } else {
            
            let task = session.dataTask(with: request) { (data, response, error) in
                if let error = error {
                    debugPrint("Error session dataTask: \(error)")
                    completion(NetworkResult.failure(NetworkResult.BackEndAPIError.serverError(error)))
                }
                
                guard let data = data,
                    let response = response as? HTTPURLResponse,
                    (200...299).contains(response.statusCode) else {
                        debugPrint("Server Response Error")
                        return }
                
                // Parse data
                do {
                    let parsedObject = try JSONDecoder().decode([T].self, from: data)
                    completion(.success(parsedObject))
                    
                    // parse success then cache data
                    let cachedData = CachedURLResponse(response: response, data: data)
                    URLCache.shared.storeCachedResponse(cachedData, for: request)
                    
                } catch let parsingError {
                    debugPrint("Error: when parsing: \(parsingError)")
                    completion(.failure(.parseDataError))
                }
            }
            task.resume()
        }
    }
    
    private func getFromCache(request: URLRequest) -> Data? {
        if let response = URLCache.shared.cachedResponse(for: request) {
            return response.data
        }
        return nil
    }
    
}

extension APIManager: URLSessionDelegate, URLSessionDownloadDelegate {
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            debugPrint("Task completed with Error: \(task), error: \(error)")
            completion?(.failure(.serverError(error)))
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        let written = byteFormatter.string(fromByteCount: totalBytesWritten)
        let expected = byteFormatter.string(fromByteCount: totalBytesExpectedToWrite)
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        
        completion?(NetworkResult.progress(written, expected, progress))
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        guard let sourceUrl = downloadTask.originalRequest?.url else {
            completion?(.failure(.missingDataError))
            return
        }
        completion?(.success((sourceUrl: sourceUrl, location: location)))
    }
    
}
