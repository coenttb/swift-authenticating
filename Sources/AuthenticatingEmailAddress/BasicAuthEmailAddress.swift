//
//  BasicAuthEmailAddress.swift
//  swift-authenticating
//
//  Created by Coen ten Thije Boonkkamp on 20/12/2024.
//

import EmailAddress
import RFC_7617

extension RFC_7617.Basic {
    /// Creates Basic Authentication credentials using an email address as the username.\n    ///
    /// This convenience initializer allows you to use a type-safe `EmailAddress`
    /// as the username for Basic Authentication, which is common in many APIs.
    ///
    /// ## Example
    ///
    /// ```swift
    /// import AuthenticatingEmailAddress
    /// import EmailAddress
    ///
    /// // Create credentials with email
    /// let email = try EmailAddress("user@example.com")
    /// let auth = try BasicAuth(
    ///     emailAddress: email,
    ///     password: "password123"
    /// )
    ///
    /// // This is equivalent to:
    /// let auth = try BasicAuth(
    ///     username: "user@example.com",
    ///     password: "password123"
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - emailAddress: The email address to use as the username.
    ///   - password: The password for authentication.
    /// - Throws: An error if the credentials cannot be created.
    public init(
        emailAddress: EmailAddress,
        password: String
    ) throws {
        self = try .init(
            username: emailAddress.description,
            password: password
        )
    }
}
