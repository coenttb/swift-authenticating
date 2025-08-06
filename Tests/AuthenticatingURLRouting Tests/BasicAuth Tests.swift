//
//  File.swift
//  swift-basic-auth
//
//  Created by Coen ten Thije Boonkkamp on 20/12/2024.
//

import Testing
import Foundation
@testable import AuthenticatingURLRouting

@Suite(
    "RFC_7617.Basic Router Tests"
)
struct RFC_7617BasicRouterTests {
    @Test("Parses valid Basic Auth header")
    func testParseValidRFC_7617BasicHeader() throws {
        let router = RFC_7617.Basic.Router()
        let header = "Basic dXNlcm5hbWU6cGFzc3dvcmQ=" // username:password
        
        let requestData = URLRequestData(headers: ["Authorization": [header]])
        let parsed = try router.parse(requestData)
        
        #expect(parsed.username == "username")
        #expect(parsed.password == "password")
    }
    
    @Test("Fails gracefully on invalid Basic Auth header")
    func testParseInvalidRFC_7617BasicHeader() throws {
        let router = RFC_7617.Basic.Router()
        let invalidHeader = "Basic invalid_base64"
        let requestData = URLRequestData(headers: ["Authorization": [invalidHeader]])

        do {
            let parsed = try router.parse(requestData)
            #expect(parsed == nil, "Parsing should fail and return nil for an invalid Base64 header")
        } catch {
            #expect(true, "An error was thrown as expected.")
        }
    }
    
    @Test("Prints Basic Auth header correctly")
    func testPrintRFC_7617BasicHeader() throws {
        let router = RFC_7617.Basic.Router()
        let auth = try RFC_7617.Basic(username: "testuser", password: "testpass")

        let printed = try router.print(auth)
        let expectedHeader = "Basic " + Data("testuser:testpass".utf8).base64EncodedString()

        let printedOptionalHeader = try #require(printed.headers["Authorization"]?.first)
        let printedHeader = try #require(printedOptionalHeader)
        
        #expect(printedHeader == expectedHeader, "The printed Authorization header should match the expected value.")
    }

    @Test("Parses and prints correctly in a round trip")
    func testRoundTrip() throws {
        let router = RFC_7617.Basic.Router()
        let header = "Basic dGVzdHVzZXI6dGVzdHBhc3M=" // testuser:testpass

        let requestData = URLRequestData(headers: ["Authorization": [header]])
        let parsed = try router.parse(requestData)
        let printed = try router.print(parsed)
        
        let printedOptionalHeader = try #require(printed.headers["Authorization"]?.first)
        let printedHeader = try #require(printedOptionalHeader)
        
        #expect(printedHeader == header, "Round trip parse and print should produce the same Authorization header.")

    }

    @Test("Parses edge cases in Basic Auth header")
    func testParseEdgeCases() throws {
        let router = RFC_7617.Basic.Router()
        let specialHeader = "Basic dXNlcm5hbWU6c3BlY2lhbCFAY2hhcnMk" // username:special!@chars$

        let requestData = URLRequestData(headers: ["Authorization": [specialHeader]])
        let parsed = try router.parse(requestData)

        #expect(parsed.username == "username", "The username should match the expected value.")
        #expect(parsed.password == "special!@chars$", "The password should match the expected value, including special characters.")
    }
}
