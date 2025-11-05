//
//  BearerAuth Tests.swift
//  swift-authenticating
//
//  Created by Coen ten Thije Boonkkamp on 03/01/2025.
//

import Foundation
import Testing
import URLRouting

@testable import AuthenticatingURLRouting

@Suite(
    "RFC_6750.Bearer Router Tests"
)
struct RFC_6750BearerRouterTests {
    @Test("Parses valid Bearer Auth header")
    func testParseValidRFC_6750BearerHeader() throws {
        let router = RFC_6750.Bearer.Router()
        let header = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"

        let requestData = URLRequestData(headers: ["Authorization": [header]])
        let parsed = try router.parse(requestData)

        #expect(parsed.token == "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9")
    }

    @Test("Fails gracefully on missing Bearer prefix")
    func testParseInvalidRFC_6750BearerHeader() throws {
        let router = RFC_6750.Bearer.Router()
        let invalidHeader = "InvalidPrefix eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"
        let requestData = URLRequestData(headers: ["Authorization": [invalidHeader]])

        do {
            let parsed = try router.parse(requestData)
            #expect(parsed == nil, "Parsing should fail for invalid Bearer prefix")
        } catch {
            #expect(Bool(true), "An error was thrown as expected.")
        }
    }

    @Test("Prints Bearer Auth header correctly")
    func testPrintRFC_6750BearerHeader() throws {
        let router = RFC_6750.Bearer.Router()
        let auth = try RFC_6750.Bearer(token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9")

        let printed = try router.print(auth)
        let expectedHeader = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"

        let printedOptionalHeader = try #require(printed.headers["Authorization"]?.first)
        let printedHeader = try #require(printedOptionalHeader)

        #expect(
            printedHeader == expectedHeader,
            "The printed Authorization header should match the expected value."
        )
    }

    @Test("Parses and prints correctly in a round trip")
    func testRoundTrip() throws {
        let router = RFC_6750.Bearer.Router()
        let header = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"

        let requestData = URLRequestData(headers: ["Authorization": [header]])
        let parsed = try router.parse(requestData)
        let printed = try router.print(parsed)

        let printedOptionalHeader = try #require(printed.headers["Authorization"]?.first)
        let printedHeader = try #require(printedOptionalHeader)

        #expect(
            printedHeader == header,
            "Round trip parse and print should produce the same Authorization header."
        )
    }

    @Test("Handles empty token")
    func testEmptyToken() throws {
        let router = RFC_6750.Bearer.Router()
        let header = "Bearer "
        let requestData = URLRequestData(headers: ["Authorization": [header]])

        #expect(throws: Error.self) {
            let parsed = try router.parse(requestData)
            #expect(parsed.token.isEmpty, "Empty token should be parsed as empty string")
        }
    }

    @Test("Handles missing Authorization header")
    func testMissingAuthHeader() throws {
        let router = RFC_6750.Bearer.Router()
        let requestData = URLRequestData(headers: [:])

        #expect(throws: Error.self) {
            _ = try router.parse(requestData)
        }
    }

    @Test("Handles token with special characters")
    func testSpecialCharactersToken() throws {
        let router = RFC_6750.Bearer.Router()
        let token = "abc123!@#$%^&*()_+-=[]{}|;:,.<>?"
        let header = "Bearer \(token)"

        let requestData = URLRequestData(headers: ["Authorization": [header]])
        let parsed = try router.parse(requestData)

        #expect(parsed.token == token)
    }
}
