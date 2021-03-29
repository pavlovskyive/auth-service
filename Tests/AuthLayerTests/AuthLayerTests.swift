import XCTest
@testable import AuthLayer
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

    var authorization: String?
    
    func setHeader(_ value: String, forKey key: String) {
        
    }
    
    func removeHeader(forKey key: String) {
        
    }
    
    func setAuthorization(_ authorization: String) {
        self.authorization = authorization
    }
    
    func clearAuthorization() {
        authorization = nil
    }
    
    
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
    
    var authorization: String?
    
    func setHeader(_ value: String, forKey key: String) {
        //
    }
    
    func removeHeader(forKey key: String) {
        //
    }
    
    func setAuthorization(_ authorization: String) {
        self.authorization = authorization
    }
    
    func clearAuthorization() {
        self.authorization = nil
    }
    
    
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
        
        var authService = AuthProvider(networkProvider: MockedSuccessNetworkService(),
                                       secureStorage: MockedSuccessSecureStorage(),
                                       config: config)
        
        authService.login(credentials: credentials) { result in
            switch result {
            case .success(let token):
                XCTAssertEqual(token, "token")
            case .failure(_):
                XCTAssert(authService.loggedIn == false)
            }
        }
        
        // MARK: User already exists
        
        let failNetworkService = MockedFailNetworkService()
        failNetworkService.errorStatusCode = 404
        
        authService = AuthProvider(networkProvider: failNetworkService,
                                   secureStorage: MockedSuccessSecureStorage(),
                                   config: config)
        
        authService.login(credentials: credentials) { result in
            switch result {
            case .success(_):
                XCTFail()
            case .failure(_):
                XCTAssert(authService.loggedIn == false)
            }
        }
        
        // Network Service - Error
        // Secure Storage - OK
        authService = AuthProvider(networkProvider: MockedFailNetworkService(),
                                   secureStorage: MockedSuccessSecureStorage(),
                                   config: config)
        
        authService.login(credentials: credentials) { result in
            switch result {
            case .success(_):
                XCTFail()
            case .failure(_):
                XCTAssert(authService.loggedIn == false)
            }
        }
        
        // MARK: Secure Storage Error and Network Service Error
        
        authService = AuthProvider(networkProvider: MockedFailNetworkService(),
                                   secureStorage: MockedFailSecureStorage(),
                                   config: config)
        
        authService.login(credentials: credentials) { result in
            switch result {
            case .success(_):
                XCTFail()
            case .failure(_):
                XCTAssert(authService.loggedIn == false)
            }
        }
        
        // MARK: URL Build Error
        
        config = AuthConfig(scheme: "https",
                            host: "mock.com",
                            loginPath: "      ",
                            registerPath: "/registration",
                            logoutPath: "/logout")
        
        authService = AuthProvider(networkProvider: MockedSuccessNetworkService(),
                                   secureStorage: MockedSuccessSecureStorage(),
                                   config: config)
        
        authService.login(credentials: credentials) { result in
            switch result {
            case .success(_):
                XCTFail()
            case .failure(_):
                XCTAssert(authService.loggedIn == false)
            }
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
            
            let authService = AuthProvider(networkProvider: MockedSuccessNetworkService(),
                                           secureStorage: successSecureStorage,
                                           config: config)
            
            authService.logout { error in
                XCTAssertNil(error)
                XCTAssert(authService.loggedIn == false)
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
        
        var authService = AuthProvider(networkProvider: MockedSuccessNetworkService(),
                                       secureStorage: successSecureStorage,
                                       config: config)
        
        authService.logout { error in
            XCTAssert(authService.loggedIn == false)
        }
        
        // MARK: Network Service Error
        
        let failNetworkService = MockedFailNetworkService()
        failNetworkService.errorStatusCode = 401
        
        successSecureStorage = MockedSuccessSecureStorage()
        successSecureStorage.token = "token"
        
        authService = AuthProvider(networkProvider: failNetworkService,
                                   secureStorage: successSecureStorage,
                                   config: config)
        
        authService.logout { error in
            XCTAssert(error == AuthError.userIsAlreadyLoggedOut)
            XCTAssert(authService.loggedIn == false)
        }
        
        // MARK: URL Build Error
        
        config = AuthConfig(scheme: "https",
                            host: "mock.com",
                            loginPath: "/login",
                            registerPath: "/registration",
                            logoutPath: "    ")
        
        successSecureStorage = MockedSuccessSecureStorage()
        successSecureStorage.token = "token"
        
        authService = AuthProvider(networkProvider: MockedSuccessNetworkService(),
                                   secureStorage: successSecureStorage,
                                   config: config)
        
        authService.logout { error in
            XCTAssert(error == AuthError.internalError)
            XCTAssert(authService.loggedIn == false)
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
        
        var authService = AuthProvider(networkProvider: MockedSuccessNetworkService(),
                                       secureStorage: MockedSuccessSecureStorage(),
                                       config: config)
        
        authService.register(credentials: credentials) { result in
            switch result {
            case .success(_):
                XCTAssert(authService.loggedIn == true)
            case .failure(_):
                XCTFail()
            }
        }
        
        // MARK: User already exists
        
        let failNetworkService = MockedFailNetworkService()
        failNetworkService.errorStatusCode = 409
        
        authService = AuthProvider(networkProvider: failNetworkService,
                                   secureStorage: MockedSuccessSecureStorage(),
                                   config: config)
        
        authService.register(credentials: credentials) { result in
            switch result {
            case .success(_):
                XCTFail()
            case .failure(_):
                XCTAssert(authService.loggedIn == false)
            }
        }

        // MARK: Network Service Error
        
        authService = AuthProvider(networkProvider: MockedFailNetworkService(),
                                   secureStorage: MockedSuccessSecureStorage(),
                                   config: config)
        
        authService.register(credentials: credentials) { result in
            switch result {
            case .success(_):
                XCTFail()
            case .failure(_):
                XCTAssert(authService.loggedIn == false)
            }
        }
        
        // MARK: Secure Storage and Network Service Errors
        
        authService = AuthProvider(networkProvider: MockedFailNetworkService(),
                                   secureStorage: MockedFailSecureStorage(),
                                   config: config)
        
        authService.register(credentials: credentials) { result in
            switch result {
            case .success(_):
                XCTFail()
            case .failure(_):
                XCTAssert(authService.loggedIn == false)
            }
        }
        
        // MARK: URL Build Error
        
        config = AuthConfig(scheme: "https",
                            host: "mock.com",
                            loginPath: "/login",
                            registerPath: "   ",
                            logoutPath: "/logout")
        
        authService = AuthProvider(networkProvider: MockedSuccessNetworkService(),
                                   secureStorage: MockedSuccessSecureStorage(),
                                   config: config)
        
        authService.register(credentials: credentials) { result in
            switch result {
            case .success(_):
                XCTFail()
            case .failure(_):
                XCTAssert(authService.loggedIn == false)
            }
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
