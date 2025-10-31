# swift-authenticating

[![CI](https://github.com/coenttb/swift-authenticating/workflows/CI/badge.svg)](https://github.com/coenttb/swift-authenticating/actions/workflows/ci.yml)
![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Type-safe HTTP authentication with URL routing integration for Swift.

## Overview

`swift-authenticating` provides type-safe HTTP authentication types and URL routers, supporting both Basic (RFC 7617) and Bearer (RFC 6750) authentication schemes. Built on Point-Free's [swift-url-routing](https://github.com/pointfreeco/swift-url-routing) and [swift-dependencies](https://github.com/pointfreeco/swift-dependencies), it enables composable and testable API authentication patterns.

## Features

- Type-safe authentication with compile-time guarantees via Swift's type system
- URL routing integration via swift-url-routing ParserPrinter protocol
- RFC 7617 Basic Authentication support with base64 credential encoding
- RFC 6750 Bearer Token Authentication support
- Email address support for Basic Authentication via EmailAddress type
- Generic Authenticating struct for custom authentication schemes
- Full swift-dependencies integration for testability
- Swift 6.0 concurrency support with Sendable conformance

## Installation

Add `swift-authenticating` to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/coenttb/swift-authenticating", from: "0.0.1")
]
```

Then add the product to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "Authenticating", package: "swift-authenticating")
    ]
)
```

## Quick Start

### Basic Authentication

```swift
import Authenticating

// Create basic auth credentials
let auth = try BasicAuth(username: "api", password: "secret-key")

// Use with URL routing to generate Authorization header
let router = BasicAuth.Router()
let requestData = try router.print(auth)
// requestData.headers["Authorization"] contains "Basic <base64>"
```

### Bearer Token Authentication

```swift
import Authenticating

// Create bearer token
let auth = try BearerAuth(token: "your-api-token")

// Use with URL routing to generate Authorization header
let router = BearerAuth.Router()
let requestData = try router.print(auth)
// requestData.headers["Authorization"] contains "Bearer your-api-token"
```

## Usage Examples

### Email-based Basic Authentication

```swift
import Authenticating

let email = try EmailAddress("user@example.com")
let auth = try BasicAuth(emailAddress: email, password: "password123")
```

### Creating an Authenticated Client

```swift
import Authenticating
import Dependencies
import URLRouting

// Define your API routes
enum MyAPI: Equatable {
    case getUser(id: String)
    case updateProfile(name: String)
}

// Create router for your API
struct MyAPIRouter: ParserPrinter {
    var body: some URLRouting.Router<MyAPI> {
        OneOf {
            Route(.case(MyAPI.getUser)) {
                Path { "users"; Parse(.string) }
            }
            Route(.case(MyAPI.updateProfile)) {
                Method.post
                Path { "profile" }
                Body(.form(name: .string))
            }
        }
    }
}

// Create authenticated client
let authenticating = try Authenticating(
    baseURL: URL(string: "https://api.example.com")!,
    username: "api",
    password: "secret-key",
    buildClient: { requestBuilder in
        // Return your client implementation
        // requestBuilder closure converts MyAPI -> URLRequest
        return myClientImplementation
    }
)

// Access client and router
let client = authenticating.client
let router = authenticating.router
```

### API Key Authentication (Mailgun-style)

```swift
import Authenticating

// Many APIs use "api" as username with API key as password
let authenticating = try Authenticating(
    baseURL: URL(string: "https://api.mailgun.net")!,
    apiKey: "key-1234567890abcdef",
    buildClient: { requestBuilder in
        // Build your client
        return mailgunClient
    }
)
```

## Module Reference

### Authenticating

Core module providing generic authentication types:

- `Authenticating<Auth, AuthRouter, API, APIRouter, ClientOutput>` - Generic authentication container with client and router
- `BasicAuth` - Type alias for RFC_7617.Basic
- `BearerAuth` - Type alias for RFC_6750.Bearer

### AuthenticatingURLRouting

URL routing implementations for authentication schemes:

- `BasicAuth.Router` - ParserPrinter for RFC 7617 Basic Authentication
- `BasicAuth.ParserPrinter` - Credential encoding/decoding for Basic auth
- `BearerAuth.Router` - ParserPrinter for RFC 6750 Bearer Token authentication
- `BearerAuth.ParserPrinter` - Token encoding/decoding for Bearer auth

### AuthenticatingEmailAddress

Email address support for authentication:

- `BasicAuth.init(emailAddress:password:)` - Convenience initializer using EmailAddress as username

## Requirements

- Swift 6.0+
- macOS 14.0+ / iOS 17.0+

## Related Packages

### Dependencies

- [swift-emailaddress-type](https://github.com/coenttb/swift-emailaddress-type): A Swift package with a type-safe EmailAddress model.

### Used By

- [swift-github-live](https://github.com/coenttb/swift-github-live): A Swift package with live implementations for the GitHub API.
- [swift-identities-types](https://github.com/coenttb/swift-identities-types): A Swift package with foundational types for authentication.
- [swift-mailgun-live](https://github.com/coenttb/swift-mailgun-live): A Swift package with live implementations for Mailgun.
- [swift-stripe](https://github.com/coenttb/swift-stripe): The Swift library for the Stripe API.
- [swift-stripe-live](https://github.com/coenttb/swift-stripe-live): A Swift package with live implementations for the Stripe API.

### Third-Party Dependencies

- [pointfreeco/swift-dependencies](https://github.com/pointfreeco/swift-dependencies): A dependency management library for controlling dependencies in Swift.
- [pointfreeco/swift-url-routing](https://github.com/pointfreeco/swift-url-routing): A bidirectional URL router with more type safety and less fuss.

## License

This project is licensed under the Apache 2.0 License. See [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome. Please open an issue or pull request.
