//
//  AuthProvider.swift
//  
//
//  Created by Vsevolod Pavlovskyi on 24.03.2021.
//

import Foundation
import NetworkService
import KeychainWrapper

public protocol AuthProvider {

    var networkService: NetworkProvider { get }
    var secureStorage: SecureStorage { get }
    var config: AuthConfig { get }

    var isAuthorized: Bool { get }

    func login(credentials: [String: String], then: @escaping (AuthError?) -> Void)
    func logout(then: @escaping (AuthError?) -> Void)
    func register(credentials: [String: String], then: @escaping (AuthError?) -> Void)

}
