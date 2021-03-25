//
//  AuthService.swift
//  
//
//  Created by Vsevolod Pavlovskyi on 25.03.2021.
//

import Foundation
import NetworkService

public protocol Authenticator {

    typealias TokenResult = (Result<String, AuthError>) -> Void
    typealias ErrorCompletion = (AuthError?) -> Void
    
    func login(credentials: [String: String], then: @escaping TokenResult)
    func logout(then: @escaping ErrorCompletion)
    func register(credentials: [String: String], then: @escaping TokenResult)

}

public final class AuthService: Authenticator {
    
    private let networkProvider: NetworkProvider
    private let config: AuthConfig
    
    public init(networkProvider: NetworkProvider,
                config: AuthConfig) {
        self.networkProvider = networkProvider
        self.config = config
    }

    // MARK: Login

    public func login(credentials: [String: String],
                      then: @escaping TokenResult) {

        guard let resource = makeLoginResource(credentials: credentials) else {
            then(.failure(.internalError))
            return
        }

        networkProvider.performRequest(for: resource) { result in
            switch result {
            case .success(let tokenData):
                self.handleTokenData(tokenData, then: then)
            case .failure(let error):
                then(.failure(self.handleNetworkError(error: error)))
            }
        }
    }

    // MARK: Logout

    public func logout(then: @escaping ErrorCompletion) {

        guard let resource = makeLogoutResource() else {
            then(.internalError)
            return
        }

        networkProvider.performRequest(for: resource) { result in

            switch result {
            case .success:
                then(nil)
            case .failure(let error):
                then(self.handleNetworkError(error: error))
            }
        }
    }

    // MARK: Register

    public func register(credentials: [String: String], then: @escaping TokenResult) {

        guard let resource = makeRegisterResource(credentials: credentials) else {
            then(.failure(.internalError))
            return
        }

        networkProvider.performRequest(for: resource) { result in
            switch result {
            case .success(let tokenData):
                self.handleTokenData(tokenData, then: then)
            case .failure(let error):
                then(.failure(self.handleNetworkError(error: error)))
            }
        }
    }

}


extension AuthService {

    // MARK: Resource creations

    func makeLoginResource(credentials: [String: String]) -> Resource? {

        guard let body = try? JSONSerialization.data(withJSONObject: credentials),
              let url = buildURL(with: config.loginPath) else {
            return nil
        }
        
        let headers = [
            "Content-Type": "application/json",
            "accept": "application/json"
        ]

        return Resource(method: .post, url: url, body: body, headers: headers)
    }

    func makeLogoutResource() -> Resource? {

        guard let url = buildURL(with: config.logoutPath) else {
            return nil
        }

        return Resource(method: .put, url: url)
    }

    func makeRegisterResource(credentials: [String: String]) -> Resource? {

        guard let body = try? JSONSerialization.data(withJSONObject: credentials),
              let url = buildURL(with: config.registerPath) else {
            return nil
        }
        
        let headers = [
            "Content-Type": "application/json",
            "accept": "application/json"
        ]

        return Resource(method: .post, url: url, body: body, headers: headers)
    }

    func buildURL(with path: String) -> URL? {

        var components = URLComponents()

        components.scheme = config.scheme
        components.host = config.host
        components.path = path

        return components.url
    }
    
    // MARK: Handlers
    
    func handleTokenData(_ data: Data, then: @escaping (Result<String, AuthError>) -> Void) {

        guard let token = String(data: data, encoding: .utf8) else {
            then(.failure(.badData))
            return
        }

        then(.success(token))
    }

    func handleNetworkError(error: NetworkError) -> AuthError {
        switch error {
        case .badStatusCode(400):
            return .internalServerError
        case .badStatusCode(401):
            return .userIsAlreadyLoggedOut
        case .badStatusCode(404):
            return .userNotFound
        case .badStatusCode(409):
            return .userAlreadyExists
        default:
            return .networkError(error)
        }
    }

}
