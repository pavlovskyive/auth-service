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
    
    public var loggedIn: Bool = false

    private var authDelegates = MulticastDelegate<AuthDelegate>()

    private var secureStorage: SecureStorage
    private var authService: Authenticator
    private var networkProvider: NetworkProvider
    
    private var tempCredentials: [String: String]?

    public init(networkProvider: NetworkProvider,
                secureStorage: SecureStorage,
                config: AuthConfig) {

        self.networkProvider = networkProvider
        self.secureStorage = secureStorage
        self.authService = AuthService(networkProvider: networkProvider,
                                       config: config)
        
        tryLogin()
    }
    
    public func login(credentials: [String: String], then: @escaping TokenResult) {
        
        tempCredentials = credentials

        authService.login(credentials: credentials) { [weak self] result in
            switch result {
            case .success(let token):
                self?.saveCredentialsToStorage(credentials)
                self?.handleTokenRetreiving(token: token)
                then(.success(token))
                self?.authDelegates.invoke { $0.onLogin() }
            case .failure(let error):
                then(.failure(error))
            }
        }

    }
    
    public func tryLogin() {

        guard let credentialsString = try? secureStorage.get(forKey: "credentials"),
              let credentials = parseString(credentialsString) else {
            return
        }

        login(credentials: credentials) {_ in}

    }

    public func logout(then: @escaping ErrorCompletion) {
        deleteCredentialsFromStorage()
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
        
        loggedIn = true
        
        saveTokenToStorage(token)
        setNetworkAuthorization(token)
    }
    
    func handleTokenDeletion() {

        loggedIn = false

        deleteTokenFromStorage()
        removeNetworkAuthorization()
    }
    
    func setNetworkAuthorization(_ token: String) {
        networkProvider.setAuthorization("Bearer \(token)")
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
    
    func saveCredentialsToStorage(_ credentials: [String: String]?) {
        guard let credentials = credentials,
              let credentialsString = parseCredentials(credentials) else {
            return
        }
        
        try? secureStorage.set(credentialsString, forKey: "credentials")
    }
    
    func deleteCredentialsFromStorage() {
        try? secureStorage.delete(forKey: "credentials")
    }
    
    func parseCredentials(_ credentials: [String: String]) -> String? {

        guard let data = try? JSONSerialization.data(withJSONObject: credentials, options: []),
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }

        return string
    }
    
    func parseString(_ string: String) -> [String: String]? {
        guard let data = string.data(using: .utf8),
              let credentials = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String] else {
            return nil
        }

        return credentials
    }
    
}


