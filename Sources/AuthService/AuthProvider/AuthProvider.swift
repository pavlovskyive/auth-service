//
//  AuthProvider.swift
//
//
//  Created by Vsevolod Pavlovskyi on 23.03.2021.
//

import Foundation
import NetworkService
import KeychainWrapper

public class AuthProvider: Authenticator {

    private var secureStorage: SecureStorage
    private var authService: AuthService
    private var networkProvider: NetworkProvider

    public init(networkProvider: NetworkProvider,
                secureStorage: SecureStorage,
                config: AuthConfig) {

        self.networkProvider = networkProvider
        self.secureStorage = secureStorage
        self.authService = AuthService(networkProvider: networkProvider,
                                       config: config)
    }
    
    public func login(credentials: [String: String], then: @escaping TokenResult) {

        authService.login(credentials: credentials) { result in
            switch result {
            case .success(let token):
                self.handleTokenRetreiving(token: token)
                then(.success(token))
            case .failure(let error):
                then(.failure(error))
            }
        }

    }

    public func logout(then: @escaping ErrorCompletion) {
        handleTokenDeletion()
        authService.logout { then($0) }
    }

    public func register(credentials: [String: String], then: @escaping TokenResult) {

        authService.register(credentials: credentials) { result in
            switch result {
            case .success(let token):
                self.handleTokenRetreiving(token: token)
                then(.success(token))
            case .failure(let error):
                then(.failure(error))
            }
        }

    }

}

extension AuthProvider {
    
    func handleTokenRetreiving(token: String) {
        saveTokenToStorage(token)
        setHeader(token)
    }
    
    func handleTokenDeletion() {
        deleteTokenFromStorage()
        clearHeader()
    }
    
    func setHeader(_ token: String) {
        networkProvider.setHeader(token, forKey: "Bearer token")
    }
    
    func clearHeader() {
        networkProvider.removeHeader(forKey: "Bearer token")
    }
    
    func saveTokenToStorage(_ token: String) {
        try? secureStorage.set(token, forKey: "token")
    }
    
    func deleteTokenFromStorage() {
        try? secureStorage.delete(forKey: "token")
    }
    
}


