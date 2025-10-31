//
//  ClientErgonomicsExample.swift
//  swift-authenticating
//
//  Created on 07/08/2025.
//

import Dependencies
import DependenciesMacros
import Foundation
import Testing
import URLRouting

@testable import Authenticating

@Suite("Client Ergonomics Example")
struct ClientErgonomicsExample {

  enum API: Equatable, Sendable {
    case getUser(id: String)
    case listMessages(page: Int)
  }

  struct Router: ParserPrinter, Sendable, TestDependencyKey {
    typealias Input = URLRequestData
    typealias Output = API
    static var testValue: Router { Router() }

    func parse(_ input: inout URLRequestData) throws -> ClientErgonomicsExample.API {
      fatalError()
    }

    func print(_ output: ClientErgonomicsExample.API, into input: inout URLRequestData) throws {
      fatalError()
    }
  }

  // Mock client with methods that have proper parameter labels
  @DependencyClient
  struct APIClient: Sendable {
    var getUser: @Sendable (_ id: String) async throws -> String = { _ in "mock-user" }
    var listMessages: @Sendable (_ page: Int) async throws -> [String] = { _ in [] }
  }

  @Test("Demonstrates improved ergonomics with .client property")
  func testImprovedErgonomics() async throws {
    let baseURL = URL(string: "https://api.example.com")!
    let token = "test-token"

    // Create authenticated client
    let authenticatedClient = try AuthenticatingClient<
      BearerAuth,
      BearerAuth.Router,
      API,
      Router,
      APIClient
    >(
      baseURL: baseURL,
      token: token,
      buildClient: { _ in
        APIClient(
          getUser: { _ in "mock-user" },
          listMessages: { _ in [] }
        )
      }
    )

    // Before: Using dynamic member lookup (closure properties without labels)
    // This works but doesn't have parameter labels:
    _ = try await authenticatedClient.getUser("user123")
    _ = try await authenticatedClient.listMessages(1)

    // After: Using .client property (methods with proper parameter labels)
    // This provides better ergonomics with labeled parameters:
    _ = try await authenticatedClient.client.getUser(id: "user123")
    _ = try await authenticatedClient.client.listMessages(page: 1)

    // Just demonstrating the API usage
  }

  @Test("Both approaches work together harmoniously")
  func testBothApproachesWork() async throws {
    let baseURL = URL(string: "https://api.example.com")!
    let token = "test-token"

    let authenticatedClient = try AuthenticatingClient<
      BearerAuth,
      BearerAuth.Router,
      API,
      Router,
      APIClient
    >(
      baseURL: baseURL,
      token: token,
      buildClient: { _ in
        APIClient(
          getUser: { _ in "mock-user" },
          listMessages: { _ in [] }
        )
      }
    )

    // Dynamic member lookup still works for quick access
    let user1 = try await authenticatedClient.getUser("123")

    // .client property provides labeled parameters
    let user2 = try await authenticatedClient.client.getUser(id: "123")

    #expect(user1 == user2)
  }
}
