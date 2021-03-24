//
//  AuthProvider+public.swift
//  
//
//  Created by Vsevolod Pavlovskyi on 24.03.2021.
//

import Foundation
import NetworkService
import KeychainWrapper

extension AuthProvider {

    // MARK: Login

    public func login(credentials: [String: String], then: @escaping (AuthError?) -> Void) {
        guard let resource = makeLoginResource(credentials: credentials) else {
            then(.internalError)
            return
        }

        networkService.performRequest(for: resource, decodingTo: Token.self) { result in
            switch result {
            case .success(let tokenResponse):
                let token = tokenResponse.token
                saveToken(token: token, then: then)
            case .failure(let error):
                handleNetworkError(error: error, then: then)
            }
        }
    }

    // MARK: Logout

    public func logout(then: @escaping (AuthError?) -> Void) {

        // Retreive token.
        guard let token = try? secureStorage.get(forKey: "token") else {
            then(.userIsAlreadyLoggedOut)
            return
        }

        // Clear token.
        try? secureStorage.delete(forKey: "token")

        guard let resource = makeLogoutResource(token: token) else {
            then(.internalError)
            return
        }

        networkService.performRequest(for: resource) { result in
            switch result {
            case .success:
                then(nil)
            case .failure(let error):
                handleNetworkError(error: error, then: then)
            }
        }
    }

    // MARK: Register

    public func register(credentials: [String: String], then: @escaping (AuthError?) -> Void) {

        guard let resource = makeRegisterResource(credentials: credentials) else {
            then(.internalError)
            return
        }

        networkService.performRequest(for: resource,
                                      decodingTo: Token.self) { result in

            switch result {
            case .success(let tokenResponse):
                let token = tokenResponse.token
                saveToken(token: token, then: then)
            case .failure(let error):
                handleNetworkError(error: error, then: then)
            }
        }
    }

}
