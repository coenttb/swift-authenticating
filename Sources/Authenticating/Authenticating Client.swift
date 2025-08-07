//
//  File.swift
//  coenttb-mailgun
//
//  Created by Coen ten Thije Boonkkamp on 20/12/2024.
//
import URLRouting
import Foundation
import Dependencies
import URLRouting

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension Authenticating {
    /// A dynamic HTTP client that automatically handles authentication.
    ///
    /// ``Client`` provides a type-safe way to make authenticated API requests using
    /// `@dynamicMemberLookup` for ergonomic access to your API endpoints.
    ///
    /// ## Overview
    ///
    /// The client automatically injects authentication information into every request,
    /// allowing you to focus on your API logic without worrying about authentication details.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // From the Mailgun example
    /// public typealias AuthenticatedClient<
    ///     API: Equatable & Sendable,
    ///     APIRouter: ParserPrinter & Sendable,
    ///     Client: Sendable
    /// > = Authenticating<BasicAuth>.Client<
    ///     BasicAuth.Router,
    ///     API,
    ///     APIRouter,
    ///     Client
    /// > where APIRouter.Output == API, APIRouter.Input == URLRequestData
    ///
    /// // Create the client
    /// let client = try AuthenticatedClient(
    ///     apiKey: apiKey,
    ///     router: router,
    ///     buildClient: { makeRequest in
    ///         // Your client implementation
    ///     }
    /// )
    /// ```
    ///
    /// ## Dynamic Member Lookup
    ///
    /// The client uses `@dynamicMemberLookup` to provide direct access to the underlying
    /// client's methods and properties, making authenticated requests feel natural.
    @dynamicMemberLookup
    public struct Client: Sendable {
        
        private let baseURL: URL
        private let auth: Auth
        
        private let router: APIRouter
        private let buildClient: @Sendable (@escaping @Sendable (API) throws -> URLRequest) -> ClientOutput
        private let authenticatedRouter: Router
        
        /// Creates a new authenticated client.
        ///
        /// - Parameters:
        ///   - baseURL: The base URL for all API requests.
        ///   - auth: The authentication credentials.
        ///   - router: The API router for handling routes.
        ///   - authRouter: The authentication router for handling auth headers.
        ///   - buildClient: A closure that builds the underlying client given a request builder.
        public init(
            baseURL: URL,
            auth: Auth,
            router: APIRouter,
            authRouter: AuthRouter,
            buildClient: @escaping @Sendable (@escaping @Sendable (API) throws -> URLRequest) -> ClientOutput
        ) {
            self.baseURL = baseURL
            self.auth = auth
            self.router = router
            self.buildClient = buildClient
            self.authenticatedRouter = Router(
                baseURL: baseURL,
                authRouter: authRouter,
                router: router
            )
        }
        
        /// Provides dynamic access to the underlying client's properties and methods.
        ///
        /// This allows you to access closure properties directly on the authenticated client:
        ///
        /// ```swift
        /// let response = try await authenticatedClient.send(.getUser(id: "123"))
        /// ```
        public subscript<T>(dynamicMember keyPath: KeyPath<ClientOutput, T>) -> T {
            @Sendable
            func makeRequest(for api: API) throws -> URLRequest {
                let data = try authenticatedRouter.print(Authenticating.API(auth: auth, api: api))
                
                guard let request = URLRequest(data: data) else {
                    throw Error.requestError
                }
                
                return request
            }
            
            return withEscapedDependencies { dependencies in
                buildClient { api in
                    try dependencies.yield {
                        try makeRequest(for: api)
                    }
                }[keyPath: keyPath]
            }
        }
        
        /// Provides access to the underlying client with all authentication automatically applied.
        ///
        /// This computed property returns the client instance with authentication headers
        /// automatically injected into every request. This allows you to call methods
        /// with proper parameter labels:
        ///
        /// ```swift
        /// // With proper method syntax:
        /// let response = try await authenticatedClient.client.send(request)
        /// ```
        public var client: ClientOutput {
            @Sendable
            func makeRequest(for api: API) throws -> URLRequest {
                let data = try authenticatedRouter.print(Authenticating.API(auth: auth, api: api))
                
                guard let request = URLRequest(data: data) else {
                    throw Error.requestError
                }
                
                return request
            }
            
            return withEscapedDependencies { dependencies in
                buildClient { api in
                    try dependencies.yield {
                        try makeRequest(for: api)
                    }
                }
            }
        }
    }
}



/// Errors that can occur during authenticated client operations.
public enum Error: Swift.Error {
    /// An error occurred while printing the request data.
    case printError
    
    /// An error occurred while creating the URLRequest.
    case requestError
}

// MARK: - Bearer Authentication Conveniences

extension AuthenticatingClient where Auth == BearerAuth {
    /// Creates a new client with Bearer token authentication.
    ///
    /// This convenience initializer is available when using Bearer authentication
    /// and when the API router is registered as a test dependency.
    ///
    /// - Parameters:
    ///   - baseURL: The base URL for all API requests.
    ///   - token: The Bearer token for authentication.
    ///   - buildClient: A closure that builds the underlying client.
    /// - Throws: An error if the token is invalid.
    public init(
        baseURL: URL,
        token: String,
        buildClient: @escaping @Sendable (
            _ makeRequest: @escaping @Sendable (_ route: API) throws -> URLRequest
        ) -> ClientOutput
    ) throws where Auth == BearerAuth, AuthRouter == BearerAuth.Router, APIRouter: TestDependencyKey, APIRouter.Value == APIRouter {
        @Dependency(APIRouter.self) var router
        
        self = .init(
            baseURL: baseURL,
            auth: try .init(token: token),
            router: router,
            authRouter: BearerAuth.Router(),
            buildClient: buildClient
        )
    }
}

extension Authenticating.Client where APIRouter: TestDependencyKey, APIRouter.Value == APIRouter {
    /// Creates a new client with Bearer token authentication (simplified).
    ///
    /// This convenience initializer is for clients that don't need access to the request builder.
    ///
    /// - Parameters:
    ///   - baseURL: The base URL for all API requests.
    ///   - token: The Bearer token for authentication.
    ///   - buildClient: A closure that builds the underlying client.
    /// - Throws: An error if the token is invalid.
    public init(
        baseURL: URL,
        token: String,
        buildClient: @escaping @Sendable () -> ClientOutput
    ) throws where Auth == BearerAuth, AuthRouter == BearerAuth.Router {
        @Dependency(APIRouter.self) var router
        self = try .init(
            baseURL: baseURL,
            token: token,
            buildClient: { _ in buildClient() }
        )
    }
}

// MARK: - Basic Authentication Conveniences

extension AuthenticatingClient where Auth == BasicAuth {
    /// Creates a new client with Basic authentication.
    ///
    /// This convenience initializer is available when using Basic authentication
    /// and when the API router is registered as a test dependency.
    ///
    /// - Parameters:
    ///   - baseURL: The base URL for all API requests.
    ///   - username: The username for Basic authentication.
    ///   - password: The password for Basic authentication.
    ///   - buildClient: A closure that builds the underlying client.
    /// - Throws: An error if the credentials are invalid.
    public init(
        baseURL: URL,
        username: String,
        password: String,
        buildClient: @escaping @Sendable (
            _ makeRequest: @escaping @Sendable (_ route: API) throws -> URLRequest
        ) -> ClientOutput
    ) throws where Auth == BasicAuth, AuthRouter == BasicAuth.Router, APIRouter: TestDependencyKey, APIRouter.Value == APIRouter {
        @Dependency(APIRouter.self) var router
        
        self = .init(
            baseURL: baseURL,
            auth: try .init(username: username, password: password),
            router: router,
            authRouter: BasicAuth.Router(),
            buildClient: buildClient
        )
    }
}

extension Authenticating.Client where APIRouter: TestDependencyKey, APIRouter.Value == APIRouter {
    /// Creates a new client with Basic authentication (simplified).
    ///
    /// This convenience initializer is for clients that don't need access to the request builder.
    ///
    /// - Parameters:
    ///   - baseURL: The base URL for all API requests.
    ///   - username: The username for Basic authentication.
    ///   - password: The password for Basic authentication.
    ///   - buildClient: A closure that builds the underlying client.
    /// - Throws: An error if the credentials are invalid.
    public init(
        baseURL: URL,
        username: String,
        password: String,
        buildClient: @escaping @Sendable () -> ClientOutput
    ) throws where Auth == BasicAuth, AuthRouter == BasicAuth.Router {
        @Dependency(APIRouter.self) var router
        self = try .init(
            baseURL: baseURL,
            username: username,
            password: password,
            buildClient: { _ in buildClient() }
        )
    }
}
