# swift-authentication

<p align="center">
  <img src="https://img.shields.io/badge/Swift-5.10-orange.svg" alt="Swift 5.10">
  <img src="https://img.shields.io/badge/Platforms-macOS%20|%20iOS%20|%20tvOS%20|%20watchOS%20|%20Linux-lightgray.svg" alt="Platforms">
  <img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg" alt="License">
  <img src="https://img.shields.io/badge/Release-0.0.1-green.svg" alt="Release">
</p>

A Swift package providing type-safe HTTP authentication with URL routing integration. Built on [swift-url-routing](https://github.com/pointfreeco/swift-url-routing) and [swift-dependencies](https://github.com/pointfreeco/swift-dependencies), this package offers a composable and testable approach to API authentication.

## Overview

`swift-authentication` provides foundation authentication types and their associated URL routers, supporting both Basic and Bearer authentication schemes. It's designed to seamlessly integrate with your API clients while maintaining type safety and testability.

### Key Features

- 🔐 **Type-safe authentication** - Leverage Swift's type system for compile-time safety
- 🔄 **URL routing integration** - Built on swift-url-routing for seamless request/response handling
- 🧩 **Composable architecture** - Mix and match authentication with your API definitions
- 🧪 **Testable** - Full support for swift-dependencies testing patterns

## Installation

Add `swift-authentication` to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/coenttb/swift-authentication", from: "0.0.1")
]
```

Then add Authenticating to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "Authenticating", package: "swift-authentication")
    ]
)
```

## Quick Start

### Basic Authentication

```swift
import Authenticating

// Create basic auth credentials
let auth = try BasicAuth(username: "api", password: "secret-key")

// Use with URL routing
let router = BasicAuth.Router()
let request = try router.request(for: auth, baseURL: URL(string: "https://api.example.com")!)
```

### Bearer Token Authentication

```swift
import Authenticating

// Create bearer token
let auth = BearerAuth(token: "your-api-token")

// Use with URL routing
let router = BearerAuth.Router()
let request = try router.request(for: auth, baseURL: URL(string: "https://api.example.com")!)
```

## Usage Examples

### Creating an Authenticated API Client

Here's a real-world example showing how to create an authenticated client for a Mailgun API:

```swift
import Authenticating
import Dependencies
import URLRouting

// Define your authenticated client type
public typealias AuthenticatedClient<
    API: Equatable & Sendable,
    APIRouter: ParserPrinter & Sendable,
    Client: Sendable
> = Authenticating<BasicAuth>.Client<
    BasicAuth.Router,
    API,
    APIRouter,
    Client
> where APIRouter.Output == API, APIRouter.Input == URLRequestData

// Create convenience initializer
extension AuthenticatedClient {
    public init(
        apiKey: ApiKey,
        router: APIRouter,
        buildClient: @escaping @Sendable (API) throws -> URLRequest) -> ClientOutput
    ) throws where Auth == BasicAuth, AuthRouter == BasicAuth.Router {
        @Dependency(\.envVars.baseUrl) var baseUrl
        
        self = .init(
            baseURL: baseUrl,
            auth: try .init(username: "api", password: apiKey.rawValue),
            router: router,
            authRouter: BasicAuth.Router(),
            buildClient: buildClient
        )
    }
}
```

### Email-based Authentication

```swift
import AuthenticatingEmailAddress
import EmailAddress

// Use email address for basic auth
let email = try EmailAddress("user@example.com")
let auth = try BasicAuth(emailAddress: email, password: "password123")
```

### Integrating with Your API

```swift
// Define your API routes
enum MyAPI: Equatable {
    case getUser(id: String)
    case updateProfile(Profile)
    case deleteAccount
}

// Create authenticated API type
typealias AuthenticatedAPI = Authenticating<BasicAuth>.API<MyAPI>

// Build your client
let client = try AuthenticatedClient(
    apiKey: apiKey,
    router: myAPIRouter,
    buildClient: { api in
        // Your client implementation
    }
)
```

## Module Overview

### Authenticating

The core module providing:
- `Authenticating<Auth>` - Generic namespace for authentication types
- `Authenticating.API` - Combines authentication with your API types
- `Authenticating.Client` - Dynamic client with automatic authentication

### AuthenticatingURLRouting

URL routing implementations for authentication schemes:
- `BasicAuth.Router` - RFC 7617 Basic Authentication routing
- `BearerAuth.Router` - RFC 6750 Bearer Token routing
- Integration with `swift-url-routing` for request/response handling

### AuthenticatingEmailAddress

Extensions for email-based authentication:
- Email address support for Basic Authentication
- Integration with `swift-emailaddress-type`

## Advanced Usage

### Custom Authentication Schemes

You can extend the package with custom authentication schemes:

```swift
import Authenticating

// Define your custom auth type
struct CustomAuth: Equatable, Sendable {
    let token: String
    let signature: String
}

// Create router implementation
extension CustomAuth {
    struct Router: ParserPrinter {
        // Implementation details...
    }
}

// Use with Authenticating types
typealias CustomAuthClient = Authenticating<CustomAuth>.Client<
    CustomAuth.Router,
    MyAPI,
    MyAPI.Router,
    MyClient
>
```

### Testing

The package is designed with testing in mind using `swift-dependencies`:

```swift
import Dependencies
import Testing

@Suite("My Client Tests")
struct MyClientTests {
    @Test
    func testAuthenticatedRequest() async throws {
        @Dependency(\.client) var client
        let response = await client.get("foo")
    }
}

// uses testValue in tests. Or set DependencyValues \.context to .live for a live client.
```

### Environment Configuration

Use environment variables for configuration:

```swift
// in your code:
extension AuthenticatedClient {
    init(
        buildClient: @escaping @Sendable (API) throws -> URLRequest) -> ClientOutput
    ) throws {
        @Dependency(\.envVars) var envVars
        @Dependency(\.router) var router
        let apiKey = envVars.apiKey
        
        self = try AuthenticatedClient(
            apiKey: apiKey,
            router: router,
            buildClient: buildClient
        )
    }
}
```

## Requirements

- **Swift** 6.0+
- **macOS** 14.0+ / **iOS** 17.0+
- **Dependencies**:

## Related Projects

- [coenttb-mailgun](https://github.com/coenttb/coenttb-mailgun) - Uses swift-authenticating to parse and print the URLRequest in a mailgun-compliant format.

## License

This project is licensed under the **Apache 2.0 License**. See the [LICENSE](LICENSE).

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Status

This package is under active development. Expect frequent changes until version 1.0.0.
