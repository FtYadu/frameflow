//
//  LoginView.swift
//  FrameFlow
//
//  Created by LMTD on 04/11/2025.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                VStack(spacing: AppSpacing.lg) {
                    // Header
                    VStack(spacing: AppSpacing.md) {
                        Image(systemName: "camera.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [AppColors.primary, AppColors.secondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("FrameFlow")
                            .font(AppFonts.largeTitle)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("AI-powered automation for photographers")
                            .font(AppFonts.body)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, AppSpacing.xl)
                    
                    // Form
                    VStack(spacing: AppSpacing.lg) {
                        if !viewModel.isShowingSignUp {
                            loginForm
                        } else {
                            signUpForm
                        }
                    }
                    
                    Spacer()
                    
                    // Toggle between login/signup
                    HStack {
                        Text(viewModel.isShowingSignUp ? "Already have an account?" : "Don't have an account?")
                            .foregroundColor(AppColors.textSecondary)
                        
                        Button(viewModel.isShowingSignUp ? "Sign In" : "Sign Up") {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.toggleSignUpMode()
                            }
                        }
                        .foregroundColor(AppColors.primary)
                    }
                    .font(AppFonts.body)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.xl)
            }
        }
    }
    
    // MARK: - Login Form
    private var loginForm: some View {
        VStack(spacing: AppSpacing.lg) {
            VStack(spacing: AppSpacing.md) {
                CustomTextField(
                    title: "Email",
                    text: $viewModel.email,
                    keyboardType: .emailAddress,
                    autocapitalization: .never
                )
                
                CustomSecureField(
                    title: "Password",
                    text: $viewModel.password
                )
            }
            
            if let errorMessage = viewModel.errorMessage {
                ErrorBanner(message: errorMessage)
            }
            
            Button(action: {
                Task {
                    await viewModel.login()
                }
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    
                    Text("Sign In")
                        .font(AppFonts.headline)
                }
                .frame(maxWidth: .infinity)
            }
            .primaryButton()
            .disabled(viewModel.isLoading)
        }
    }
    
    // MARK: - Sign Up Form
    private var signUpForm: some View {
        VStack(spacing: AppSpacing.lg) {
            VStack(spacing: AppSpacing.md) {
                CustomTextField(
                    title: "Full Name",
                    text: $viewModel.fullName
                )
                
                CustomTextField(
                    title: "Email",
                    text: $viewModel.email,
                    keyboardType: .emailAddress,
                    autocapitalization: .never
                )
                
                CustomTextField(
                    title: "Instagram Handle (Optional)",
                    text: $viewModel.instagramHandle,
                    placeholder: "@yourusername"
                )
                
                CustomTextField(
                    title: "Photography Niche (Optional)",
                    text: $viewModel.niche,
                    placeholder: "Wedding, Portrait, Fashion..."
                )
                
                CustomSecureField(
                    title: "Password",
                    text: $viewModel.password
                )
                
                CustomSecureField(
                    title: "Confirm Password",
                    text: $viewModel.confirmPassword
                )
            }
            
            if let errorMessage = viewModel.errorMessage {
                ErrorBanner(message: errorMessage)
            }
            
            Button(action: {
                Task {
                    await viewModel.signUp()
                }
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    
                    Text("Create Account")
                        .font(AppFonts.headline)
                }
                .frame(maxWidth: .infinity)
            }
            .primaryButton()
            .disabled(viewModel.isLoading)
        }
    }
}

// MARK: - Custom Text Field
struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String?
    let keyboardType: UIKeyboardType
    let autocapitalization: TextInputAutocapitalization
    
    init(
        title: String,
        text: Binding<String>,
        placeholder: String? = nil,
        keyboardType: UIKeyboardType = .default,
        autocapitalization: TextInputAutocapitalization = .words
    ) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.keyboardType = keyboardType
        self.autocapitalization = autocapitalization
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textSecondary)
            
            TextField(placeholder ?? title, text: $text)
                .textFieldStyle(CustomTextFieldStyle())
                .keyboardType(keyboardType)
                .textInputAutocapitalization(autocapitalization)
        }
    }
}

// MARK: - Custom Secure Field
struct CustomSecureField: View {
    let title: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textSecondary)
            
            SecureField(title, text: $text)
                .textFieldStyle(CustomTextFieldStyle())
        }
    }
}

// MARK: - Error Banner
struct ErrorBanner: View {
    let message: String
    
    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(AppColors.danger)
            
            Text(message)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.danger)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(AppSpacing.md)
        .background(AppColors.danger.opacity(0.1))
        .cornerRadius(CornerRadius.small)
    }
}

// MARK: - Auth ViewModel (Updated)
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
    
    var isLoading: Bool {
        return authService.isLoading
    }
    
    var errorMessage: String? {
        return formError ?? authService.errorMessage
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

#Preview {
    LoginView()
}