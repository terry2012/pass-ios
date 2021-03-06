//
//  PasswordStore.swift
//  pass
//
//  Created by Mingshen Sun on 19/1/2017.
//  Copyright © 2017 Bob Sun. All rights reserved.
//

import Foundation
import Result
import CoreData
import UIKit
import SwiftyUserDefaults
import ObjectiveGit

struct GitCredential {
    
    enum Credential {
        case http(userName: String, password: String)
        case ssh(userName: String, password: String, publicKeyFile: URL, privateKeyFile: URL)
    }
    
    var credential: Credential
    
    func credentialProvider() throws -> GTCredentialProvider {
        return GTCredentialProvider { (_, _, _) -> (GTCredential) in
            let credential: GTCredential?
            switch self.credential {
            case let .http(userName, password):
                credential = try? GTCredential(userName: userName, password: password)
            case let .ssh(userName, password, publicKeyFile, privateKeyFile):
                credential = try? GTCredential(userName: userName, publicKeyURL: publicKeyFile, privateKeyURL: privateKeyFile, passphrase: password)
            }
            return credential ?? GTCredential()
        }
    }
}

class PasswordStore {
    static let shared = PasswordStore()
    
    let storeURL = URL(fileURLWithPath: "\(Globals.documentPath)/password-store")
    let tempStoreURL = URL(fileURLWithPath: "\(Globals.documentPath)/password-store-temp")
    var storeRepository: GTRepository?
    var gitCredential: GitCredential?
    
    let pgp: ObjectivePGP = ObjectivePGP()
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    
    private init() {
        do {
            if FileManager.default.fileExists(atPath: storeURL.path) {
                try storeRepository = GTRepository.init(url: storeURL)
            }
        } catch {
            print(error)
        }
        if Defaults[.pgpKeyID] != "" {
            pgp.importKeys(fromFile: Globals.pgpPublicKeyPath, allowDuplicates: false)
            pgp.importKeys(fromFile: Globals.pgpPrivateKeyPath, allowDuplicates: false)

        }
        if Defaults[.gitRepositoryAuthenticationMethod] == "Password" {
            gitCredential = GitCredential(credential: GitCredential.Credential.http(userName: Defaults[.gitRepositoryUsername], password: Defaults[.gitRepositoryPassword]))
        } else if Defaults[.gitRepositoryAuthenticationMethod] == "SSH Key"{
            gitCredential = GitCredential(credential: GitCredential.Credential.ssh(userName: Defaults[.gitRepositoryUsername], password: Defaults[.gitRepositorySSHPrivateKeyPassphrase]!, publicKeyFile: Globals.sshPublicKeyURL, privateKeyFile: Globals.sshPrivateKeyURL))
        } else {
            gitCredential = nil
        }
        
    }
    
    func initPGP(pgpPublicKeyURL: URL, pgpPublicKeyLocalPath: String, pgpPrivateKeyURL: URL, pgpPrivateKeyLocalPath: String) throws {
        let pgpPublicData = try Data(contentsOf: pgpPublicKeyURL)
        try pgpPublicData.write(to: URL(fileURLWithPath: pgpPublicKeyLocalPath), options: .atomic)
        
        let pgpPrivateData = try Data(contentsOf: pgpPrivateKeyURL)
        try pgpPrivateData.write(to: URL(fileURLWithPath: pgpPrivateKeyLocalPath), options: .atomic)
        
        pgp.importKeys(fromFile: pgpPublicKeyLocalPath, allowDuplicates: false)
        pgp.importKeys(fromFile: pgpPrivateKeyLocalPath, allowDuplicates: false)

        let key = pgp.getKeysOf(.public)[0]
        Defaults[.pgpKeyID] = key.keyID!.shortKeyString
        if let gpgUser = key.users[0] as? PGPUser {
            Defaults[.pgpKeyUserID] = gpgUser.userID
        }
    }
    
    
    func cloneRepository(remoteRepoURL: URL,
                         credential: GitCredential,
                         transferProgressBlock: @escaping (UnsafePointer<git_transfer_progress>, UnsafeMutablePointer<ObjCBool>) -> Void,
                         checkoutProgressBlock: @escaping (String?, UInt, UInt) -> Void) throws {
        let credentialProvider = try credential.credentialProvider()
        let options: [String: Any] = [
            GTRepositoryCloneOptionsCredentialProvider: credentialProvider,
        ]
        storeRepository = try GTRepository.clone(from: remoteRepoURL, toWorkingDirectory: tempStoreURL, options: options, transferProgressBlock:transferProgressBlock, checkoutProgressBlock: checkoutProgressBlock)
        let fm = FileManager.default
        do {
            if fm.fileExists(atPath: storeURL.path) {
                try fm.removeItem(at: storeURL)
            }
            try fm.copyItem(at: tempStoreURL, to: storeURL)
            try fm.removeItem(at: tempStoreURL)
        } catch {
            print(error)
        }
        storeRepository = try GTRepository(url: storeURL)
        updatePasswordEntityCoreData()
        gitCredential = credential
    }
    
    func pullRepository(transferProgressBlock: @escaping (UnsafePointer<git_transfer_progress>, UnsafeMutablePointer<ObjCBool>) -> Void) throws {
        if gitCredential == nil {
            throw NSError(domain: "me.mssun.pass.error", code: 1, userInfo: [NSLocalizedDescriptionKey: "Git Repository is not set."])
        }
        let credentialProvider = try gitCredential!.credentialProvider()
        let options: [String: Any] = [
            GTRepositoryRemoteOptionsCredentialProvider: credentialProvider
        ]
        let remote = try GTRemote(name: "origin", in: storeRepository!)
        try storeRepository?.pull((storeRepository?.currentBranch())!, from: remote, withOptions: options, progress: transferProgressBlock)
        updatePasswordEntityCoreData()
    }
    
    func updatePasswordEntityCoreData() {
        deleteCoreData(entityName: "PasswordEntity")
        deleteCoreData(entityName: "PasswordCategoryEntity")
        
        let fm = FileManager.default
        fm.enumerator(atPath: storeURL.path)?.forEach({ (e) in
            if let e = e as? String, let url = URL(string: e) {
                if url.pathExtension == "gpg" {
                    let passwordEntity = PasswordEntity(context: context)
                    let endIndex =  url.lastPathComponent.index(url.lastPathComponent.endIndex, offsetBy: -4)
                    passwordEntity.name = url.lastPathComponent.substring(to: endIndex)
                    passwordEntity.rawPath = "\(url.path)"
                    let items = url.path.characters.split(separator: "/").map(String.init)
                    for i in 0 ..< items.count - 1 {
                        let passwordCategoryEntity = PasswordCategoryEntity(context: context)
                        passwordCategoryEntity.category = items[i]
                        passwordCategoryEntity.level = Int16(i)
                        passwordCategoryEntity.password = passwordEntity
                    }
                }
            }
        })
        do {
            try context.save()
        } catch {
            print("Error with save: \(error)")
        }
    }
    
    func fetchPasswordEntityCoreData() -> [PasswordEntity] {
        let passwordEntityFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "PasswordEntity")
        do {
            let fetchedPasswordEntities = try context.fetch(passwordEntityFetch) as! [PasswordEntity]
            return fetchedPasswordEntities.sorted { $0.name!.caseInsensitiveCompare($1.name!) == .orderedAscending }
        } catch {
            fatalError("Failed to fetch passwords: \(error)")
        }
    }
    
    func fetchPasswordCategoryEntityCoreData(password: PasswordEntity) -> [PasswordCategoryEntity] {
        let passwordCategoryEntityFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "PasswordCategoryEntity")
        passwordCategoryEntityFetchRequest.predicate = NSPredicate(format: "password = %@", password)
        passwordCategoryEntityFetchRequest.sortDescriptors = [NSSortDescriptor(key: "level", ascending: true)]
        do {
            let passwordCategoryEntities = try context.fetch(passwordCategoryEntityFetchRequest) as! [PasswordCategoryEntity]
            return passwordCategoryEntities
        } catch {
            fatalError("Failed to fetch password categories: \(error)")
        }
    }
    
    func fetchUnsyncedPasswords() -> [PasswordEntity] {
        let passwordEntityFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "PasswordEntity")
        passwordEntityFetchRequest.predicate = NSPredicate(format: "synced = %i", 0)
        do {
            let passwordEntities = try context.fetch(passwordEntityFetchRequest) as! [PasswordEntity]
            return passwordEntities
        } catch {
            fatalError("Failed to fetch passwords: \(error)")
        }
    }
    
    func setAllSynced() {
        let passwordEntities = fetchUnsyncedPasswords()
        for passwordEntity in passwordEntities {
            passwordEntity.synced = true
        }
        do {
            try context.save()
        } catch {
            fatalError("Failed to save: \(error)")
        }
    }
    
    func getNumberOfUnsyncedPasswords() -> Int {
        let passwordEntityFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "PasswordEntity")
        do {
            passwordEntityFetchRequest.predicate = NSPredicate(format: "synced = %i", 0)
            return try context.count(for: passwordEntityFetchRequest)
        } catch {
            fatalError("Failed to fetch employees: \(error)")
        }
    }
    
    func updateRemoteRepo() {
    }
    
    func createCommitInRepository(message: String, fileData: Data, filename: String, progressBlock: (_ progress: Float) -> Void) -> GTCommit? {
        do {
            let head = try storeRepository!.headReference()
            let branch = GTBranch(reference: head, repository: storeRepository!)
            let headCommit = try branch?.targetCommit()
            
            let treeBulider = try GTTreeBuilder(tree: headCommit?.tree, repository: storeRepository!)
            try treeBulider.addEntry(with: fileData, fileName: filename, fileMode: GTFileMode.blob)
            
            let newTree = try treeBulider.writeTree()
            let headReference = try storeRepository!.headReference()
            let commitEnum = try GTEnumerator(repository: storeRepository!)
            try commitEnum.pushSHA(headReference.targetOID.sha)
            let parent = commitEnum.nextObject() as! GTCommit
            progressBlock(0.5)
            let commit = try storeRepository!.createCommit(with: newTree, message: message, parents: [parent], updatingReferenceNamed: headReference.name)
            progressBlock(0.7)
            return commit
        } catch {
            print(error)
        }
        return nil
    }
    
    
    private func getLocalBranch(withName branchName: String) -> GTBranch? {
        do {
            let reference = GTBranch.localNamePrefix().appending(branchName)
            let branches = try storeRepository!.branches(withPrefix: reference)
            return branches[0]
        } catch {
            print(error)
        }
        return nil
    }
    
    func pushRepository(transferProgressBlock: @escaping (UInt32, UInt32, Int, UnsafeMutablePointer<ObjCBool>) -> Void) throws {
        let credentialProvider = try gitCredential!.credentialProvider()
        let options: [String: Any] = [
            GTRepositoryRemoteOptionsCredentialProvider: credentialProvider,
            ]
        let masterBranch = getLocalBranch(withName: "master")!
        let remote = try GTRemote(name: "origin", in: storeRepository!)
        try storeRepository?.push(masterBranch, to: remote, withOptions: options, progress: transferProgressBlock)
    }
    
    func add(password: Password, progressBlock: (_ progress: Float) -> Void) {
        progressBlock(0.0)
        let passwordEntity = NSEntityDescription.insertNewObject(forEntityName: "PasswordEntity", into: context) as! PasswordEntity
        do {
            let encryptedData = try passwordEntity.encrypt(password: password)
            progressBlock(0.3)
            let saveURL = storeURL.appendingPathComponent("\(password.name).gpg")
            try encryptedData.write(to: saveURL)
            passwordEntity.rawPath = "\(password.name).gpg"
            passwordEntity.synced = false
            try context.save()
            print(saveURL.path)
            let _ = createCommitInRepository(message: "Add new password by pass for iOS", fileData: encryptedData, filename: saveURL.lastPathComponent, progressBlock: progressBlock)
            progressBlock(1.0)
        } catch {
            print(error)
        }
    }
    
    func deleteCoreData(entityName: String) {
        let deleteFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetchRequest)
        
        do {
            try context.execute(deleteRequest)
        } catch let error as NSError {
            print(error)
        }
    }
    
    func erase() {
        Utils.removeFileIfExists(at: storeURL)
        Utils.removeFileIfExists(atPath: Globals.pgpPublicKeyPath)
        Utils.removeFileIfExists(atPath: Globals.pgpPrivateKeyPath)
        Utils.removeFileIfExists(at: Globals.sshPrivateKeyURL)
        Utils.removeFileIfExists(at: Globals.sshPublicKeyURL)
        
        deleteCoreData(entityName: "PasswordEntity")
        deleteCoreData(entityName: "PasswordCategoryEntity")
        
        Utils.eraseAllUserDefaults()
    }
}
