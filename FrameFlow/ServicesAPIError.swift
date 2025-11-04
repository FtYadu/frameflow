//
//  APIError.swift
//  FrameFlow
//
//  Created by LMTD on 04/11/2025.
//

import Foundation

enum APIError: Error, LocalizedError {
    case unauthorized
    case networkError
    case decodingError
    case serverError(String)
    case invalidURL
    case noData
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Session expired. Please login again."
        case .networkError:
            return "Connection failed. Check your internet connection."
        case .decodingError:
            return "Failed to process server response."
        case .serverError(let message):
            return message
        case .invalidURL:
            return "Invalid request URL."
        case .noData:
            return "No data received from server."
        case .unknown:
            return "An unknown error occurred."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .unauthorized:
            return "Try logging in again."
        case .networkError:
            return "Check your internet connection and try again."
        case .decodingError, .serverError:
            return "Please try again or contact support if the problem persists."
        case .invalidURL, .noData, .unknown:
            return "Please try again later."
        }
    }
}

struct APIErrorResponse: Codable {
    let error: String
    let message: String?
    let details: String?
}