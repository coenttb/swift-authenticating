//
//  File.swift
//  coenttb-authentication
//
//  Created by Coen ten Thije Boonkkamp on 05/08/2025.
//

import Foundation
import URLRouting
import Dependencies

/// A generic struct for authentication-related functionality.
///
/// ``Authenticating`` provides both client and router properties for authenticated API access,
/// enabling clean dependency injection patterns.
///
/// ## Overview
///
/// The `Authenticating` struct is generic over authentication and API types, providing
/// strongly-typed authentication handlers for different schemes like Basic Auth or Bearer tokens.
///
/// ## Example Usage
///
/// ```swift
/// @Dependency(Mailgun.self) var mailgun
/// 
/// // Access the client for making requests
/// let response = try await mailgun.client.send(...)
/// 
/// // Access the router for URL generation
/// let url = mailgun.router.url(for: .getMessage(id: "123"))
/// ```
@dynamicMemberLookup
public struct Authenticating<
    Auth: Equatable & Sendable,
    AuthRouter: ParserPrinter & Sendable,
    API: Equatable & Sendable,
    APIRouter: ParserPrinter & Sendable,
    ClientOutput: Sendable
>: Sendable where
    APIRouter.Input == URLRequestData,
    APIRouter.Output == API,
    AuthRouter.Input == URLRequestData,
    AuthRouter.Output == Auth
{
    /// The authenticated client for making API requests
    public let client: ClientOutput
    
    /// The router for URL generation and request building
    public let router: Router
    
    /// Creates a new authenticating instance with client and router.
    ///
    /// - Parameters:
    ///   - baseURL: The base URL for all API requests
    ///   - auth: The authentication credentials
    ///   - apiRouter: The API router for handling routes
    ///   - authRouter: The authentication router for handling auth headers
    ///   - buildClient: A closure that builds the underlying client
    public init(
        baseURL: URL,
        auth: Auth,
        apiRouter: APIRouter,
        authRouter: AuthRouter,
        buildClient: @escaping @Sendable (@escaping @Sendable (API) throws -> URLRequest) -> ClientOutput
    ) {
        self.client = Client(
            baseURL: baseURL,
            auth: auth,
            router: apiRouter,
            authRouter: authRouter,
            buildClient: buildClient
        ).client
        
        self.router = Router(
            baseURL: baseURL,
            authRouter: authRouter,
            router: apiRouter
        )
    }
    
    public subscript<T>(dynamicMember keyPath: KeyPath<ClientOutput, T>) -> T {
        self.client[keyPath: keyPath]
    }
}

// MARK: - Bearer Authentication Conveniences

extension Authenticating where Auth == BearerAuth, AuthRouter == BearerAuth.Router, APIRouter: TestDependencyKey, APIRouter.Value == APIRouter {
    /// Creates a new authenticating instance with Bearer token authentication.
    ///
    /// - Parameters:
    ///   - baseURL: The base URL for all API requests
    ///   - token: The Bearer token for authentication
    ///   - buildClient: A closure that builds the underlying client
    /// - Throws: An error if the token is invalid
    public init(
        baseURL: URL,
        token: String,
        buildClient: @escaping @Sendable (@escaping @Sendable (API) throws -> URLRequest) -> ClientOutput
    ) throws {
        @Dependency(APIRouter.self) var apiRouter
        
        self.init(
            baseURL: baseURL,
            auth: try BearerAuth(token: token),
            apiRouter: apiRouter,
            authRouter: BearerAuth.Router(),
            buildClient: buildClient
        )
    }
}

// MARK: - Basic Authentication Conveniences

extension Authenticating where Auth == BasicAuth, AuthRouter == BasicAuth.Router, APIRouter: TestDependencyKey, APIRouter.Value == APIRouter {
    /// Creates a new authenticating instance with Basic authentication.
    ///
    /// - Parameters:
    ///   - baseURL: The base URL for all API requests
    ///   - username: The username for Basic authentication
    ///   - password: The password for Basic authentication
    ///   - buildClient: A closure that builds the underlying client
    /// - Throws: An error if the credentials are invalid
    public init(
        baseURL: URL,
        username: String,
        password: String,
        buildClient: @escaping @Sendable (@escaping @Sendable (API) throws -> URLRequest) -> ClientOutput
    ) throws {
        @Dependency(APIRouter.self) var apiRouter
        
        self.init(
            baseURL: baseURL,
            auth: try BasicAuth(username: username, password: password),
            apiRouter: apiRouter,
            authRouter: BasicAuth.Router(),
            buildClient: buildClient
        )
    }
    
    /// Creates a new authenticating instance with API key authentication (Basic auth).
    ///
    /// For Mailgun-style authentication where apiKey is used as the password.
    ///
    /// - Parameters:
    ///   - baseURL: The base URL for all API requests
    ///   - apiKey: The API key to use as the password
    ///   - buildClient: A closure that builds the underlying client
    /// - Throws: An error if the API key is invalid
    public init(
        baseURL: URL,
        apiKey: String,
        buildClient: @escaping @Sendable (@escaping @Sendable (API) throws -> URLRequest) -> ClientOutput
    ) throws {
        try self.init(
            baseURL: baseURL,
            username: "api",
            password: apiKey,
            buildClient: buildClient
        )
    }
}

// MARK: - Backwards Compatibility

public typealias AuthenticatingClient<
    Auth: Equatable & Sendable,
    AuthRouter: ParserPrinter & Sendable,
    API: Equatable & Sendable,
    APIRouter: ParserPrinter & Sendable,
    ClientOutput: Sendable
> = Authenticating<Auth, AuthRouter, API, APIRouter, ClientOutput>.Client
where
    APIRouter.Input == URLRequestData,
    APIRouter.Output == API,
    AuthRouter.Input == URLRequestData,
    AuthRouter.Output == Auth

// For AuthenticatingAPI, users will need to use the full type

public typealias AuthenticatingAPIRouter<
    Auth: Equatable & Sendable,
    AuthRouter: ParserPrinter & Sendable,
    API: Equatable & Sendable,
    APIRouter: ParserPrinter & Sendable
> = Authenticating<Auth, AuthRouter, API, APIRouter, Never>.Router
where
    APIRouter.Input == URLRequestData,
    APIRouter.Output == API,
    AuthRouter.Input == URLRequestData,
    AuthRouter.Output == Auth
