//
//  File.swift
//  
//
//  Created by Vsevolod Pavlovskyi on 24.03.2021.
//

import Foundation

public struct AuthConfig {

    var scheme: String
    var host: String

    var loginPath: String
    var registerPath: String
    var logoutPath: String

    public init(scheme: String,
                host: String,
                loginPath: String,
                registerPath: String,
                logoutPath: String) {

        self.scheme = scheme
        self.host = host
        self.loginPath = loginPath
        self.registerPath = registerPath
        self.logoutPath = logoutPath
    }

}
