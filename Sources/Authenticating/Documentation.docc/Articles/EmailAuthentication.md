# Email Authentication

Use email addresses with Basic Authentication.

## Overview

The AuthenticatingEmailAddress module extends Basic Authentication to work with type-safe email addresses. This is particularly useful for APIs that use email addresses as usernames.

## Using Email Addresses

Instead of passing a string username, you can use a validated `EmailAddress`:

```swift
import AuthenticatingEmailAddress
import EmailAddress

// Create a validated email address
let email = try EmailAddress("user@example.com")

// Use it for Basic Authentication
let auth = try BasicAuth(
    emailAddress: email,
    password: "password123"
)
```

This is equivalent to:

```swift
let auth = try BasicAuth(
    username: "user@example.com",
    password: "password123"
)
```

## Benefits

Using `EmailAddress` provides several advantages:

1. **Type Safety**: Email addresses are validated at compile time
2. **Validation**: Invalid email formats are caught early
3. **Clarity**: Makes it explicit that the username is an email address

## Real-World Example

Many APIs use email-based authentication. Here's how you might set up a client:

```swift
import Authenticating
import AuthenticatingEmailAddress
import EmailAddress

struct UserAPIClient {
    let email: EmailAddress
    let password: String
    
    func makeAuthenticatedRequest() throws -> URLRequest {
        // Create authentication with email
        let auth = try BasicAuth(
            emailAddress: email,
            password: password
        )
        
        // Use with router
        let router = BasicAuth.Router()
        return try router.request(
            for: auth,
            baseURL: URL(string: "https://api.example.com")!
        )
    }
}

// Usage
let client = UserAPIClient(
    email: try EmailAddress("admin@company.com"),
    password: "secure-password"
)
```

## Integration with Clients

When building authenticated clients, you can accept email addresses directly:

```swift
extension AuthenticatedClient {
    init(
        emailAddress: EmailAddress,
        password: String,
        router: APIRouter,
        buildClient: @escaping (API) throws -> URLRequest) -> ClientOutput
    ) throws where Auth == BasicAuth {
        self = try .init(
            baseURL: baseURL,
            auth: .init(emailAddress: emailAddress, password: password),
            router: router,
            authRouter: BasicAuth.Router(),
            buildClient: buildClient
        )
    }
}
```
