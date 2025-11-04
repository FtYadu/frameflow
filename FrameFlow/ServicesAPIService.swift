//
//  APIService.swift
//  FrameFlow
//
//  Created by LMTD on 04/11/2025.
//

import Foundation
import Combine

class APIService: ObservableObject {
    static let shared = APIService()
    
    private let session = URLSession.shared
    private let baseURL = Config.apiBaseURL
    private let keychain = KeychainService.shared
    
    private init() {}
    
    // MARK: - Generic Request Method
    private func makeRequest<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Codable? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authorization header if required
        if requiresAuth {
            guard let token = keychain.getAuthToken() else {
                throw APIError.unauthorized
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add request body if provided
        if let body = body {
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                request.httpBody = try encoder.encode(body)
            } catch {
                throw APIError.decodingError
            }
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError
            }
            
            // Handle different status codes
            switch httpResponse.statusCode {
            case 200...299:
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                do {
                    return try decoder.decode(T.self, from: data)
                } catch {
                    print("Decoding error: \(error)")
                    print("Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
                    throw APIError.decodingError
                }
                
            case 401:
                // Try to refresh token
                if requiresAuth, await refreshAuthToken() {
                    // Retry the request with new token
                    return try await makeRequest(endpoint: endpoint, method: method, body: body, requiresAuth: requiresAuth)
                } else {
                    throw APIError.unauthorized
                }
                
            case 400...499:
                let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data)
                throw APIError.serverError(errorResponse?.message ?? "Client error")
                
            case 500...599:
                let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data)
                throw APIError.serverError(errorResponse?.message ?? "Server error")
                
            default:
                throw APIError.unknown
            }
            
        } catch {
            if error is APIError {
                throw error
            } else {
                throw APIError.networkError
            }
        }
    }
    
    // MARK: - Token Refresh
    private func refreshAuthToken() async -> Bool {
        guard let refreshToken = keychain.getRefreshToken() else {
            return false
        }
        
        do {
            let request = RefreshTokenRequest(refreshToken: refreshToken)
            let response: AuthResponse = try await makeRequest(
                endpoint: "/auth/refresh",
                method: .POST,
                body: request,
                requiresAuth: false
            )
            
            _ = keychain.saveAuthToken(response.accessToken)
            _ = keychain.saveRefreshToken(response.refreshToken)
            
            return true
        } catch {
            keychain.clearTokens()
            return false
        }
    }
    
    // MARK: - AI Provider Integration
    func callAIProvider(
        provider: AIProvider,
        model: AIModel,
        prompt: String,
        temperature: Double = 0.7,
        maxTokens: Int = 1000
    ) async throws -> AIResponse {
        guard let apiKey = keychain.getAPIKey(for: provider) else {
            throw APIError.serverError("No API key found for \(provider.displayName)")
        }
        
        let request = AIRequest(
            provider: provider,
            model: model,
            prompt: prompt,
            temperature: temperature,
            maxTokens: maxTokens,
            apiKey: apiKey
        )
        
        return try await makeRequest(
            endpoint: "/ai/generate",
            method: .POST,
            body: request
        )
    }
}

// MARK: - HTTP Methods
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case PATCH = "PATCH"
    case DELETE = "DELETE"
}

// MARK: - Authentication Methods
extension APIService {
    func login(email: String, password: String) async throws -> AuthResponse {
        let request = LoginRequest(email: email, password: password)
        let response: AuthResponse = try await makeRequest(
            endpoint: "/auth/login",
            method: .POST,
            body: request,
            requiresAuth: false
        )
        
        // Save tokens to keychain
        _ = keychain.saveAuthToken(response.accessToken)
        _ = keychain.saveRefreshToken(response.refreshToken)
        
        return response
    }
    
    func signUp(email: String, password: String, fullName: String, instagramHandle: String? = nil, niche: String? = nil) async throws -> AuthResponse {
        let request = SignUpRequest(
            email: email,
            password: password,
            fullName: fullName,
            instagramHandle: instagramHandle,
            niche: niche
        )
        
        let response: AuthResponse = try await makeRequest(
            endpoint: "/auth/signup",
            method: .POST,
            body: request,
            requiresAuth: false
        )
        
        // Save tokens to keychain
        _ = keychain.saveAuthToken(response.accessToken)
        _ = keychain.saveRefreshToken(response.refreshToken)
        
        return response
    }
    
    func getCurrentUser() async throws -> User {
        return try await makeRequest(endpoint: "/auth/me")
    }
    
    func logout() {
        keychain.clearTokens()
    }
}

// MARK: - Agent Methods
extension APIService {
    func fetchAgents() async throws -> [Agent] {
        return try await makeRequest(endpoint: "/agents")
    }
    
    func fetchAgent(type: String) async throws -> Agent {
        return try await makeRequest(endpoint: "/agents/\(type)")
    }
    
    func toggleAgent(type: String, isActive: Bool) async throws -> Agent {
        let request = AgentStatusUpdate(isActive: isActive)
        return try await makeRequest(
            endpoint: "/agents/\(type)/toggle",
            method: .PATCH,
            body: request
        )
    }
    
    func triggerAgent(type: String, action: String, parameters: [String: String]? = nil) async throws {
        let request = AgentTriggerRequest(action: action, parameters: parameters)
        let _: EmptyResponse = try await makeRequest(
            endpoint: "/agents/\(type)/trigger",
            method: .POST,
            body: request
        )
    }
    
    func fetchAgentTasks(type: String) async throws -> [AgentTask] {
        return try await makeRequest(endpoint: "/agents/\(type)/tasks")
    }
    
    func fetchAgentBrief(type: String) async throws -> AgentBrief? {
        return try await makeRequest(endpoint: "/agents/briefs/\(type)")
    }
}

// MARK: - Task Methods
extension APIService {
    func fetchTasks() async throws -> [AgentTask] {
        return try await makeRequest(endpoint: "/tasks")
    }
    
    func fetchTask(id: String) async throws -> AgentTask {
        return try await makeRequest(endpoint: "/tasks/\(id)")
    }
    
    func approveTask(id: String, approved: Bool, feedback: String? = nil) async throws -> AgentTask {
        let request = TaskApprovalRequest(approved: approved, feedback: feedback)
        return try await makeRequest(
            endpoint: "/tasks/\(id)/approve",
            method: .PATCH,
            body: request
        )
    }
    
    func deleteTask(id: String) async throws {
        let _: EmptyResponse = try await makeRequest(
            endpoint: "/tasks/\(id)",
            method: .DELETE
        )
    }
}

// MARK: - Lead Methods
extension APIService {
    func fetchLeads() async throws -> [Lead] {
        return try await makeRequest(endpoint: "/leads")
    }
    
    func fetchLead(id: String) async throws -> Lead {
        return try await makeRequest(endpoint: "/leads/\(id)")
    }
    
    func updateLeadStatus(id: String, status: String, notes: String? = nil) async throws -> Lead {
        let request = LeadStatusUpdate(status: status, notes: notes)
        return try await makeRequest(
            endpoint: "/leads/\(id)",
            method: .PATCH,
            body: request
        )
    }
    
    func sendOutreach(leadId: String, message: String, platform: String) async throws {
        let request = OutreachRequest(message: message, platform: platform)
        let _: EmptyResponse = try await makeRequest(
            endpoint: "/leads/\(leadId)/outreach",
            method: .POST,
            body: request
        )
    }
}

// MARK: - Post Methods
extension APIService {
    func fetchPosts() async throws -> [Post] {
        return try await makeRequest(endpoint: "/posts")
    }
    
    func createPost(caption: String?, imageUrl: String?, hashtags: [String], platform: String = "instagram", scheduledFor: Date? = nil) async throws -> Post {
        let request = CreatePostRequest(
            caption: caption,
            imageUrl: imageUrl,
            hashtags: hashtags,
            platform: platform,
            scheduledFor: scheduledFor
        )
        return try await makeRequest(
            endpoint: "/posts",
            method: .POST,
            body: request
        )
    }
    
    func updatePost(id: String, caption: String? = nil, hashtags: [String]? = nil, scheduledFor: Date? = nil, status: String? = nil) async throws -> Post {
        let request = UpdatePostRequest(
            caption: caption,
            hashtags: hashtags,
            scheduledFor: scheduledFor,
            status: status
        )
        return try await makeRequest(
            endpoint: "/posts/\(id)",
            method: .PATCH,
            body: request
        )
    }
    
    func deletePost(id: String) async throws {
        let _: EmptyResponse = try await makeRequest(
            endpoint: "/posts/\(id)",
            method: .DELETE
        )
    }
    
    func schedulePost(id: String, scheduledFor: Date) async throws -> Post {
        return try await makeRequest(
            endpoint: "/posts/\(id)/schedule",
            method: .POST,
            body: ["scheduled_for": scheduledFor]
        )
    }
    
    func generateCaption(imageUrl: String? = nil, topic: String? = nil, brandVoice: String? = nil, targetAudience: String? = nil) async throws -> GenerateCaptionResponse {
        let request = GenerateCaptionRequest(
            imageUrl: imageUrl,
            topic: topic,
            brandVoice: brandVoice,
            targetAudience: targetAudience
        )
        return try await makeRequest(
            endpoint: "/posts/generate-caption",
            method: .POST,
            body: request
        )
    }
}

// MARK: - Notification Methods
extension APIService {
    func fetchNotifications() async throws -> [AppNotification] {
        return try await makeRequest(endpoint: "/notifications")
    }
    
    func markNotificationAsRead(id: String) async throws -> AppNotification {
        let request = MarkNotificationReadRequest()
        return try await makeRequest(
            endpoint: "/notifications/\(id)/read",
            method: .PATCH,
            body: request
        )
    }
}

// MARK: - Helper Types
struct EmptyResponse: Codable {}

// MARK: - AI Integration Models
struct AIRequest: Codable {
    let provider: AIProvider
    let model: AIModel
    let prompt: String
    let temperature: Double
    let maxTokens: Int
    let apiKey: String
    
    enum CodingKeys: String, CodingKey {
        case provider, model, prompt, temperature
        case maxTokens = "max_tokens"
        case apiKey = "api_key"
    }
}

struct AIResponse: Codable {
    let response: String
    let tokensUsed: Int
    let cost: Double
    let provider: AIProvider
    let model: String
    
    enum CodingKeys: String, CodingKey {
        case response
        case tokensUsed = "tokens_used"
        case cost, provider, model
    }
}