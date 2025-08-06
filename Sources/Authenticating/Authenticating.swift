//
//  File.swift
//  coenttb-authentication
//
//  Created by Coen ten Thije Boonkkamp on 05/08/2025.
//

/// A generic namespace for authentication-related types and functionality.
///
/// ``Authenticating`` serves as a container for authentication types, providing a type-safe
/// approach to handling different authentication schemes in your API clients.
///
/// ## Overview
///
/// The `Authenticating` enum is generic over an authentication type, allowing you to create
/// strongly-typed authentication handlers for different schemes like Basic Auth or Bearer tokens.
///
/// ## Topics
///
/// ### Authentication Types
/// - ``API``
/// - ``Client``
///
/// ### Type Aliases
/// - ``BearerAuth``
/// - ``BasicAuth``
///
/// ## Example Usage
///
/// ```swift
/// import Authenticating
///
/// // Using Basic Authentication
/// let basicAuth = try BasicAuth(username: "api", password: "secret-key")
///
/// // Using Bearer Authentication
/// let bearerAuth = BearerAuth(token: "your-api-token")
/// ```
public enum Authenticating<Auth:Equatable & Sendable> {}
