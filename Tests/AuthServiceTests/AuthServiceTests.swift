import XCTest
@testable import AuthService
import NetworkService
import KeychainWrapper

// swiftlint:disable all

// MARK: - Mocks

class MockedSuccessSecureStorage: SecureStorage {
    
    var token: String?
    
    func set(_ value: String, forKey service: String) throws {
        token = value
    }
    
    func get(forKey service: String) throws -> String {
        guard let token = token else {
            throw SecureStorageError.init(type: .itemNotFound)
        }
        
        return token
    }
    
    func update(_ value: String, forKey service: String) throws {
        token = value
    }
    
    func delete(forKey service: String) throws {
        token = nil
    }
    
}

struct MockedFailSecureStorage: SecureStorage {
    
    func set(_ value: String, forKey service: String) throws {
        throw SecureStorageError(type: .unableToConvertToData)
    }
    
    func get(forKey service: String) throws -> String {
        throw SecureStorageError(type: .itemNotFound)
    }
    
    func update(_ value: String, forKey service: String) throws {
        throw SecureStorageError(type: .itemNotFound)
    }
    
    func delete(forKey service: String) throws {
        throw SecureStorageError(type: .itemNotFound)
    }
    
}

class MockedSuccessNetworkService: NetworkProvider {
    
    var successfulStatusCodes: Range<Int> = 100..<300
    
    var defaultHeaders = [String: String]()
    
    func setSuccessfulStatusCodes(_ range: Range<Int>) {
        successfulStatusCodes = range
    }
    
    func performRequest<T>(for resource: Resource, decodingTo type: T.Type, completion: @escaping (Result<T, NetworkError>) -> Void) where T: Decodable {
        
        // Don't need it.
        completion(.failure(.badStatusCode(404)))
    }
    
    func performRequest(for resource: Resource, completion: @escaping (Result<Data, NetworkError>) -> Void) {
        completion(.success("token".data(using: .utf8)!))
    }
    
}

class MockedFailNetworkService: NetworkProvider {
    
    var errorStatusCode: Int = 400
    
    var successfulStatusCodes: Range<Int> = 100..<300
    
    var defaultHeaders = [String: String]()
    
    func setSuccessfulStatusCodes(_ range: Range<Int>) {
        successfulStatusCodes = range
    }
    
    func performRequest<T>(for resource: Resource, decodingTo type: T.Type, completion: @escaping (Result<T, NetworkError>) -> Void) where T: Decodable {
        
        completion(.failure(.badStatusCode(errorStatusCode)))
    }
    
    func performRequest(for resource: Resource, completion: @escaping (Result<Data, NetworkError>) -> Void) {
        completion(.failure(.badStatusCode(errorStatusCode)))
    }
    
}

// MARK: - Tests

final class AuthServiceTests: XCTestCase {
    
    // MARK: - Login Tests
    func testLogin() {
        
        // MARK: Setup
        
        let credentials = [
            "email": "email@example.com",
            "password": "password"
        ]
        
        var config = AuthConfig(scheme: "https",
                                host: "mock.com",
                                loginPath: "/login",
                                registerPath: "/registration",
                                logoutPath: "/logout")
        
        // MARK: Success
        
        var authService = AuthProvider(networkService: MockedSuccessNetworkService(),
                                       secureStorage: MockedSuccessSecureStorage(),
                                       config: config)
        
        authService.login(credentials: credentials) { error in
            XCTAssertNil(error)
            XCTAssert(authService.isAuthorized == true)
        }
        
        // MARK: User already exists
        
        let failNetworkService = MockedFailNetworkService()
        failNetworkService.errorStatusCode = 404
        
        authService = AuthProvider(networkService: failNetworkService,
                                   secureStorage: MockedSuccessSecureStorage(),
                                   config: config)
        
        authService.login(credentials: credentials) { error in
            XCTAssert(error == AuthError.userNotFound)
            XCTAssert(authService.isAuthorized == false)
        }
        
        // MARK: Secure Storage Error
        
        authService = AuthProvider(networkService: MockedSuccessNetworkService(),
                                   secureStorage: MockedFailSecureStorage(),
                                   config: config)
        
        authService.login(credentials: credentials) { error in
            XCTAssertNotNil(error)
            XCTAssert(authService.isAuthorized == false)
        }
        
        // Network Service - Error
        // Secure Storage - OK
        authService = AuthProvider(networkService: MockedFailNetworkService(),
                                   secureStorage: MockedSuccessSecureStorage(),
                                   config: config)
        
        authService.login(credentials: credentials) { error in
            XCTAssertNotNil(error)
            XCTAssert(authService.isAuthorized == false)
        }
        
        // MARK: Secure Storage Error and Network Service Error
        
        authService = AuthProvider(networkService: MockedFailNetworkService(),
                                   secureStorage: MockedFailSecureStorage(),
                                   config: config)
        
        authService.login(credentials: credentials) { error in
            XCTAssertNotNil(error)
            XCTAssert(authService.isAuthorized == false)
        }
        
        // MARK: URL Build Error
        
        config = AuthConfig(scheme: "https",
                            host: "mock.com",
                            loginPath: "      ",
                            registerPath: "/registration",
                            logoutPath: "/logout")
        
        authService = AuthProvider(networkService: MockedSuccessNetworkService(),
                                   secureStorage: MockedSuccessSecureStorage(),
                                   config: config)
        
        authService.login(credentials: credentials) { error in
            XCTAssertNotNil(error)
            XCTAssert(authService.isAuthorized == false)
        }
        
    }
    
    // MARK: - Logout Tests
    func testLogoutSuccess() {
        
        let successSecureStorage = MockedSuccessSecureStorage()
        
        let config = AuthConfig(scheme: "https",
                                host: "mock.com",
                                loginPath: "/login",
                                registerPath: "/registration",
                                logoutPath: "/logout")
        
        do {
            try successSecureStorage.set("token", forKey: "token")
            
            let authService = AuthProvider(networkService: MockedSuccessNetworkService(),
                                           secureStorage: successSecureStorage,
                                           config: config)
            
            authService.logout { error in
                XCTAssertNil(error)
                XCTAssert(authService.isAuthorized == false)
            }
        } catch {
            XCTFail()
        }
    }
    
    func testLogoutFail() {
        
        // MARK: User is already logged out
        
        var successSecureStorage = MockedSuccessSecureStorage()
        
        var config = AuthConfig(scheme: "https",
                                host: "mock.com",
                                loginPath: "/login",
                                registerPath: "/registration",
                                logoutPath: "/logout")
        
        var authService = AuthProvider(networkService: MockedSuccessNetworkService(),
                                       secureStorage: successSecureStorage,
                                       config: config)
        
        authService.logout { error in
            XCTAssert(error == AuthError.userIsAlreadyLoggedOut)
            XCTAssert(authService.isAuthorized == false)
        }
        
        // MARK: Network Service Error
        
        let failNetworkService = MockedFailNetworkService()
        failNetworkService.errorStatusCode = 401
        
        successSecureStorage = MockedSuccessSecureStorage()
        successSecureStorage.token = "token"
        
        authService = AuthProvider(networkService: failNetworkService,
                                   secureStorage: successSecureStorage,
                                   config: config)
        
        authService.logout { error in
            XCTAssert(error == AuthError.userIsAlreadyLoggedOut)
            XCTAssert(authService.isAuthorized == false)
        }
        
        // MARK: URL Build Error
        
        config = AuthConfig(scheme: "https",
                            host: "mock.com",
                            loginPath: "/login",
                            registerPath: "/registration",
                            logoutPath: "    ")
        
        successSecureStorage = MockedSuccessSecureStorage()
        successSecureStorage.token = "token"
        
        authService = AuthProvider(networkService: MockedSuccessNetworkService(),
                                   secureStorage: successSecureStorage,
                                   config: config)
        
        authService.logout { error in
            XCTAssert(error == AuthError.internalError)
            XCTAssert(authService.isAuthorized == false)
        }
        
    }
    
    // MARK: - Register Tests
    func testRegister() {
        
        // MARK: Setup
        
        let credentials = [
            "email": "email@example.com",
            "password": "password"
        ]
        
        var config = AuthConfig(scheme: "https",
                                host: "mock.com",
                                loginPath: "/login",
                                registerPath: "/registration",
                                logoutPath: "/logout")
        
        // MARK: Success
        
        var authService = AuthProvider(networkService: MockedSuccessNetworkService(),
                                       secureStorage: MockedSuccessSecureStorage(),
                                       config: config)
        
        authService.register(credentials: credentials) { error in
            XCTAssertNil(error)
            XCTAssert(authService.isAuthorized == true)
        }
        
        // MARK: User already exists
        
        let failNetworkService = MockedFailNetworkService()
        failNetworkService.errorStatusCode = 409
        
        authService = AuthProvider(networkService: failNetworkService,
                                   secureStorage: MockedSuccessSecureStorage(),
                                   config: config)
        
        authService.register(credentials: credentials) { error in
            XCTAssert(error == AuthError.userAlreadyExists)
            XCTAssert(authService.isAuthorized == false)
        }
        
        // MARK: Secure Storage Error
        
        authService = AuthProvider(networkService: MockedSuccessNetworkService(),
                                   secureStorage: MockedFailSecureStorage(),
                                   config: config)
        
        authService.register(credentials: credentials) { error in
            XCTAssertNotNil(error)
            XCTAssert(authService.isAuthorized == false)
        }
        
        // MARK: Network Service Error
        
        authService = AuthProvider(networkService: MockedFailNetworkService(),
                                   secureStorage: MockedSuccessSecureStorage(),
                                   config: config)
        
        authService.register(credentials: credentials) { error in
            XCTAssertNotNil(error)
            XCTAssert(authService.isAuthorized == false)
        }
        
        // MARK: Secure Storage and Network Service Errors
        
        authService = AuthProvider(networkService: MockedFailNetworkService(),
                                   secureStorage: MockedFailSecureStorage(),
                                   config: config)
        
        authService.register(credentials: credentials) { error in
            XCTAssertNotNil(error)
            XCTAssert(authService.isAuthorized == false)
        }
        
        // MARK: URL Build Error
        
        config = AuthConfig(scheme: "https",
                            host: "mock.com",
                            loginPath: "/login",
                            registerPath: "   ",
                            logoutPath: "/logout")
        
        authService = AuthProvider(networkService: MockedSuccessNetworkService(),
                                   secureStorage: MockedSuccessSecureStorage(),
                                   config: config)
        
        authService.register(credentials: credentials) { error in
            XCTAssertNotNil(error)
            XCTAssert(authService.isAuthorized == false)
        }
        
    }
    
    static var allTests = [
        ("testLogin", testLogin),
        ("testLogoutSuccess", testLogoutSuccess),
        ("testLogoutFail", testLogoutFail),
        ("testRegister", testRegister)
    ]
}

// swiftlint:enable all
