# Testing

Learn how to test authenticated clients using swift-dependencies.

## Overview

The Authenticating package is designed with testing in mind, leveraging swift-dependencies for easy mocking and testing of authenticated clients.

## Setting Up Test Dependencies

First, make your API router conform to `TestDependencyKey`:

```swift
import Dependencies

extension MyAPI.Router: TestDependencyKey {
    static let testValue = MyAPI.Router()
    static let liveValue = MyAPI.Router()
}
```

## Writing Tests

Here's how to test an authenticated client:

```swift
import Dependencies
import Testing
@testable import MyApp

@Suite("Authenticated Client Tests")
struct AuthenticatedClientTests {
    @Test
    func testSuccessfulAuthentication() async throws {
        // Create a mock client
        let mockClient = MyClient(
            getUser: { id in
                // Return mock data
                User(id: id, name: "Test User")
            }
        )
        
        // Run test with dependencies
        try await withDependencies {
            $0.apiRouter = .testValue
            $0.myClient = mockClient
        } operation: {
            let client = try AuthenticatedClient(
                apiKey: "test-key",
                router: MyAPI.Router(),
                buildClient: { _ in mockClient }
            )
            
            let user = await client.getUser(id: "123")
            #expect(user.name == "Test User")
        }
    }
}
```

## Testing Authentication Headers

Verify that authentication headers are correctly applied:

```swift
@Test
func testBasicAuthHeader() throws {
    let auth = try BasicAuth(username: "user", password: "pass")
    let router = BasicAuth.Router()
    
    let request = try router.request(
        for: auth,
        baseURL: URL(string: "https://api.example.com")!
    )
    
    let authHeader = request.value(forHTTPHeaderField: "Authorization")
    #expect(authHeader == "Basic dXNlcjpwYXNz") // base64("user:pass")
}

@Test
func testBearerAuthHeader() throws {
    let auth = BearerAuth(token: "test-token")
    let router = BearerAuth.Router()
    
    let request = try router.request(
        for: auth,
        baseURL: URL(string: "https://api.example.com")!
    )
    
    let authHeader = request.value(forHTTPHeaderField: "Authorization")
    #expect(authHeader == "Bearer test-token")
}
```

## Integration Testing

Test the full request/response cycle:

```swift
@Test
func testAPIIntegration() async throws {
    // Mock HTTP handler
    let mockHandler: URLRequest.Handler = { request in
        // Verify authentication
        guard let auth = request.value(forHTTPHeaderField: "Authorization"),
              auth.hasPrefix("Basic ") else {
            throw URLError(.userAuthenticationRequired)
        }
        
        // Return mock response
        return (
            Data("{\"id\": \"123\", \"name\": \"Test\"}".utf8),
            HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
        )
    }
    
    try await withDependencies {
        $0.urlRequestHandler = mockHandler
    } operation: {
        let client = try AuthenticatedClient(
            username: "api",
            password: "secret",
            buildClient: { makeRequest in
                MyClient.live(makeRequest: makeRequest)
            }
        )
        
        let result = await client.getUser(id: "123")
        #expect(result.name == "Test")
    }
}
```

## Testing Error Scenarios

Don't forget to test authentication failures:

```swift
@Test
func testAuthenticationFailure() async throws {
    let mockHandler: URLRequest.Handler = { request in
        // Simulate 401 Unauthorized
        throw URLError(.userAuthenticationRequired)
    }
    
    try await withDependencies {
        $0.urlRequestHandler = mockHandler
    } operation: {
        let client = try AuthenticatedClient(
            username: "wrong",
            password: "credentials",
            buildClient: MyClient.live
        )
        
        await #expect(throws: URLError.self) {
            try await client.getUser(id: "123")
        }
    }
}
```

## Best Practices

1. **Use Test Dependencies**: Register your routers and clients as test dependencies
2. **Mock at the Right Level**: Mock at the HTTP handler level for integration tests
3. **Test Edge Cases**: Include tests for malformed tokens, expired credentials, etc.
4. **Verify Headers**: Always verify that authentication headers are correctly applied
5. **Test Concurrency**: Ensure your authenticated clients work correctly in concurrent contexts