//
//  File.swift
//  
//
//  Created by Vsevolod Pavlovskyi on 24.03.2021.
//

import Foundation

public struct Token: Codable {
    var token: String

    public init(token: String) {
        self.token = token
    }
}
