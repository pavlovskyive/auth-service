//
//  AuthProvider+private.swift
//  
//
//  Created by Vsevolod Pavlovskyi on 24.03.2021.
//

import Foundation
import NetworkService

extension AuthProvider {

    // MARK: Resource creations

    func makeLoginResource(credentials: [String: String]) -> Resource? {

        guard let body = try? JSONSerialization.data(withJSONObject: credentials),
              let url = buildURL(with: config.loginPath) else {
            return nil
        }

        return Resource(method: .post, url: url, body: body)
    }

    func makeLogoutResource(token: String) -> Resource? {

        let tokenObj = Token(token: token)

        guard let body = try? JSONEncoder().encode(tokenObj),
              let url = buildURL(with: config.logoutPath) else {
            return nil
        }

        return Resource(method: .put, url: url, body: body)
    }

    func makeRegisterResource(credentials: [String: String]) -> Resource? {

        guard let body = try? JSONSerialization.data(withJSONObject: credentials),
              let url = buildURL(with: config.registerPath) else {
            return nil
        }

        return Resource(method: .post, url: url, body: body)
    }

    func buildURL(with path: String) -> URL? {

        var components = URLComponents()

        components.scheme = config.scheme
        components.host = config.host
        components.path = path

        return components.url
    }

    // MARK: Save Token

    func saveToken(token: String, then: @escaping (AuthError?) -> Void) {
        do {
            try secureStorage.set(token, forKey: "token")
            then(nil)
        } catch {
            then(.secureStorageError)
        }
    }

    // MARK: Network Error handling

    func handleNetworkError(error: NetworkError, then: @escaping (AuthError?) -> Void) {

        switch error {
        case .badStatusCode(400):
            then(.internalServerError)
        case .badStatusCode(401):
            then(.userIsAlreadyLoggedOut)
        case .badStatusCode(404):
            then(.userNotFound)
        case .badStatusCode(409):
            then(.userAlreadyExists)
        default:
            then(.networkError(error))
        }

        return
    }
}
