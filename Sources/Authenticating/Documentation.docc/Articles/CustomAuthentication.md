# Custom Authentication

Extend the package with your own authentication schemes.

## Overview

While the package provides Basic and Bearer authentication out of the box, you can easily add support for custom authentication schemes by following the same patterns.

## Creating a Custom Authentication Type

First, define your authentication type:

```swift
import Foundation

struct APIKeyAuth: Equatable, Sendable {
    let apiKey: String
    let apiSecret: String
    
    init(apiKey: String, apiSecret: String) throws {
        // Add validation if needed
        guard !apiKey.isEmpty, !apiSecret.isEmpty else {
            throw ValidationError.emptyCredentials
        }
        
        self.apiKey = apiKey
        self.apiSecret = apiSecret
    }
}
```

## Implementing the Router

Create a router that handles your authentication scheme:

```swift
import URLRouting

extension APIKeyAuth {
    struct Router: ParserPrinter, Sendable {
        init() {}
        
        var body: some URLRouting.Router<APIKeyAuth> {
            Headers {
                Field("X-API-Key") {
                    Parse(.string).map(.memberwise(APIKeyAuth.init))
                }
                Field("X-API-Secret") {
                    Parse(.string)
                }
            }
        }
    }
}
```

## Using with Authenticating Types

Now you can use your custom authentication with the Authenticating types:

```swift
// Define authenticated API type
typealias APIKeyAuthenticatedAPI = Authenticating<APIKeyAuth>.API<MyAPI>

// Create authenticated client type
typealias APIKeyAuthClient = Authenticating<APIKeyAuth>.Client<
    APIKeyAuth.Router,
    MyAPI,
    MyAPI.Router,
    MyClient
>

// Use it
let auth = try APIKeyAuth(apiKey: "key", apiSecret: "secret")
let client = APIKeyAuthClient(
    baseURL: URL(string: "https://api.example.com")!,
    auth: auth,
    router: MyAPI.Router(),
    authRouter: APIKeyAuth.Router(),
    buildClient: { makeRequest in
        // Client implementation
    }
)
```

## Advanced: HMAC Authentication

Here's a more complex example with HMAC signature authentication:

```swift
import CryptoKit
import Foundation

struct HMACAuth: Equatable, Sendable {
    let accessKey: String
    let secretKey: String
    let timestamp: Date
    
    func signature(for request: URLRequest) -> String {
        // Calculate HMAC-SHA256 signature
        let message = "\(request.httpMethod ?? "GET")\n\(request.url?.path ?? "")\n\(Int(timestamp.timeIntervalSince1970))"
        
        let key = SymmetricKey(data: secretKey.data(using: .utf8)!)
        let signature = HMAC<SHA256>.authenticationCode(
            for: message.data(using: .utf8)!,
            using: key
        )
        
        return Data(signature).base64EncodedString()
    }
}

extension HMACAuth {
    struct Router: ParserPrinter, Sendable {
        var body: some URLRouting.Router<HMACAuth> {
            Headers {
                Field("X-Access-Key") { Parse(.string) }
                Field("X-Timestamp") { Parse(.double) }
                Field("X-Signature") { Parse(.string) }
            }
            .map(.convert(
                apply: { accessKey, timestamp, _ in
                    // Parse logic
                },
                unapply: { auth in
                    // Print logic with signature calculation
                }
            ))
        }
    }
}
```

## Best Practices

1. **Validation**: Add validation in your authentication type's initializer
2. **Sendable**: Ensure your types conform to `Sendable` for concurrency
3. **Equatable**: Conform to `Equatable` for testing and comparison
4. **Error Handling**: Define clear error types for authentication failures
5. **Documentation**: Document your authentication scheme's requirements