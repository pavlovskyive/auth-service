//
//  File.swift
//  
//
//  Created by Vsevolod Pavlovskyi on 24.03.2021.
//

import Foundation
import NetworkService

public enum AuthError: Error {

    // Internal Errors
    case internalError
    case internalServerError

    // User Errors
    case userIsAlreadyLoggedOut
    case userNotFound
    case userAlreadyExists

    // Network Errors
    case networkError(NetworkError)

    // Secure Storage Errors
    case secureStorageError

    // Unknown Errors
    case unknownError(Error)

}

extension AuthError: Equatable {

    public static func == (lhs: AuthError, rhs: AuthError) -> Bool {
        lhs.localizedDescription == rhs.localizedDescription
    }

}
