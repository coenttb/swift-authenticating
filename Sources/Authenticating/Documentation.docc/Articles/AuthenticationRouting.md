# Authentication Routing

Learn how to use authentication routers with swift-url-routing.

## Overview

The AuthenticatingURLRouting module provides router implementations for both Basic and Bearer authentication schemes. These routers integrate seamlessly with swift-url-routing to handle authentication headers in a type-safe manner.

## Basic Authentication Router

The Basic Authentication router handles RFC 7617 compliant authentication headers:

```swift
import Authenticating
import AuthenticatingURLRouting

// Create the router
let router = BasicAuth.Router()

// Create authentication
let auth = try BasicAuth(username: "api", password: "secret-key")

// Generate a request
let request = try router.request(
    for: auth,
    baseURL: URL(string: "https://api.example.com")!
)

// The request will have the header:
// Authorization: Basic YXBpOnNlY3JldC1rZXk=
```

## Bearer Token Router

The Bearer token router handles RFC 6750 compliant OAuth 2.0 bearer tokens:

```swift
import Authenticating
import AuthenticatingURLRouting

// Create the router
let router = BearerAuth.Router()

// Create authentication
let auth = BearerAuth(token: "your-api-token")

// Generate a request
let request = try router.request(
    for: auth,
    baseURL: URL(string: "https://api.example.com")!
)

// The request will have the header:
// Authorization: Bearer your-api-token
```

## Combining with API Routers

You can combine authentication routers with your API routers:

```swift
// Define your API
enum MyAPI: Equatable {
    case getUser(id: String)
    case updateProfile(Profile)
}

// Create your API router
struct MyAPIRouter: ParserPrinter {
    // Router implementation...
}

// Combine with authentication
let authenticatedRouter = Authenticating<BasicAuth>.API.Router(
    baseURL: URL(string: "https://api.example.com")!,
    authRouter: BasicAuth.Router(),
    router: MyAPIRouter()
)

// Create an authenticated request
let api = Authenticating<BasicAuth>.API(
    auth: auth,
    api: MyAPI.getUser(id: "123")
)
let request = try authenticatedRouter.request(for: api)
```

## Parser-Printer Architecture

Both routers implement the `ParserPrinter` protocol, allowing them to:

1. **Parse** incoming requests to extract authentication information
2. **Print** outgoing requests with proper authentication headers

This bidirectional capability makes them ideal for both client and server implementations.