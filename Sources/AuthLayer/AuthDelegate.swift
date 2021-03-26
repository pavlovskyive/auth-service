//
//  File.swift
//  
//
//  Created by Vsevolod Pavlovskyi on 25.03.2021.
//

import Foundation

public protocol AuthDelegate {
    
    func onLogin()
    func onLogout()
}

extension AuthDelegate {
    
    func onLogin() {}
    func onLogout() {}
}
