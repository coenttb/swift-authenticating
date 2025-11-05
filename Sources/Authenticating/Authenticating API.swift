//
//  Authenticating API.swift
//  swift-authenticating
//
//  Created by Coen ten Thije Boonkkamp on 05/01/2025.
//

import Dependencies
import Foundation
import URLRouting

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

extension Authenticating {
    /// Combines authentication credentials with API route definitions.
    ///
    /// ``API`` is a container that pairs authentication information with your API routes,
    /// enabling type-safe authenticated requests.
    ///
    /// ## Overview
    ///
    /// Use `API` to create authenticated API requests by combining your authentication
    /// credentials with your API route definitions. This ensures that every request
    /// includes the necessary authentication information.
    ///
    /// ## Example
    ///
    /// ```swift
    /// import Authenticating
    ///
    /// // Define your API routes
    /// enum MyAPI: Equatable {
    ///     case getUser(id: String)
    ///     case updateProfile(Profile)
    /// }
    ///
    /// // Create authenticated API
    /// let auth = try BasicAuth(username: "api", password: "secret-key")
    /// let authenticatedAPI = Authenticating<BasicAuth>.API(
    ///     auth: auth,
    ///     api: MyAPI.getUser(id: "123")
    /// )
    /// ```
    public struct API: Equatable & Sendable {
        /// The authentication credentials.
        public let auth: Auth

        /// The API route or request.
        public let api: API

        /// Creates a new authenticated API instance.
        ///
        /// - Parameters:
        ///   - auth: The authentication credentials to use.
        ///   - api: The API route or request to authenticate.
        public init(auth: Auth, api: API) {
            self.auth = auth
            self.api = api
        }
    }
}

extension Authenticating.API where Auth == BearerAuth {
    /// Creates a new authenticated API instance using a Bearer token.
    ///
    /// This convenience initializer is available when using Bearer authentication.
    ///
    /// - Parameters:
    ///   - apiKey: The API key to use as the Bearer token.
    ///   - api: The API route or request to authenticate.
    /// - Throws: An error if the API key is invalid.
    public init(apiKey: String, api: API) throws {
        self.auth = try .init(token: apiKey)
        self.api = api
    }
}

extension Authenticating {
    /// A router that combines authentication routing with API routing.
    ///
    /// ``Router`` handles the parsing and printing of authenticated API requests,
    /// combining authentication headers with your API routes.
    ///
    /// ## Overview
    ///
    /// The router uses `swift-url-routing` to parse incoming requests and print
    /// outgoing requests, ensuring that authentication information is properly
    /// included in all API calls.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let router = Authenticating<BasicAuth>.API.Router(
    ///     baseURL: URL(string: "https://api.example.com")!,
    ///     authRouter: BasicAuth.Router(),
    ///     router: MyAPI.Router()
    /// )
    ///
    /// // Create a request
    /// let api = Authenticating<BasicAuth>.API(
    ///     auth: auth,
    ///     api: MyAPI.getUser(id: "123")
    /// )
    /// let request = try router.request(for: api)
    /// ```
    public struct Router: ParserPrinter, Sendable {

        /// The base URL for all API requests.
        let baseURL: URL

        /// The router responsible for handling authentication.
        let authRouter: AuthRouter

        /// The router responsible for handling API routes.
        let router: APIRouter

        /// Creates a new authenticated API router.
        ///
        /// - Parameters:
        ///   - baseURL: The base URL for API requests.
        ///   - authRouter: The router for handling authentication.
        ///   - router: The router for handling API routes.
        public init(
            baseURL: URL,
            authRouter: AuthRouter,
            router: APIRouter
        ) {
            self.baseURL = baseURL
            self.authRouter = authRouter
            self.router = router
        }

        /// The router body that combines authentication and API routing.
        public var body: some URLRouting.Router<Authenticating.API> {
            Parse(.memberwise(Authenticating.API.init)) {
                authRouter

                router
            }
            .baseURL(self.baseURL.absoluteString)
        }
    }
}
