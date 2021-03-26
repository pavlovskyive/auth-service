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
    
    private var authDelegates = MulticastDelegate<AuthDelegate>()

    private var secureStorage: SecureStorage
    private var authService: Authenticator
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

        authService.login(credentials: credentials) { [weak self] result in
            switch result {
            case .success(let token):
                self?.handleTokenRetreiving(token: token)
                then(.success(token))
                self?.authDelegates.invoke { $0.onLogin() }
            case .failure(let error):
                then(.failure(error))
            }
        }

    }

    public func logout(then: @escaping ErrorCompletion) {
        authDelegates.invoke { $0.onLogout() }
        handleTokenDeletion()
        authService.logout { then($0) }
    }

    public func register(credentials: [String: String], then: @escaping TokenResult) {

        authService.register(credentials: credentials) { [weak self] result in
            switch result {
            case .success(let token):
                self?.handleTokenRetreiving(token: token)
                then(.success(token))
                self?.authDelegates.invoke { $0.onLogin() }
            case .failure(let error):
                then(.failure(error))
            }
        }
    }
    
    public func subscribe(_ delegate: AuthDelegate) {
        authDelegates.add(delegate)
    }
    
    public func unsubscribe(_ delegate: AuthDelegate) {
        authDelegates.remove(delegate)
    }

}

extension AuthProvider {
    
    func handleTokenRetreiving(token: String) {
        saveTokenToStorage(token)
        setNetworkAuthorization(token)
    }
    
    func handleTokenDeletion() {
        deleteTokenFromStorage()
        removeNetworkAuthorization()
    }
    
    func setNetworkAuthorization(_ token: String) {
        networkProvider.setAuthorization("Bearer: \(token)")
    }
    
    func removeNetworkAuthorization() {
        networkProvider.clearAuthorization()
    }
    
    func saveTokenToStorage(_ token: String) {
        try? secureStorage.set(token, forKey: "token")
    }
    
    func deleteTokenFromStorage() {
        try? secureStorage.delete(forKey: "token")
    }
    
}


