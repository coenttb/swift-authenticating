# ``Authenticating``

Type-safe HTTP authentication with URL routing integration for Swift.

## Overview

The Authenticating package provides a composable and testable approach to API authentication, built on [swift-url-routing](https://github.com/pointfreeco/swift-url-routing) and [swift-dependencies](https://github.com/pointfreeco/swift-dependencies). It supports both Basic and Bearer authentication schemes with type-safe handling and seamless integration with your API clients.

## Getting Started

### Basic Authentication

```swift
import Authenticating

// Create Basic auth credentials
let auth = try BasicAuth(username: "api", password: "secret-key")

// Use with URL routing
let router = BasicAuth.Router()
let request = try router.request(for: auth, baseURL: URL(string: "https://api.example.com")!)
```

### Bearer Token Authentication

```swift
import Authenticating

// Create Bearer token
let auth = BearerAuth(token: "your-api-token")

// Use with URL routing  
let router = BearerAuth.Router()
let request = try router.request(for: auth, baseURL: URL(string: "https://api.example.com")!)
```

## Creating an Authenticated Client

Here's a real-world example from the Mailgun integration:

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
        buildClient: @escaping @Sendable (API) throws -> URLRequest) -> ClientOutput
    ) throws where Auth == BasicAuth, AuthRouter == BasicAuth.Router {
        @Dependency(\.envVars.baseUrl) var baseUrl
        @Dependency(\.envVars.apiKey) var apiKey
        @Dependency(\.router) var router
        
        self = .init(
            baseURL: baseUrl,
            auth: try .init(username: "api", password: apiKey.rawValue),
            router: router,
            authRouter: BasicAuth.Router(),
            buildClient: buildClient
        )
    }
}

// Recommended convenience typealias
extension Client {
    public typealias Authenticated = AuthenticatedClient<API, API.Router, Client>
}

// conform your Client to DependencyKey, but set the type to Client.Authenticated (not Client)
extension Client: DependencyKey {
    public static var liveValue: Client.Authenticated { 
        Client.Authenticated { Client.init(...) }
    }
}

// conform your Router to DependencyKey, required for this pattern.
extension Router: @retroactive DependencyKey {
    public static let liveValue: Router = .init()
}

```

## Topics

### Essentials

- ``Authenticating``
- ``Authenticating/API``
- ``Authenticating/Client``

### Authentication Types

- ``BasicAuth``
- ``BearerAuth``

### URL Routing

- <doc:AuthenticationRouting>

### Email Authentication

- <doc:EmailAuthentication>

### Advanced Usage

- <doc:CustomAuthentication>
- <doc:Testing>
