//
//  AuthProvider.swift
//
//
//  Created by Vsevolod Pavlovskyi on 23.03.2021.
//

import Foundation
import NetworkService
import KeychainWrapper
import SwiftyBeaver

let log = SwiftyBeaver.self

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
        
        let platform = SBPlatformDestination(appID: "Gw3AJo",
                                             appSecret: "afxsclzQ9qhnltomqgiu2vxlgc0rqwoc",
                                             encryptionKey: "cWtgjh7gtqdkhplpwlKvrigmTDwraUof")

        log.addDestination(platform)
        log.info("Initializing Auth provider...")

        self.networkProvider = networkProvider
        self.secureStorage = secureStorage
        self.authService = AuthService(networkProvider: networkProvider,
                                       config: config)
        
        tryLogin()
    }
    
    public func login(credentials: [String: String], then: @escaping TokenResult) {
        
        tempCredentials = credentials
        log.info("Logging in...")
        authService.login(credentials: credentials) { [weak self] result in
            switch result {
            case .success(let token):
                log.info("Logged in successfully")
                self?.saveCredentialsToStorage(credentials)
                self?.handleTokenRetreiving(token: token)
                then(.success(token))
                self?.authDelegates.invoke { $0.onLogin() }
            case .failure(let error):
                log.error(error.localizedDescription)
                then(.failure(error))
            }
        }

    }
    
    public func tryLogin() {

        log.info("Trying to log in with saved credentials...")
        guard let credentialsString = try? secureStorage.get(forKey: "credentials"),
              let credentials = parseString(credentialsString) else {
            log.info("No credentials saved on device")
            return
        }

        log.info("Found credentials")
        login(credentials: credentials) {_ in}

    }

    public func logout(then: @escaping ErrorCompletion) {
        log.info("Logging out...")
        deleteCredentialsFromStorage()
        authDelegates.invoke { $0.onLogout() }
        handleTokenDeletion()
        authService.logout { then($0) }
    }

    public func register(credentials: [String: String], then: @escaping TokenResult) {

        log.info("Trying to register user...")
        authService.register(credentials: credentials) { [weak self] result in
            switch result {
            case .success(let token):
                log.info("Successfully registered")
                self?.handleTokenRetreiving(token: token)
                then(.success(token))
                self?.authDelegates.invoke { $0.onLogin() }
            case .failure(let error):
                log.error(error.localizedDescription)
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
        log.verbose("Handling token retreiving...")
        loggedIn = true
        
        saveTokenToStorage(token)
        setNetworkAuthorization(token)
    }
    
    func handleTokenDeletion() {
        log.verbose("Handling token deletion...")
        loggedIn = false

        deleteTokenFromStorage()
        removeNetworkAuthorization()
    }
    
    func setNetworkAuthorization(_ token: String) {
        log.verbose("Setting token to Network Service...")
        networkProvider.setAuthorization("Bearer \(token)")
    }
    
    func removeNetworkAuthorization() {
        log.verbose("Removing token to Network Service...")
        networkProvider.clearAuthorization()
    }
    
    func saveTokenToStorage(_ token: String) {
        log.verbose("Saving token to storage...")
        try? secureStorage.set(token, forKey: "token")
    }
    
    func deleteTokenFromStorage() {
        log.verbose("Deleting token from storage...")
        try? secureStorage.delete(forKey: "token")
    }
    
    func saveCredentialsToStorage(_ credentials: [String: String]?) {
        log.verbose("Saving credentials to storage...")
        guard let credentials = credentials,
              let credentialsString = parseCredentials(credentials) else {
            return
        }
        
        try? secureStorage.set(credentialsString, forKey: "credentials")
    }
    
    func deleteCredentialsFromStorage() {
        log.verbose("Deleting token from storage...")
        try? secureStorage.delete(forKey: "credentials")
    }
    
    func parseCredentials(_ credentials: [String: String]) -> String? {

        guard let data = try? JSONSerialization.data(withJSONObject: credentials, options: []),
              let string = String(data: data, encoding: .utf8) else {
            log.error("Could not parse credentials to String")
            return nil
        }

        return string
    }
    
    func parseString(_ string: String) -> [String: String]? {
        guard let data = string.data(using: .utf8),
              let credentials = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String] else {
            log.error("Could not parse credentials string to [String: String]")
            return nil
        }

        return credentials
    }
    
}


