//
//  AIProvider.swift
//  FrameFlow
//
//  Created by LMTD on 04/11/2025.
//

import Foundation
import SwiftUI

// MARK: - AI Provider Enum
enum AIProvider: String, CaseIterable {
    case anthropic = "anthropic"
    case openai = "openai" 
    case google = "google"
    case mistral = "mistral"
    case groq = "groq"
    
    var displayName: String {
        switch self {
        case .anthropic: return "Anthropic"
        case .openai: return "OpenAI"
        case .google: return "Google AI"
        case .mistral: return "Mistral AI"
        case .groq: return "Groq"
        }
    }
    
    var icon: String {
        switch self {
        case .anthropic: return "brain"
        case .openai: return "cpu"
        case .google: return "magnifyingglass.circle"
        case .mistral: return "wind"
        case .groq: return "bolt.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .anthropic: return Color(hex: "D4A574")
        case .openai: return Color(hex: "10A37F")
        case .google: return Color(hex: "4285F4")
        case .mistral: return Color(hex: "FF6B6B")
        case .groq: return Color(hex: "F97316")
        }
    }
    
    var baseURL: String {
        switch self {
        case .anthropic: return "https://api.anthropic.com"
        case .openai: return "https://api.openai.com"
        case .google: return "https://generativelanguage.googleapis.com"
        case .mistral: return "https://api.mistral.ai"
        case .groq: return "https://api.groq.com/openai"
        }
    }
    
    var models: [AIModel] {
        switch self {
        case .anthropic:
            return [
                AIModel(id: "claude-3-5-sonnet-20241022", name: "Claude 3.5 Sonnet", costPer1K: 0.003),
                AIModel(id: "claude-3-5-haiku-20241022", name: "Claude 3.5 Haiku", costPer1K: 0.00025),
                AIModel(id: "claude-3-opus-20240229", name: "Claude 3 Opus", costPer1K: 0.015)
            ]
        case .openai:
            return [
                AIModel(id: "gpt-4o", name: "GPT-4o", costPer1K: 0.0025),
                AIModel(id: "gpt-4o-mini", name: "GPT-4o Mini", costPer1K: 0.00015),
                AIModel(id: "gpt-4-turbo", name: "GPT-4 Turbo", costPer1K: 0.01)
            ]
        case .google:
            return [
                AIModel(id: "gemini-1.5-pro-latest", name: "Gemini 1.5 Pro", costPer1K: 0.00125),
                AIModel(id: "gemini-1.5-flash-latest", name: "Gemini 1.5 Flash", costPer1K: 0.000075),
                AIModel(id: "gemini-pro", name: "Gemini Pro", costPer1K: 0.0005)
            ]
        case .mistral:
            return [
                AIModel(id: "mistral-large-latest", name: "Mistral Large", costPer1K: 0.004),
                AIModel(id: "mistral-medium-latest", name: "Mistral Medium", costPer1K: 0.00275),
                AIModel(id: "mistral-small-latest", name: "Mistral Small", costPer1K: 0.002)
            ]
        case .groq:
            return [
                AIModel(id: "llama-3.1-70b-versatile", name: "Llama 3.1 70B", costPer1K: 0.00059),
                AIModel(id: "llama-3.1-8b-instant", name: "Llama 3.1 8B", costPer1K: 0.000059),
                AIModel(id: "mixtral-8x7b-32768", name: "Mixtral 8x7B", costPer1K: 0.00024)
            ]
        }
    }
}

// MARK: - AI Model
struct AIModel: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let costPer1K: Double // Cost per 1K tokens in USD
    
    var costPerMillionTokens: Double {
        return costPer1K * 1000
    }
    
    var formattedCost: String {
        if costPer1K < 0.001 {
            return String(format: "$%.4f/1K", costPer1K)
        } else {
            return String(format: "$%.3f/1K", costPer1K)
        }
    }
}

// MARK: - Agent AI Configuration
struct AgentAIConfig: Codable {
    let agentType: String
    let provider: AIProvider
    let model: AIModel
    let temperature: Double
    let maxTokens: Int
    
    init(agentType: String, provider: AIProvider = .anthropic, model: AIModel? = nil, temperature: Double = 0.7, maxTokens: Int = 1000) {
        self.agentType = agentType
        self.provider = provider
        self.model = model ?? provider.models.first!
        self.temperature = temperature
        self.maxTokens = maxTokens
    }
}

// MARK: - AI Usage Stats
struct AIUsageStats: Codable {
    let provider: AIProvider
    let model: String
    let tokensUsed: Int
    let cost: Double
    let requestCount: Int
    let date: Date
    
    init(provider: AIProvider, model: String, tokensUsed: Int, cost: Double) {
        self.provider = provider
        self.model = model
        self.tokensUsed = tokensUsed
        self.cost = cost
        self.requestCount = 1
        self.date = Date()
    }
}

// MARK: - Monthly Cost Estimate
struct MonthlyCostEstimate {
    let provider: AIProvider
    let model: AIModel
    let estimatedTokensPerMonth: Int
    let estimatedCost: Double
    
    var formattedCost: String {
        if estimatedCost < 1.0 {
            return String(format: "$%.2f", estimatedCost)
        } else {
            return String(format: "$%.0f", estimatedCost)
        }
    }
}