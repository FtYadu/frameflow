//
//  AISettingsView.swift
//  FrameFlow
//
//  Created by LMTD on 04/11/2025.
//

import SwiftUI
import Combine

struct AISettingsView: View {
    @StateObject private var viewModel = AISettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: AppSpacing.lg) {
                        // Header
                        headerSection
                        
                        // API Keys Section
                        apiKeysSection
                        
                        // Agent Model Configuration
                        agentConfigSection
                        
                        // Monthly Cost Estimate
                        costEstimateSection
                        
                        // Usage Statistics
                        usageStatsSection
                    }
                    .padding(.horizontal, AppSpacing.md)
                }
            }
            .navigationTitle("AI Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadSettings()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("AI Configuration")
                .font(AppFonts.title)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Configure your AI providers and manage API keys securely")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(AppSpacing.lg)
        .glassmorphismCard()
    }
    
    // MARK: - API Keys Section
    private var apiKeysSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("API Keys")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Your API keys are stored securely in the iOS Keychain")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textSecondary)
            
            ForEach(AIProvider.allCases, id: \.self) { provider in
                APIKeyRow(
                    provider: provider,
                    hasKey: viewModel.hasAPIKey(for: provider),
                    onSave: { key in
                        await viewModel.saveAPIKey(for: provider, key: key)
                    },
                    onDelete: {
                        await viewModel.deleteAPIKey(for: provider)
                    }
                )
            }
        }
        .padding(AppSpacing.md)
        .glassmorphismCard()
    }
    
    // MARK: - Agent Config Section
    private var agentConfigSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Agent Models")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Choose which AI model each agent should use")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textSecondary)
            
            ForEach(AgentType.allCases, id: \.self) { agentType in
                if let config = viewModel.getAgentConfig(for: agentType) {
                    AgentModelCard(
                        agentType: agentType,
                        config: config,
                        onUpdate: { newConfig in
                            await viewModel.updateAgentConfig(newConfig)
                        }
                    )
                }
            }
        }
        .padding(AppSpacing.md)
        .glassmorphismCard()
    }
    
    // MARK: - Cost Estimate Section
    private var costEstimateSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Monthly Cost Estimate")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)
            
            HStack {
                VStack(alignment: .leading) {
                    Text(viewModel.monthlyEstimate.formattedCost)
                        .font(AppFonts.largeTitle)
                        .foregroundColor(AppColors.warning)
                    
                    Text("Estimated monthly cost")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(viewModel.estimatedTokensPerMonth / 1000)K")
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.primary)
                    
                    Text("tokens/month")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            Text("Based on your current agent configuration and typical usage patterns")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(AppSpacing.md)
        .glassmorphismCard()
    }
    
    // MARK: - Usage Stats Section
    private var usageStatsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("This Month's Usage")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)
            
            if viewModel.monthlyUsage.isEmpty {
                Text("No usage data yet")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.vertical, AppSpacing.lg)
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(viewModel.monthlyUsage, id: \.provider) { usage in
                    UsageStatsRow(usage: usage)
                }
            }
        }
        .padding(AppSpacing.md)
        .glassmorphismCard()
    }
}

// MARK: - API Key Row
struct APIKeyRow: View {
    let provider: AIProvider
    let hasKey: Bool
    let onSave: (String) async -> Void
    let onDelete: () async -> Void
    
    @State private var showingKeyInput = false
    @State private var keyInput = ""
    @State private var isProcessing = false
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Provider icon and name
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: provider.icon)
                    .foregroundColor(provider.color)
                    .font(.title3)
                
                VStack(alignment: .leading) {
                    Text(provider.displayName)
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(hasKey ? "API Key configured" : "No API key")
                        .font(AppFonts.caption)
                        .foregroundColor(hasKey ? AppColors.success : AppColors.textSecondary)
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: AppSpacing.sm) {
                if hasKey {
                    Button("Update") {
                        showingKeyInput = true
                    }
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.primary)
                    
                    Button("Remove") {
                        Task {
                            await onDelete()
                        }
                    }
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.danger)
                } else {
                    Button("Add Key") {
                        showingKeyInput = true
                    }
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.primary)
                }
            }
        }
        .sheet(isPresented: $showingKeyInput) {
            APIKeyInputView(
                provider: provider,
                onSave: { key in
                    await onSave(key)
                }
            )
        }
    }
}

// MARK: - API Key Input View
struct APIKeyInputView: View {
    let provider: AIProvider
    let onSave: (String) async -> Void
    
    @State private var apiKey = ""
    @State private var isProcessing = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                VStack(spacing: AppSpacing.lg) {
                    // Header
                    VStack(spacing: AppSpacing.md) {
                        Image(systemName: provider.icon)
                            .font(.system(size: 40))
                            .foregroundColor(provider.color)
                        
                        Text("Add \(provider.displayName) API Key")
                            .font(AppFonts.title)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("Your API key will be stored securely in the iOS Keychain")
                            .font(AppFonts.body)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Key input
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("API Key")
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.textSecondary)
                        
                        SecureField("Enter your API key", text: $apiKey)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    
                    Spacer()
                    
                    // Save button
                    Button("Save API Key") {
                        Task {
                            isProcessing = true
                            await onSave(apiKey)
                            isProcessing = false
                            dismiss()
                        }
                    }
                    .primaryButton()
                    .disabled(apiKey.isEmpty || isProcessing)
                }
                .padding(AppSpacing.lg)
            }
            .navigationTitle("API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Agent Model Card
struct AgentModelCard: View {
    let agentType: AgentType
    let config: AgentAIConfig
    let onUpdate: (AgentAIConfig) async -> Void
    
    @State private var selectedProvider: AIProvider
    @State private var selectedModel: AIModel
    @State private var temperature: Double
    @State private var showingModelPicker = false
    
    init(agentType: AgentType, config: AgentAIConfig, onUpdate: @escaping (AgentAIConfig) async -> Void) {
        self.agentType = agentType
        self.config = config
        self.onUpdate = onUpdate
        self._selectedProvider = State(initialValue: config.provider)
        self._selectedModel = State(initialValue: config.model)
        self._temperature = State(initialValue: config.temperature)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: agentType.icon)
                    .foregroundColor(agentType.gradientColors.first)
                    .font(.title3)
                
                Text(agentType.displayName)
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Button("Configure") {
                    showingModelPicker = true
                }
                .font(AppFonts.caption)
                .foregroundColor(AppColors.primary)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text(selectedProvider.displayName)
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(selectedModel.name)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                Text(selectedModel.formattedCost)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.warning)
            }
        }
        .padding(AppSpacing.sm)
        .background(AppColors.surface.opacity(0.5))
        .cornerRadius(CornerRadius.small)
        .sheet(isPresented: $showingModelPicker) {
            ModelPickerView(
                selectedProvider: $selectedProvider,
                selectedModel: $selectedModel,
                temperature: $temperature,
                onSave: {
                    let newConfig = AgentAIConfig(
                        agentType: agentType.rawValue,
                        provider: selectedProvider,
                        model: selectedModel,
                        temperature: temperature
                    )
                    Task {
                        await onUpdate(newConfig)
                    }
                }
            )
        }
    }
}

// MARK: - Model Picker View
struct ModelPickerView: View {
    @Binding var selectedProvider: AIProvider
    @Binding var selectedModel: AIModel
    @Binding var temperature: Double
    let onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                VStack(spacing: AppSpacing.lg) {
                    // Provider Selection
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("AI Provider")
                            .font(AppFonts.headline)
                            .foregroundColor(AppColors.textPrimary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: AppSpacing.sm) {
                            ForEach(AIProvider.allCases, id: \.self) { provider in
                                ProviderCard(
                                    provider: provider,
                                    isSelected: selectedProvider == provider,
                                    onSelect: {
                                        selectedProvider = provider
                                        selectedModel = provider.models.first ?? AIModel(id: "claude-3-5-sonnet-20241022", name: "Claude 3.5 Sonnet", costPer1K: 0.003)
                                    }
                                )
                            }
                        }
                    }
                    
                    // Model Selection
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Model")
                            .font(AppFonts.headline)
                            .foregroundColor(AppColors.textPrimary)
                        
                        ForEach(selectedProvider.models, id: \.id) { model in
                            ModelRow(
                                model: model,
                                isSelected: selectedModel.id == model.id,
                                onSelect: {
                                    selectedModel = model
                                }
                            )
                        }
                    }
                    
                    // Temperature Setting
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        HStack {
                            Text("Creativity")
                                .font(AppFonts.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Spacer()
                            
                            Text(String(format: "%.1f", temperature))
                                .font(AppFonts.body)
                                .foregroundColor(AppColors.primary)
                        }
                        
                        Slider(value: $temperature, in: 0...1, step: 0.1)
                            .accentColor(AppColors.primary)
                    }
                    
                    Spacer()
                    
                    Button("Save Configuration") {
                        onSave()
                        dismiss()
                    }
                    .primaryButton()
                }
                .padding(AppSpacing.lg)
            }
            .navigationTitle("Model Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Provider Card
struct ProviderCard: View {
    let provider: AIProvider
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: provider.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? provider.color : AppColors.textSecondary)
                
                Text(provider.displayName)
                    .font(AppFonts.caption)
                    .foregroundColor(isSelected ? AppColors.textPrimary : AppColors.textSecondary)
            }
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(
                isSelected ? 
                provider.color.opacity(0.1) :
                AppColors.surface.opacity(0.5)
            )
            .cornerRadius(CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .stroke(
                        isSelected ? provider.color : AppColors.divider,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Model Row
struct ModelRow: View {
    let model: AIModel
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading) {
                    Text(model.name)
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("ID: \(model.id)")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                Text(model.formattedCost)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.warning)
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppColors.success)
                }
            }
            .padding(AppSpacing.sm)
            .background(isSelected ? AppColors.primary.opacity(0.1) : Color.clear)
            .cornerRadius(CornerRadius.small)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Usage Stats Row
struct UsageStatsRow: View {
    let usage: AIUsageStats
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(usage.provider.displayName)
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(usage.model)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(String(format: "$%.2f", usage.cost))
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.warning)
                
                Text("\(usage.tokensUsed) tokens")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
}

// MARK: - Custom Text Field Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .foregroundColor(AppColors.textPrimary)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.md)
            .background(AppColors.surface)
            .cornerRadius(CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .stroke(AppColors.divider, lineWidth: 1)
            )
    }
}

// MARK: - AI Settings ViewModel
@MainActor
class AISettingsViewModel: ObservableObject {
    @Published var apiKeys: [AIProvider: String] = [:]
    @Published var agentConfigs: [String: AgentAIConfig] = [:]
    @Published var monthlyUsage: [AIUsageStats] = []
    @Published var monthlyEstimate: MonthlyCostEstimate = MonthlyCostEstimate(
        provider: .anthropic,
        model: AIModel(id: "claude-3-5-sonnet-20241022", name: "Claude 3.5 Sonnet", costPer1K: 0.003),
        estimatedTokensPerMonth: 50000,
        estimatedCost: 150.0
    )
    @Published var loadingState: LoadingState = .idle
    
    private let keychain = KeychainService.shared
    
    var estimatedTokensPerMonth: Int {
        return agentConfigs.values.reduce(0) { total, config in
            // Estimate tokens per month based on agent type
            let baseTokens: Int
            switch AgentType(rawValue: config.agentType) {
            case .scout: baseTokens = 20000 // Lead finding uses more tokens
            case .marketing: baseTokens = 10000 // Caption generation
            default: baseTokens = 5000
            }
            return total + baseTokens
        }
    }
    
    // MARK: - Data Loading
    func loadSettings() async {
        loadingState = .loading
        
        // Load API keys
        apiKeys = keychain.getAllAPIKeys()
        
        // Load agent configurations with defaults
        for agentType in AgentType.allCases {
            if let config = keychain.getAgentConfig(for: agentType.rawValue) {
                agentConfigs[agentType.rawValue] = config
            } else {
                // Set default configuration
                let defaultConfig = AgentAIConfig(agentType: agentType.rawValue)
                agentConfigs[agentType.rawValue] = defaultConfig
                _ = keychain.saveAgentConfig(defaultConfig)
            }
        }
        
        // Calculate monthly estimate
        updateCostEstimate()
        
        loadingState = .success
    }
    
    // MARK: - API Key Management
    func hasAPIKey(for provider: AIProvider) -> Bool {
        return apiKeys[provider] != nil
    }
    
    func saveAPIKey(for provider: AIProvider, key: String) async {
        if keychain.saveAPIKey(for: provider, key: key) {
            apiKeys[provider] = key
            HapticManager.notification(.success)
        } else {
            HapticManager.notification(.error)
        }
    }
    
    func deleteAPIKey(for provider: AIProvider) async {
        if keychain.deleteAPIKey(for: provider) {
            apiKeys.removeValue(forKey: provider)
            HapticManager.notification(.success)
        } else {
            HapticManager.notification(.error)
        }
    }
    
    // MARK: - Agent Configuration
    func getAgentConfig(for agentType: AgentType) -> AgentAIConfig? {
        return agentConfigs[agentType.rawValue]
    }
    
    func updateAgentConfig(_ config: AgentAIConfig) async {
        if keychain.saveAgentConfig(config) {
            agentConfigs[config.agentType] = config
            updateCostEstimate()
            HapticManager.notification(.success)
        } else {
            HapticManager.notification(.error)
        }
    }
    
    // MARK: - Cost Estimation
    private func updateCostEstimate() {
        var totalCost = 0.0
        let totalTokens = estimatedTokensPerMonth
        
        for config in agentConfigs.values {
            let agentTokens = totalTokens / agentConfigs.count
            let cost = (Double(agentTokens) / 1000.0) * config.model.costPer1K
            totalCost += cost
        }
        
        // Use the most common provider/model for display
        let commonProvider = agentConfigs.values.first?.provider ?? .anthropic
        let commonModel = agentConfigs.values.first?.model ?? (commonProvider.models.first ?? AIModel(id: "claude-3-5-sonnet-20241022", name: "Claude 3.5 Sonnet", costPer1K: 0.003))
        
        monthlyEstimate = MonthlyCostEstimate(
            provider: commonProvider,
            model: commonModel,
            estimatedTokensPerMonth: totalTokens,
            estimatedCost: totalCost
        )
    }
}

#Preview {
    AISettingsView()
}