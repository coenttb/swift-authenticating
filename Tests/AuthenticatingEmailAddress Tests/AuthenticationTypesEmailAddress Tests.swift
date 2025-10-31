//
//  AuthenticationTypesEmailAddress Tests.swift
//  swift-authenticating
//
//  Created by Coen ten Thije Boonkkamp on 24/07/2024.
//

import Testing
import Foundation
@testable import AuthenticatingEmailAddress
@testable import AuthenticatingURLRouting

typealias BasicAuth = RFC_7617.Basic

@Suite("BasicAuth with EmailAddress Tests")
struct BasicAuthEmailAddressTests {

    @Test("Creates BasicAuth with valid email address")
    func testCreateBasicAuthWithValidEmail() throws {
        let email = try EmailAddress("user@example.com")
        let auth = try BasicAuth(emailAddress: email, password: "password123")

        #expect(auth.username == "user@example.com")
        #expect(auth.password == "password123")
    }

    @Test("Creates BasicAuth with email containing special characters")
    func testCreateBasicAuthWithSpecialCharactersEmail() throws {
        // Email addresses can have special characters before @
        let email = try EmailAddress("user+tag@example.com")
        let auth = try BasicAuth(emailAddress: email, password: "p@ssw0rd!")

        #expect(auth.username == "user+tag@example.com")
        #expect(auth.password == "p@ssw0rd!")
    }

    @Test("Creates BasicAuth with email containing dots")
    func testCreateBasicAuthWithDotsInEmail() throws {
        let email = try EmailAddress("first.last@example.com")
        let auth = try BasicAuth(emailAddress: email, password: "secure123")

        #expect(auth.username == "first.last@example.com")
        #expect(auth.password == "secure123")
    }

    @Test("Creates BasicAuth with email containing numbers")
    func testCreateBasicAuthWithNumbersInEmail() throws {
        let email = try EmailAddress("user123@example.com")
        let auth = try BasicAuth(emailAddress: email, password: "pass")

        #expect(auth.username == "user123@example.com")
        #expect(auth.password == "pass")
    }

    @Test("Creates BasicAuth with email containing hyphen in domain")
    func testCreateBasicAuthWithHyphenInDomain() throws {
        let email = try EmailAddress("user@my-domain.com")
        let auth = try BasicAuth(emailAddress: email, password: "password")

        #expect(auth.username == "user@my-domain.com")
        #expect(auth.password == "password")
    }

    @Test("Round-trip encoding and decoding preserves email credentials")
    func testRoundTripEncodingWithEmail() throws {
        let email = try EmailAddress("test@example.com")
        let originalAuth = try BasicAuth(emailAddress: email, password: "testpass")

        // Encode the credentials
        let encoded = originalAuth.encoded()

        // Parse the encoded string
        let parsedAuth = try BasicAuth.parse(from: "Basic \(encoded)")

        #expect(parsedAuth.username == originalAuth.username)
        #expect(parsedAuth.password == originalAuth.password)
    }

    @Test("BasicAuth with email matches BasicAuth with string username")
    func testEmailAddressMatchesStringUsername() throws {
        let emailAddress = try EmailAddress("user@example.com")
        let authWithEmail = try BasicAuth(emailAddress: emailAddress, password: "pass123")
        let authWithString = try BasicAuth(username: "user@example.com", password: "pass123")

        #expect(authWithEmail.username == authWithString.username)
        #expect(authWithEmail.password == authWithString.password)
        #expect(authWithEmail.encoded() == authWithString.encoded())
    }

    @Test("Creates BasicAuth with subdomain in email")
    func testCreateBasicAuthWithSubdomain() throws {
        let email = try EmailAddress("user@mail.example.com")
        let auth = try BasicAuth(emailAddress: email, password: "password")

        #expect(auth.username == "user@mail.example.com")
    }

    @Test("Creates BasicAuth with short email")
    func testCreateBasicAuthWithShortEmail() throws {
        let email = try EmailAddress("a@b.co")
        let auth = try BasicAuth(emailAddress: email, password: "pwd")

        #expect(auth.username == "a@b.co")
        #expect(auth.password == "pwd")
    }

    @Test("Base64 encoding is correct for email-based auth")
    func testBase64EncodingForEmailAuth() throws {
        let email = try EmailAddress("user@example.com")
        let auth = try BasicAuth(emailAddress: email, password: "password123")

        let encoded = auth.encoded()
        let expectedBase64 = Data("user@example.com:password123".utf8).base64EncodedString()

        #expect(encoded == expectedBase64)
    }

    @Test("Router integration with email-based BasicAuth")
    func testRouterIntegrationWithEmailAuth() throws {
        let email = try EmailAddress("api@service.com")
        let auth = try BasicAuth(emailAddress: email, password: "api-key-123")

        let router = BasicAuth.Router()
        let requestData = try router.print(auth)

        let authHeaderOptional = try #require(requestData.headers["Authorization"]?.first)
        let authHeader = try #require(authHeaderOptional)
        #expect(authHeader.starts(with: "Basic "))

        // Parse it back
        let parsed = try router.parse(requestData)
        #expect(parsed.username == "api@service.com")
        #expect(parsed.password == "api-key-123")
    }
}
