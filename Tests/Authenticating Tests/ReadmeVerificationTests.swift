//
//  ReadmeVerificationTests.swift
//  swift-authenticating
//
//  Tests verifying that README code examples compile and work correctly.
//

import Foundation
import Testing

@testable import Authenticating

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

@Suite("README Verification")
struct ReadmeVerificationTests {

    @Test("Basic Authentication example from README line 48-58")
    func basicAuthenticationExample() throws {
        // From README Quick Start
        let auth = try BasicAuth(username: "api", password: "secret-key")

        let router = BasicAuth.Router()
        let requestData = try router.print(auth)

        let authHeaderOptional = try #require(requestData.headers["Authorization"]?.first)
        let authHeader = try #require(authHeaderOptional)
        #expect(authHeader.starts(with: "Basic "))
    }

    @Test("Bearer Token Authentication example from README line 62-72")
    func bearerTokenExample() throws {
        // From README Quick Start
        let auth = try BearerAuth(token: "your-api-token")

        let router = BearerAuth.Router()
        let requestData = try router.print(auth)

        #expect(requestData.headers["Authorization"]?.first == "Bearer your-api-token")
    }

    @Test("Email-based Basic Authentication from README line 76-83")
    func emailBasedAuthExample() throws {
        // From README Usage Examples
        let email = try EmailAddress("user@example.com")
        let auth = try BasicAuth(emailAddress: email, password: "password123")

        #expect(auth.username == "user@example.com")
    }

    @Test("BasicAuth creation with username and password")
    func basicAuthCreation() throws {
        let auth = try BasicAuth(username: "testuser", password: "testpass")
        #expect(auth.username == "testuser")
    }

    @Test("BearerAuth creation with token")
    func bearerAuthCreation() throws {
        let auth = try BearerAuth(token: "test-token-123")
        #expect(auth.token == "test-token-123")
    }

    @Test("BasicAuth.Router creates proper Authorization header")
    func basicAuthRouterHeader() throws {
        let auth = try BasicAuth(username: "user", password: "pass")
        let router = BasicAuth.Router()

        let printed = try router.print(auth)
        let authHeaderOptional = try #require(printed.headers["Authorization"]?.first)
        let authHeader = try #require(authHeaderOptional)

        #expect(authHeader.starts(with: "Basic "))
    }

    @Test("BearerAuth.Router creates proper Authorization header")
    func bearerAuthRouterHeader() throws {
        let auth = try BearerAuth(token: "abc123")
        let router = BearerAuth.Router()

        let printed = try router.print(auth)
        let authHeader = printed.headers["Authorization"]?.first

        #expect(authHeader == "Bearer abc123")
    }

    @Test("BasicAuth can parse Authorization header")
    func basicAuthParserCanParse() throws {
        let auth = try BasicAuth(username: "api", password: "secret")
        let router = BasicAuth.Router()

        let printed = try router.print(auth)
        let parsed = try router.parse(printed)

        #expect(parsed.username == "api")
    }

    @Test("BearerAuth can parse Authorization header")
    func bearerAuthParserCanParse() throws {
        let auth = try BearerAuth(token: "test-token")
        let router = BearerAuth.Router()

        let printed = try router.print(auth)
        let parsed = try router.parse(printed)

        #expect(parsed.token == "test-token")
    }
}
