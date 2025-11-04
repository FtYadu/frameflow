//
//  AuthViewModel.swift
//  FrameFlow
//
//  Created by LMTD on 04/11/2025.
//

import Foundation
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var fullName = ""
    @Published var instagramHandle = ""
    @Published var niche = ""
    
    @Published var isShowingSignUp = false
    @Published var formError: String?
    
    private let authService = AuthService.shared
    private var cancellables = Set<AnyCancellable>()
    
    var isLoading: Bool {
        return authService.isLoading
    }
    
    var errorMessage: String? {
        return formError ?? authService.errorMessage
    }
    
    init() {
        // Clear form error when authentication state changes
        authService.$loadingState
            .sink { [weak self] state in
                if case .failure = state {
                    // Error is handled by authService
                } else {
                    self?.formError = nil
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Validation
    private func validateLoginForm() -> Bool {
        formError = nil
        
        if email.isEmpty {
            formError = "Email is required"
            return false
        }
        
        if !email.isValidEmail {
            formError = "Please enter a valid email address"
            return false
        }
        
        if password.isEmpty {
            formError = "Password is required"
            return false
        }
        
        if password.count < 6 {
            formError = "Password must be at least 6 characters"
            return false
        }
        
        return true
    }
    
    private func validateSignUpForm() -> Bool {
        formError = nil
        
        if fullName.isEmpty {
            formError = "Full name is required"
            return false
        }
        
        if email.isEmpty {
            formError = "Email is required"
            return false
        }
        
        if !email.isValidEmail {
            formError = "Please enter a valid email address"
            return false
        }
        
        if password.isEmpty {
            formError = "Password is required"
            return false
        }
        
        if password.count < 6 {
            formError = "Password must be at least 6 characters"
            return false
        }
        
        if password != confirmPassword {
            formError = "Passwords don't match"
            return false
        }
        
        return true
    }
    
    // MARK: - Actions
    func login() async {
        guard validateLoginForm() else { return }
        
        await authService.login(email: email, password: password)
    }
    
    func signUp() async {
        guard validateSignUpForm() else { return }
        
        let cleanInstagramHandle = instagramHandle.isEmpty ? nil : instagramHandle.replacingOccurrences(of: "@", with: "")
        let cleanNiche = niche.isEmpty ? nil : niche
        
        await authService.signUp(
            email: email,
            password: password,
            fullName: fullName,
            instagramHandle: cleanInstagramHandle,
            niche: cleanNiche
        )
    }
    
    func toggleSignUpMode() {
        isShowingSignUp.toggle()
        clearForm()
    }
    
    func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        fullName = ""
        instagramHandle = ""
        niche = ""
        formError = nil
    }
}