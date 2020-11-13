//
//  APIManagerTests.swift
//  
//
//  Created by Remzi YILDIRIM on 11/9/20.
//

import XCTest
@testable import NetworkPackage

final class APIManagerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func test_whenAPI_thenNotNil() {
        // Given
        let api = APIManager()
        
        // When
        
        // Then
        XCTAssertNotNil(api)
    }

}

// MARK: - All Tests
extension APIManagerTests {
    static var allTests = [
        ("test_whenAPI_thenNotNil", test_whenAPI_thenNotNil),
    ]
}
