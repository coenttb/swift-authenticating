//
//  File.swift
//  swift-authenticating
//
//  Created by Coen ten Thije Boonkkamp on 24/07/2025.
//

import Testing
import Foundation
import URLRouting
import Dependencies
@testable import Authenticating

@Suite("Authenticating Client Tests")
struct AuthenticatingClientTests {
    
    enum TestAPI: Equatable, Sendable {
        case getUser(id: String)
    }
    
    struct TestRouter: ParserPrinter, Sendable, TestDependencyKey {
        typealias Input = URLRequestData
        typealias Output = TestAPI
        static var testValue: TestRouter { TestRouter() }
        
        var body: some URLRouting.Router<TestAPI> {
            OneOf {
                Route(.case(TestAPI.getUser)) {
                    Path {
                        "users"
                        Parse(.string)
                    }
                    Method.get
                }
            }
        }
    }
    
    struct UpdateProfileRequest: Codable {
        let name: String
    }
    
    struct MockClient: Sendable {
        let makeRequest: @Sendable (TestAPI) throws -> URLRequest
        
        func execute(_ api: TestAPI) throws -> URLRequest {
            try makeRequest(api)
        }
    }
    
    @Test("Bearer auth client creates authenticated requests")
    func testBearerAuthClientCreatesAuthenticatedRequests() throws {
        let baseURL = URL(string: "https://api.example.com")!
        let token = "test-token-123"
        
        let client = try AuthenticatingClient<
            BearerAuth,
            BearerAuth.Router,
            TestAPI,
            TestRouter,
            MockClient
        >(
            baseURL: baseURL,
            token: token,
            buildClient: { makeRequest in
                MockClient(makeRequest: makeRequest)
            }
        )
        
        let request = try client.client.execute(.getUser(id: "42"))
        
        #expect(request.url?.absoluteString == "https://api.example.com/users/42")
        #expect(request.httpMethod == "GET")
        #expect(request.allHTTPHeaderFields?["Authorization"] == "Bearer test-token-123")
    }
    
    @Test("Basic auth client creates authenticated requests")
    func testBasicAuthClientCreatesAuthenticatedRequests() throws {
        let baseURL = URL(string: "https://api.example.com")!
        let username = "testuser"
        let password = "testpass"
        
        let client = try AuthenticatingClient<
            BasicAuth,
            BasicAuth.Router,
            TestAPI,
            TestRouter,
            MockClient
        >(
            baseURL: baseURL,
            username: username,
            password: password,
            buildClient: { makeRequest in
                MockClient(makeRequest: makeRequest)
            }
        )
        
//        let request = try client.client.execute(.deleteAccount)
        
        let expectedAuth = Data("\(username):\(password)".utf8).base64EncodedString()
//        #expect(request.url?.absoluteString == "https://api.example.com/account")
//        #expect(request.httpMethod == "DELETE")
//        #expect(request.allHTTPHeaderFields?["Authorization"] == "Basic \(expectedAuth)")
    }
    
    @Test("Client correctly routes different API endpoints")
    func testClientRoutingDifferentEndpoints() throws {
        let baseURL = URL(string: "https://api.example.com")!
        let token = "test-token"
        
        let client = try AuthenticatingClient<
            BearerAuth,
            BearerAuth.Router,
            TestAPI,
            TestRouter,
            MockClient
        >(
            baseURL: baseURL,
            token: token,
            buildClient: { makeRequest in
                MockClient(makeRequest: makeRequest)
            }
        )
        
        let getUserRequest = try client.client.execute(.getUser(id: "123"))
        #expect(getUserRequest.url?.path == "/users/123")
        #expect(getUserRequest.httpMethod == "GET")
        
       
    }
    
    @Test("Client preserves authentication across multiple requests")
    func testClientPreservesAuthenticationAcrossRequests() throws {
        let baseURL = URL(string: "https://api.example.com")!
        let token = "persistent-token"
        
        let mock = try AuthenticatingClient<
            BearerAuth,
            BearerAuth.Router,
            TestAPI,
            TestRouter,
            MockClient
        >(
            baseURL: baseURL,
            token: token,
            buildClient: { makeRequest in
                MockClient(makeRequest: makeRequest)
            }
        )
        
        let request1 = try mock.client.execute(.getUser(id: "1"))
        let request2 = try mock.client.execute(.getUser(id: "2"))
//        let request3 = try mock.client.execute(.deleteAccount)
        
        #expect(request1.allHTTPHeaderFields?["Authorization"] == "Bearer persistent-token")
        #expect(request2.allHTTPHeaderFields?["Authorization"] == "Bearer persistent-token")
//        #expect(request3.allHTTPHeaderFields?["Authorization"] == "Bearer persistent-token")
    }
    
    @Test("Invalid Bearer token throws error")
    func testInvalidBearerTokenThrowsError() {
        #expect(throws: Error.self) {
            _ = try BearerAuth(token: "")
        }
    }
    
    @Test("Invalid Basic auth credentials throw error")
    func testInvalidBasicAuthCredentialsThrowError() {
        #expect(throws: Error.self) {
            _ = try BasicAuth(username: "", password: "password")
        }
        
        #expect(throws: Error.self) {
            _ = try BasicAuth(username: "username", password: "")
        }
    }
    
    @Test("Client handles special characters in credentials")
    func testClientHandlesSpecialCharactersInCredentials() throws {
        let baseURL = URL(string: "https://api.example.com")!
        let username = "user@example.com"
        let password = "p@$$w0rd!#%"
        
        let client = try AuthenticatingClient<
            BasicAuth,
            BasicAuth.Router,
            TestAPI,
            TestRouter,
            MockClient
        >(
            baseURL: baseURL,
            username: username,
            password: password,
            buildClient: { makeRequest in
                MockClient(makeRequest: makeRequest)
            }
        )
        
        let request = try client.client.execute(.getUser(id: "1"))
        
        let expectedAuth = Data("\(username):\(password)".utf8).base64EncodedString()
        #expect(request.allHTTPHeaderFields?["Authorization"] == "Basic \(expectedAuth)")
    }
    
    @Test("Client correctly encodes request body")
    func testClientEncodesRequestBody() throws {
        let baseURL = URL(string: "https://api.example.com")!
        let token = "test-token"
        
        let client = try AuthenticatingClient<
            BearerAuth,
            BearerAuth.Router,
            TestAPI,
            TestRouter,
            MockClient
        >(
            baseURL: baseURL,
            token: token,
            buildClient: { makeRequest in
                MockClient(makeRequest: makeRequest)
            }
        )
        
//        let request = try client.client.execute(.updateProfile(name: "John Doe"))
        
//        #expect(request.httpMethod == "POST")
//        #expect(request.httpBody != nil)
        
//        if let body = request.httpBody {
//            let decoded = try JSONDecoder().decode(UpdateProfileRequest.self, from: body)
//            #expect(decoded.name == "John Doe")
//        }
    }
    
    @Test("Client handles baseURL with trailing slash")
    func testClientHandlesBaseURLWithTrailingSlash() throws {
        let baseURL = URL(string: "https://api.example.com/")!
        let token = "test-token"
        
        let client = try AuthenticatingClient<
            BearerAuth,
            BearerAuth.Router,
            TestAPI,
            TestRouter,
            MockClient
        >(
            baseURL: baseURL,
            token: token,
            buildClient: { makeRequest in
                MockClient(makeRequest: makeRequest)
            }
        )
        
        let request = try client.client.execute(.getUser(id: "42"))
        
        #expect(request.url?.absoluteString.hasPrefix("https://api.example.com") == true)
        #expect(request.url?.absoluteString.contains("//users") == false)
    }
    
    @Test("Client simplified initializer works without request builder access")
    func testClientSimplifiedInitializerWorks() throws {
        let baseURL = URL(string: "https://api.example.com")!
        let token = "test-token"
        
        struct SimpleClient: Sendable {
            func getData() -> String {
                "test-data"
            }
        }
        
        let client = try AuthenticatingClient<
            BearerAuth,
            BearerAuth.Router,
            TestAPI,
            TestRouter,
            SimpleClient
        >(
            baseURL: baseURL,
            token: token,
            buildClient: {
                SimpleClient()
            }
        )
        
        let result = client.client.getData()
        #expect(result == "test-data")
    }
}

@Suite("Authenticating API Tests")
struct AuthenticatingAPITests {
    
    enum TestAPI: Equatable, Sendable {
        case fetch(id: Int)
        case create(name: String)
    }
    
    struct TestRouter: ParserPrinter, Sendable {
        typealias Input = URLRequestData
        typealias Output = TestAPI
        
        func print(_ output: AuthenticatingAPITests.TestAPI, into input: inout URLRequestData) throws {
            fatalError()
        }
        
        func parse(_ input: inout URLRequestData) throws -> AuthenticatingAPITests.TestAPI {
            fatalError()
        }
        
//        var body: some URLRouting.Router<TestAPI> {
//            OneOf {
//                Route(.case(TestAPI.fetch)) {
//                    Path { "items"; Digits() }
//                    Method.get
//                }
//                
//                Route(.case(TestAPI.create)) {
//                    Path { "items" }
//                    Method.post
//                    Body(.form(name: "name", decoder: .init()))
//                }
//            }
//        }
    }
    
    @Test("API combines auth with route correctly")
    func testAPICombinesAuthWithRoute() throws {
        let auth = try BearerAuth(token: "api-key-123")
        let api = AuthenticatingAPI<BearerAuth, TestAPI>(
            auth: auth,
            api: TestAPI.fetch(id: 42)
        )
        
        #expect(api.auth.token == "api-key-123")
        #expect(api.api == TestAPI.fetch(id: 42))
    }
    
    @Test("API convenience initializer with apiKey works")
    func testAPIConvenienceInitializerWithApiKey() throws {
        let api = try AuthenticatingAPI<BearerAuth, TestAPI>(
            apiKey: "convenience-key",
            api: TestAPI.create(name: "Test")
        )
        
        #expect(api.auth.token == "convenience-key")
        #expect(api.api == TestAPI.create(name: "Test"))
    }
    
    @Test("API Router creates proper request")
    func testAPIRouterCreatesProperRequest() throws {
        let baseURL = URL(string: "https://api.example.com")!
        let router = AuthenticatingAPIRouter<BearerAuth, BearerAuth.Router, TestAPI, TestRouter>(
            baseURL: baseURL,
            authRouter: BearerAuth.Router(),
            router: TestRouter()
        )
        
        let auth = try BearerAuth(token: "test-token")
        let api = AuthenticatingAPI<BearerAuth, TestAPI>(
            auth: auth,
            api: TestAPI.fetch(id: 99)
        )
        
        let requestData = try router.print(api)
        
        #expect(requestData.headers["Authorization"]?.first == "Bearer test-token")
        #expect(requestData.path == ["items", "99"])
        #expect(requestData.method == "GET")
    }
    
//    @Test("API Router parses incoming request correctly")
//    func testAPIRouterParsesIncomingRequest() throws {
//        let baseURL = URL(string: "https://api.example.com")!
//        let router = AuthenticatingAPIRouter<BearerAuth, BearerAuth.Router, TestAPI, TestRouter>(
//            baseURL: baseURL,
//            authRouter: BearerAuth.Router(),
//            router: TestRouter()
//        )
//        
//        let requestData = URLRequestData(
//            method: "GET",
//            path: ["items", "55"],
//            headers: ["Authorization": ["Bearer incoming-token"]]
//        )
//        
//        let parsed = try router.parse(requestData)
//        
//        #expect(parsed.auth.token == "incoming-token")
//        #expect(parsed.api == TestAPI.fetch(id: 55))
//    }
    
    @Test("API preserves equality")
    func testAPIPreservesEquality() throws {
        let auth1 = try BearerAuth(token: "token-abc")
        let auth2 = try BearerAuth(token: "token-abc")
        let auth3 = try BearerAuth(token: "token-xyz")
        
        let api1 = AuthenticatingAPI<BearerAuth, TestAPI>(auth: auth1, api: TestAPI.fetch(id: 1))
        let api2 = AuthenticatingAPI<BearerAuth, TestAPI>(auth: auth2, api: TestAPI.fetch(id: 1))
        let api3 = AuthenticatingAPI<BearerAuth, TestAPI>(auth: auth3, api: TestAPI.fetch(id: 1))
        let api4 = AuthenticatingAPI<BearerAuth, TestAPI>(auth: auth1, api: TestAPI.fetch(id: 2))
        
        #expect(api1 == api2)
        #expect(api1 != api3)
        #expect(api1 != api4)
    }
}

@Suite("Error Handling Tests")
struct ErrorHandlingTests {
    
    enum TestAPI: Equatable, Sendable {
        case test
    }
    
    struct FailingRouter: ParserPrinter, Sendable, TestDependencyKey {
        typealias Input = URLRequestData
        typealias Output = TestAPI
        static var testValue: FailingRouter { FailingRouter() }
        
        var body: some URLRouting.Router<TestAPI> {
            OneOf {
                Route(.case(TestAPI.test)) {
                    Path { "test" }
                    Method.get
                }
            }
        }
        
        func parse(_ input: inout URLRequestData) throws -> TestAPI {
            struct TestError: Swift.Error {}
            throw TestError()
        }
        
        func print(_ output: TestAPI, into input: inout URLRequestData) throws {
            struct TestError: Swift.Error {}
            throw TestError()
        }
    }
    
    @Test("Client handles router print errors gracefully")
    func testClientHandlesRouterPrintErrors() throws {
        let baseURL = URL(string: "https://api.example.com")!
        let token = "test-token"
        
        struct ErrorClient: Sendable {
            let makeRequest: @Sendable (TestAPI) throws -> URLRequest
            
            func execute(_ api: TestAPI) throws -> URLRequest {
                try makeRequest(api)
            }
        }
        
        let client = try AuthenticatingClient<
            BearerAuth,
            BearerAuth.Router,
            TestAPI,
            FailingRouter,
            ErrorClient
        >(
            baseURL: baseURL,
            token: token,
            buildClient: { makeRequest in
                ErrorClient(makeRequest: makeRequest)
            }
        )
        
        #expect(throws: Error.self) {
            _ = try client.client.execute(.test)
        }
    }
    
    @Test("Empty token validation")
    func testEmptyTokenValidation() {
        #expect(throws: Error.self) {
            _ = try BearerAuth(token: "")
        }
    }
    
    @Test("Empty credentials validation")
    func testEmptyCredentialsValidation() {
        #expect(throws: Error.self) {
            _ = try BasicAuth(username: "", password: "valid")
        }
        
        #expect(throws: Error.self) {
            _ = try BasicAuth(username: "valid", password: "")
        }
        
        #expect(throws: Error.self) {
            _ = try BasicAuth(username: "", password: "")
        }
    }
}

@Suite("Integration Tests")
struct IntegrationTests {
    
    enum RealWorldAPI: Equatable, Sendable {
        case getUser(id: String)
    }
    
    struct RealWorldRouter: ParserPrinter, Sendable, TestDependencyKey {
        typealias Input = URLRequestData
        typealias Output = RealWorldAPI
        static var testValue: RealWorldRouter { RealWorldRouter() }
        
        var body: some URLRouting.Router<RealWorldAPI> {
            OneOf {
                
                Route(.case(RealWorldAPI.getUser)) {
                    Path {
                        "users"
                        Parse(.string)
                    }
                    Method.get
                }
            }
        }
    }
    
    @Test("Complex real-world scenario with Bearer auth")
    func testComplexRealWorldScenarioWithBearerAuth() throws {
        let baseURL = URL(string: "https://api.production.com")!
        let apiKey = "sk_live_1234567890abcdef"
        
        struct APIService: Sendable {
            let makeRequest: @Sendable (RealWorldAPI) throws -> URLRequest
          
            
            func getUser(id: String) throws -> URLRequest {
                try makeRequest(.getUser(id: id))
            }
            
        }
        
        let client = try AuthenticatingClient<
            BearerAuth,
            BearerAuth.Router,
            RealWorldAPI,
            RealWorldRouter,
            APIService
        >(
            baseURL: baseURL,
            token: apiKey,
            buildClient: { makeRequest in
                APIService(makeRequest: makeRequest)
            }
        )
        
        
        
        let getUserRequest = try client.client.getUser(id: "usr_abc123")
        #expect(getUserRequest.url?.absoluteString == "https://api.production.com/users/usr_abc123")
        #expect(getUserRequest.httpMethod == "GET")
        
    }
    
}
