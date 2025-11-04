//
//  PostViewModel.swift
//  FrameFlow
//
//  Created by LMTD on 04/11/2025.
//

import Foundation
import Combine
import PhotosUI
import SwiftUI

@MainActor
class PostViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var selectedPost: Post?
    @Published var loadingState: LoadingState = .idle
    @Published var isCreatingPost = false
    @Published var isGeneratingCaption = false
    
    // Post creation form
    @Published var caption = ""
    @Published var hashtags = ""
    @Published var selectedImage: PhotosPickerItem?
    @Published var imageURL: String?
    @Published var scheduledDate: Date = Date().addingTimeInterval(3600) // 1 hour from now
    @Published var shouldSchedule = false
    
    private let apiService = APIService.shared
    
    // MARK: - Computed Properties
    var draftPosts: [Post] {
        return posts.filter { $0.postStatus == .draft }
    }
    
    var scheduledPosts: [Post] {
        return posts.filter { $0.postStatus == .scheduled }
    }
    
    var publishedPosts: [Post] {
        return posts.filter { $0.postStatus == .published }
    }
    
    var isLoading: Bool {
        return loadingState.isLoading
    }
    
    var errorMessage: String? {
        if case .failure(let error) = loadingState {
            return error.localizedDescription
        }
        return nil
    }
    
    var hashtagsArray: [String] {
        return hashtags
            .components(separatedBy: CharacterSet.whitespacesAndNewlines)
            .compactMap { tag in
                let cleaned = tag.trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "#", with: "")
                return cleaned.isEmpty ? nil : cleaned
            }
    }
    
    // MARK: - Data Loading
    func loadPosts() async {
        loadingState = .loading
        
        do {
            posts = try await apiService.fetchPosts()
            loadingState = .success
        } catch {
            loadingState = .failure(error)
            print("Error loading posts: \(error)")
        }
    }
    
    func refreshPosts() async {
        await loadPosts()
    }
    
    // MARK: - Post Creation
    func createPost() async {
        guard !caption.isEmpty || imageURL != nil else { return }
        
        isCreatingPost = true
        
        do {
            let newPost = try await apiService.createPost(
                caption: caption.isEmpty ? nil : caption,
                imageUrl: imageURL,
                hashtags: hashtagsArray,
                platform: "instagram",
                scheduledFor: shouldSchedule ? scheduledDate : nil
            )
            
            posts.insert(newPost, at: 0)
            clearForm()
            
            HapticManager.notification(.success)
            
        } catch {
            print("Error creating post: \(error)")
            HapticManager.notification(.error)
        }
        
        isCreatingPost = false
    }
    
    func generateCaption(topic: String? = nil, brandVoice: String? = nil, targetAudience: String? = nil) async {
        isGeneratingCaption = true
        
        do {
            let response = try await apiService.generateCaption(
                imageUrl: imageURL,
                topic: topic,
                brandVoice: brandVoice,
                targetAudience: targetAudience
            )
            
            caption = response.caption
            hashtags = response.hashtags.map { "#\($0)" }.joined(separator: " ")
            
            HapticManager.notification(.success)
            
        } catch {
            print("Error generating caption: \(error)")
            HapticManager.notification(.error)
        }
        
        isGeneratingCaption = false
    }
    
    // MARK: - Post Actions
    func updatePost(_ post: Post, caption: String? = nil, hashtags: [String]? = nil, scheduledFor: Date? = nil) async {
        do {
            let updatedPost = try await apiService.updatePost(
                id: post.id,
                caption: caption,
                hashtags: hashtags,
                scheduledFor: scheduledFor
            )
            
            if let index = posts.firstIndex(where: { $0.id == post.id }) {
                posts[index] = updatedPost
            }
            
            HapticManager.impact(.medium)
            
        } catch {
            print("Error updating post: \(error)")
            HapticManager.notification(.error)
        }
    }
    
    func deletePost(_ post: Post) async {
        do {
            try await apiService.deletePost(id: post.id)
            
            posts.removeAll { $0.id == post.id }
            
            HapticManager.impact(.light)
            
        } catch {
            print("Error deleting post: \(error)")
            HapticManager.notification(.error)
        }
    }
    
    func schedulePost(_ post: Post, for date: Date) async {
        do {
            let updatedPost = try await apiService.schedulePost(id: post.id, scheduledFor: date)
            
            if let index = posts.firstIndex(where: { $0.id == post.id }) {
                posts[index] = updatedPost
            }
            
            HapticManager.notification(.success)
            
        } catch {
            print("Error scheduling post: \(error)")
            HapticManager.notification(.error)
        }
    }
    
    // MARK: - Form Management
    func clearForm() {
        caption = ""
        hashtags = ""
        selectedImage = nil
        imageURL = nil
        shouldSchedule = false
        scheduledDate = Date().addingTimeInterval(3600)
    }
    
    func selectPost(_ post: Post) {
        selectedPost = post
        caption = post.caption ?? ""
        hashtags = post.hashtagString
        imageURL = post.imageUrl
    }
    
    func clearSelection() {
        selectedPost = nil
        clearForm()
    }
    
    // MARK: - Image Processing
    func processSelectedImage() async {
        guard let selectedImage = selectedImage else { return }
        
        do {
            // In a real app, you would upload the image to your server/S3 and get back a URL
            // For now, we'll simulate this with a placeholder URL
            let imageData = try await selectedImage.loadTransferable(type: Data.self)
            
            if imageData != nil {
                // Simulate image upload - in real app, upload to S3 or similar
                imageURL = "https://placeholder.image.url/\(UUID().uuidString).jpg"
            }
            
        } catch {
            print("Error processing image: \(error)")
        }
    }
}