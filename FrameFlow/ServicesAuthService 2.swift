//
//  AuthService.swift
//  FrameFlow
//
//  Created by LMTD on 04/11/2025.
//

import Foundation
import Combine
import UIKit

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var loadingState: LoadingState = .idle
    
    private let apiService = APIService.shared
    private let keychain = KeychainService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        checkAuthenticationStatus()
    }
    
    // MARK: - Authentication Status
    private func checkAuthenticationStatus() {
        // Check if we have a valid token
        if keychain.getAuthToken() != nil {
            Task {
                await loadCurrentUser()
            }
        }
    }
    
    // MARK: - Login
    func login(email: String, password: String) async {
        loadingState = .loading
        
        do {
            let response = try await apiService.login(email: email, password: password)
            
            currentUser = response.user
            isAuthenticated = true
            loadingState = .success
            
            HapticManager.notification(.success)
            
        } catch {
            loadingState = .failure(error.localizedDescription)
            HapticManager.notification(.error)
        }
    }
    
    // MARK: - Sign Up
    func signUp(email: String, password: String, fullName: String, instagramHandle: String? = nil, niche: String? = nil) async {
        loadingState = .loading
        
        do {
            let response = try await apiService.signUp(
                email: email,
                password: password,
                fullName: fullName,
                instagramHandle: instagramHandle,
                niche: niche
            )
            
            currentUser = response.user
            isAuthenticated = true
            loadingState = .success
            
            HapticManager.notification(.success)
            
        } catch {
            loadingState = .failure(error.localizedDescription)
            HapticManager.notification(.error)
        }
    }
    
    // MARK: - Load Current User
    func loadCurrentUser() async {
        do {
            let user = try await apiService.getCurrentUser()
            currentUser = user
            isAuthenticated = true
            loadingState = .success
        } catch {
            // If we can't load the user, the token is probably invalid
            logout()
            loadingState = .failure(error.localizedDescription)
        }
    }
    
    // MARK: - Logout
    func logout() {
        apiService.logout()
        currentUser = nil
        isAuthenticated = false
        loadingState = .idle
        
        HapticManager.impact(.light)
    }
    
    // MARK: - Helper Properties
    var isLoading: Bool {
        return loadingState.isLoading
    }
    
    var errorMessage: String? {
        if case .failure(let error) = loadingState {
            return error
        }
        return nil
    }
}