//
//  DefaultKeys.swift
//  pass
//
//  Created by Mingshen Sun on 21/1/2017.
//  Copyright © 2017 Bob Sun. All rights reserved.
//

import Foundation
import SwiftyUserDefaults

extension DefaultsKeys {
//    static let pgpKeyURL = DefaultsKey<URL?>("pgpKeyURL")
    static let pgpPublicKeyURL = DefaultsKey<URL?>("pgpPublicKeyURL")
    static let pgpPrivateKeyURL = DefaultsKey<URL?>("pgpPrivateKeyURL")

    static let pgpKeyPassphrase = DefaultsKey<String>("pgpKeyPassphrase")
    static let pgpKeyID = DefaultsKey<String>("pgpKeyID")
    static let pgpKeyUserID = DefaultsKey<String>("pgpKeyUserID")
    
    static let gitRepositoryURL = DefaultsKey<URL?>("gitRepositoryURL")
    static let gitRepositoryAuthenticationMethod = DefaultsKey<String>("gitRepositoryAuthenticationMethod")
    static let gitRepositoryUsername = DefaultsKey<String>("gitRepositoryUsername")
    static let gitRepositoryPassword = DefaultsKey<String>("gitRepositoryPassword")
    static let gitRepositorySSHPublicKeyURL = DefaultsKey<URL?>("gitRepositorySSHPublicKeyURL")
    static let gitRepositorySSHPrivateKeyURL = DefaultsKey<URL?>("gitRepositorySSHPrivateKeyURL")
    static let gitRepositorySSHPrivateKeyPassphrase = DefaultsKey<String?>("gitRepositorySSHPrivateKeyPassphrase")
    static let lastUpdatedTime = DefaultsKey<Date?>("lasteUpdatedTime")
    
    static let isTouchIDOn = DefaultsKey<Bool>("isTouchIDOn")
    static let passcodeKey = DefaultsKey<String?>("passcodeKey")
}

extension Utils {
    static func eraseAllUserDefaults() {
        Defaults.remove(.pgpPublicKeyURL)
        Defaults.remove(.pgpPrivateKeyURL)
        
        Defaults.remove(.pgpKeyPassphrase)
        Defaults.remove(.pgpKeyID)
        Defaults.remove(.pgpKeyUserID)
        
        Defaults.remove(.gitRepositoryURL)
        Defaults.remove(.gitRepositoryAuthenticationMethod)
        Defaults.remove(.gitRepositoryUsername)
        Defaults.remove(.gitRepositoryPassword)
        Defaults.remove(.gitRepositorySSHPublicKeyURL)
        Defaults.remove(.gitRepositorySSHPrivateKeyURL)
        Defaults.remove(.gitRepositorySSHPrivateKeyPassphrase)
        Defaults.remove(.lastUpdatedTime)
        
        Defaults.remove(.isTouchIDOn)
        Defaults.remove(.passcodeKey)
    }
}
