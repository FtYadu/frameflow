//
//  KeychainService.swift
//  FrameFlow
//
//  Created by LMTD on 04/11/2025.
//

import Foundation
import Security

class KeychainService {
    static let shared = KeychainService()
    
    private init() {}
    
    // MARK: - Save
    func save(key: String, data: Data) -> Bool {
        let query = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrService as String: Config.keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ] as [String: Any]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func save(key: String, string: String) -> Bool {
        guard let data = string.data(using: .utf8) else { return false }
        return save(key: key, data: data)
    }
    
    // MARK: - Load
    func load(key: String) -> Data? {
        let query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Config.keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ] as [String: Any]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess {
            return dataTypeRef as? Data
        } else {
            return nil
        }
    }
    
    func loadString(key: String) -> String? {
        guard let data = load(key: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    // MARK: - Delete
    func delete(key: String) -> Bool {
        let query = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrService as String: Config.keychainService,
            kSecAttrAccount as String: key
        ] as [String: Any]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
    
    // MARK: - Token Management
    func saveAuthToken(_ token: String) -> Bool {
        return save(key: Config.authTokenKey, string: token)
    }
    
    func saveRefreshToken(_ token: String) -> Bool {
        return save(key: Config.refreshTokenKey, string: token)
    }
    
    func getAuthToken() -> String? {
        return loadString(key: Config.authTokenKey)
    }
    
    func getRefreshToken() -> String? {
        return loadString(key: Config.refreshTokenKey)
    }
    
    func clearTokens() {
        _ = delete(key: Config.authTokenKey)
        _ = delete(key: Config.refreshTokenKey)
    }
    
    // MARK: - AI API Key Management
    func saveAPIKey(for provider: AIProvider, key: String) -> Bool {
        return save(key: "api_key_\(provider.rawValue)", string: key)
    }
    
    func getAPIKey(for provider: AIProvider) -> String? {
        return loadString(key: "api_key_\(provider.rawValue)")
    }
    
    func deleteAPIKey(for provider: AIProvider) -> Bool {
        return delete(key: "api_key_\(provider.rawValue)")
    }
    
    func getAllAPIKeys() -> [AIProvider: String] {
        var apiKeys: [AIProvider: String] = [:]
        
        for provider in AIProvider.allCases {
            if let key = getAPIKey(for: provider) {
                apiKeys[provider] = key
            }
        }
        
        return apiKeys
    }
    
    func clearAllAPIKeys() {
        for provider in AIProvider.allCases {
            _ = deleteAPIKey(for: provider)
        }
    }
    
    // MARK: - Agent AI Config Management
    func saveAgentConfig(_ config: AgentAIConfig) -> Bool {
        do {
            let data = try JSONEncoder().encode(config)
            return save(key: "agent_config_\(config.agentType)", data: data)
        } catch {
            return false
        }
    }
    
    func getAgentConfig(for agentType: String) -> AgentAIConfig? {
        guard let data = load(key: "agent_config_\(agentType)") else { return nil }
        
        do {
            return try JSONDecoder().decode(AgentAIConfig.self, from: data)
        } catch {
            return nil
        }
    }
    
    func deleteAgentConfig(for agentType: String) -> Bool {
        return delete(key: "agent_config_\(agentType)")
    }
}