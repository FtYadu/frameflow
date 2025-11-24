//
//  PostComposerView.swift
//  FrameFlow
//
//  Created by LMTD on 04/11/2025.
//

import SwiftUI
import PhotosUI

struct PostComposerView: View {
    @StateObject private var viewModel = PostViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingGenerateOptions = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        // Image picker
                        imageSection
                        
                        // Caption section
                        captionSection
                        
                        // Hashtags section
                        hashtagsSection
                        
                        // Scheduling section
                        schedulingSection
                        
                        // Action buttons
                        actionButtons
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, AppSpacing.md)
                }
            }
            .navigationTitle("Create Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save Draft") {
                        Task {
                            await viewModel.createPost()
                            dismiss()
                        }
                    }
                    .disabled(viewModel.caption.isEmpty && viewModel.imageURL == nil)
                }
            }
            .sheet(isPresented: $showingGenerateOptions) {
                CaptionGeneratorView { topic, brandVoice, targetAudience in
                    await viewModel.generateCaption(
                        topic: topic,
                        brandVoice: brandVoice,
                        targetAudience: targetAudience
                    )
                }
            }
        }
    }
    
    // MARK: - Image Section
    private var imageSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Photo")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)
            
            PhotosPicker(
                selection: $viewModel.selectedImage,
                matching: .images,
                photoLibrary: .shared()
            ) {
                if let imageURL = viewModel.imageURL {
                    // Show selected image placeholder
                    ZStack {
                        RoundedRectangle(cornerRadius: CornerRadius.medium)
                            .fill(AppColors.surface)
                            .frame(height: 200)
                        
                        VStack(spacing: AppSpacing.sm) {
                            Image(systemName: "photo.fill")
                                .font(.largeTitle)
                                .foregroundColor(AppColors.success)
                            
                            Text("Image Selected")
                                .font(AppFonts.body)
                                .foregroundColor(AppColors.success)
                            
                            Text("Tap to change")
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                } else {
                    // Show placeholder
                    ZStack {
                        RoundedRectangle(cornerRadius: CornerRadius.medium)
                            .fill(AppColors.surface)
                            .frame(height: 200)
                            .overlay(
                                RoundedRectangle(cornerRadius: CornerRadius.medium)
                                    .stroke(AppColors.divider, style: StrokeStyle(lineWidth: 2, dash: [8]))
                            )
                        
                        VStack(spacing: AppSpacing.sm) {
                            Image(systemName: "photo.badge.plus")
                                .font(.largeTitle)
                                .foregroundColor(AppColors.textSecondary)
                            
                            Text("Select Photo")
                                .font(AppFonts.body)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                }
            }
            .onChange(of: viewModel.selectedImage) { _ in
                Task {
                    await viewModel.processSelectedImage()
                }
            }
        }
    }
    
    // MARK: - Caption Section
    private var captionSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Caption")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Button(action: {
                    showingGenerateOptions = true
                }) {
                    HStack(spacing: AppSpacing.xs) {
                        if viewModel.isGeneratingCaption {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "wand.and.stars")
                                .font(.caption)
                        }
                        
                        Text("AI Generate")
                            .font(AppFonts.caption)
                    }
                    .foregroundColor(AppColors.primary)
                }
                .disabled(viewModel.isGeneratingCaption)
            }
            
            TextEditor(text: $viewModel.caption)
                .frame(minHeight: 120)
                .padding(AppSpacing.sm)
                .background(AppColors.surface)
                .cornerRadius(CornerRadius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.medium)
                        .stroke(AppColors.divider, lineWidth: 1)
                )
                .foregroundColor(AppColors.textPrimary)
        }
    }
    
    // MARK: - Hashtags Section
    private var hashtagsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Hashtags")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)
            
            TextEditor(text: $viewModel.hashtags)
                .frame(minHeight: 80)
                .padding(AppSpacing.sm)
                .background(AppColors.surface)
                .cornerRadius(CornerRadius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.medium)
                        .stroke(AppColors.divider, lineWidth: 1)
                )
                .foregroundColor(AppColors.textPrimary)
            
            Text("Separate hashtags with spaces. # will be added automatically.")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textSecondary)
        }
    }
    
    // MARK: - Scheduling Section
    private var schedulingSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Schedule")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Toggle("", isOn: $viewModel.shouldSchedule)
                    .toggleStyle(SwitchToggleStyle(tint: AppColors.primary))
            }
            
            if viewModel.shouldSchedule {
                DatePicker(
                    "Post Date & Time",
                    selection: $viewModel.scheduledDate,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(CompactDatePickerStyle())
                .accentColor(AppColors.primary)
            }
        }
        .padding(AppSpacing.md)
        .cardStyle()
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: AppSpacing.md) {
            Button(action: {
                Task {
                    await viewModel.createPost()
                    dismiss()
                }
            }) {
                HStack {
                    if viewModel.isCreatingPost {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    
                    Text(viewModel.shouldSchedule ? "Schedule Post" : "Save Draft")
                        .font(AppFonts.headline)
                }
                .frame(maxWidth: .infinity)
            }
            .primaryButton()
            .disabled(
                viewModel.isCreatingPost || 
                (viewModel.caption.isEmpty && viewModel.imageURL == nil)
            )
        }
    }
}

// MARK: - Caption Generator View
struct CaptionGeneratorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var topic = ""
    @State private var brandVoice = ""
    @State private var targetAudience = ""
    
    let onGenerate: (String?, String?, String?) async -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                VStack(spacing: AppSpacing.lg) {
                    Text("AI Caption Generator")
                        .font(AppFonts.title)
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.top, AppSpacing.lg)
                    
                    VStack(spacing: AppSpacing.lg) {
                        CustomTextField(
                            title: "Topic (Optional)",
                            text: $topic,
                            placeholder: "Wedding shoot, portrait session, etc."
                        )
                        
                        CustomTextField(
                            title: "Brand Voice (Optional)",
                            text: $brandVoice,
                            placeholder: "Professional, casual, artistic, etc."
                        )
                        
                        CustomTextField(
                            title: "Target Audience (Optional)",
                            text: $targetAudience,
                            placeholder: "Brides, business owners, artists, etc."
                        )
                    }
                    
                    Spacer()
                    
                    Button("Generate Caption") {
                        Task {
                            await onGenerate(
                                topic.isEmpty ? nil : topic,
                                brandVoice.isEmpty ? nil : brandVoice,
                                targetAudience.isEmpty ? nil : targetAudience
                            )
                            dismiss()
                        }
                    }
                    .primaryButton()
                }
                .padding(.horizontal, AppSpacing.lg)
            }
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

// MARK: - Posts List View
struct PostsListView: View {
    @StateObject private var viewModel = PostViewModel()
    @State private var showingComposer = false

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search Bar
                    searchBar

                    // Filter tabs
                    filterTabs

                    // Posts list
                    postsList
                }
            }
            .navigationTitle("Posts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingComposer = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .task {
                await viewModel.loadPosts()
            }
            .refreshable {
                await viewModel.refreshPosts()
            }
            .sheet(isPresented: $showingComposer) {
                PostComposerView()
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.textSecondary)

            TextField("Search posts...", text: $viewModel.searchText)
                .foregroundColor(AppColors.textPrimary)

            if !viewModel.searchText.isEmpty {
                Button(action: {
                    viewModel.searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .cornerRadius(CornerRadius.medium)
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.xs)
    }

    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                FilterChip(
                    title: "All",
                    isSelected: viewModel.filterStatus == nil,
                    onTap: { viewModel.filterStatus = nil }
                )

                ForEach(PostStatus.allCases, id: \.self) { status in
                    FilterChip(
                        title: status.displayName,
                        isSelected: viewModel.filterStatus == status,
                        onTap: { viewModel.filterStatus = status }
                    )
                }
            }
            .padding(.horizontal, AppSpacing.md)
        }
        .padding(.bottom, AppSpacing.sm)
    }
    
    private var postsList: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filteredPosts.isEmpty {
                EmptyStateView(
                    icon: "square.and.pencil",
                    title: "No Posts",
                    message: searchText.isEmpty ? "Create your first post to get started" : "No posts match your search"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: AppSpacing.sm) {
                        ForEach(viewModel.filteredPosts) { post in
                            PostRowView(post: post)
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                }
            }
        }
    }

    private var searchText: String {
        return viewModel.searchText
    }
}

// MARK: - Post Row View
struct PostRowView: View {
    let post: Post
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text(post.caption?.truncated(to: 50) ?? "No caption")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(2)

                Spacer()

                PostStatusBadge(status: post.postStatus ?? .draft)
            }
            
            if !post.hashtags.isEmpty {
                Text(post.hashtagString.truncated(to: 100))
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.primary)
                    .lineLimit(1)
            }
            
            HStack {
                Text(post.platform.capitalized)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary)
                
                Spacer()
                
                if let scheduledFor = post.scheduledFor {
                    Text("Scheduled: \(scheduledFor.timeAgo())")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.warning)
                } else {
                    Text(post.createdAt.timeAgo())
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .padding(AppSpacing.md)
        .cardStyle()
    }
}

// MARK: - Post Status Badge
struct PostStatusBadge: View {
    let status: PostStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption2)
            .foregroundColor(.white)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, 2)
            .background(status.color)
            .cornerRadius(8)
    }
}

#Preview {
    PostComposerView()
}