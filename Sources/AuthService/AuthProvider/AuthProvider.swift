//
//  AuthProvider.swift
//
//
//  Created by Vsevolod Pavlovskyi on 23.03.2021.
//

import Foundation
import NetworkService
import KeychainWrapper

public class AuthProvider: AuthService {

    public var networkService: NetworkProvider
    public var secureStorage: SecureStorage
    public var config: AuthConfig

    public var isAuthorized: Bool {
        do {
            _ = try secureStorage.get(forKey: "token")
            return true
        } catch {
            return false
        }
    }

    public init(networkService: NetworkProvider = NetworkService(),
                secureStorage: SecureStorage = KeychainWrapper(),
                config: AuthConfig) {

        self.networkService = networkService
        self.secureStorage = secureStorage
        self.config = config
    }
}
