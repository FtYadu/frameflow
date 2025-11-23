//
//  LeadsListView.swift
//  FrameFlow
//
//  Created by LMTD on 04/11/2025.
//

import SwiftUI

struct LeadsListView: View {
    @StateObject private var viewModel = LeadViewModel()
    @State private var showingLeadDetail = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Stats Header
                    statsHeader

                    // Search Bar
                    searchBar

                    // Filter Chips
                    filterSection

                    // Leads List
                    leadsList
                }
            }
            .navigationTitle("Leads")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.loadLeads()
            }
            .refreshable {
                await viewModel.refreshLeads()
            }
            .sheet(item: $viewModel.selectedLead) { lead in
                LeadDetailView(lead: lead) {
                    viewModel.clearSelection()
                }
            }
        }
    }
    
    // MARK: - Stats Header
    private var statsHeader: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: AppSpacing.sm) {
            StatItem(title: "Total", value: "\(viewModel.totalLeads)", color: AppColors.primary)
            StatItem(title: "New", value: "\(viewModel.newLeads)", color: AppColors.warning)
            StatItem(title: "Contacted", value: "\(viewModel.contactedLeads)", color: AppColors.success)
            StatItem(title: "Converted", value: "\(viewModel.convertedLeads)", color: AppColors.secondary)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.textSecondary)

            TextField("Search leads...", text: $viewModel.searchText)
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

    // MARK: - Filter Section
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                FilterChip(
                    title: "All",
                    isSelected: viewModel.filterStatus == nil,
                    onTap: { viewModel.filterStatus = nil }
                )

                ForEach(LeadStatus.allCases, id: \.self) { status in
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
    
    // MARK: - Leads List
    private var leadsList: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.filteredLeads.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: AppSpacing.sm) {
                        ForEach(viewModel.filteredLeads) { lead in
                            LeadRowView(
                                lead: lead,
                                onTap: {
                                    viewModel.selectLead(lead)
                                },
                                onStatusUpdate: { status in
                                    await viewModel.updateLeadStatus(lead, status: status)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                }
            }
        }
        .onChange(of: selectedFilter) { _ in
            viewModel.filterStatus = selectedFilter
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: AppSpacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                .scaleEffect(1.5)
            
            Text("Loading leads...")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        EmptyStateView(
            icon: "person.crop.circle.badge.plus",
            title: "No Leads Yet",
            message: selectedFilter == nil ? 
                "Your Scout Agent will find potential clients automatically" :
                "No leads with \(selectedFilter?.displayName.lowercased() ?? "") status"
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Text(value)
                .font(AppFonts.headline)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.vertical, AppSpacing.sm)
        .frame(maxWidth: .infinity)
        .background(AppColors.surface)
        .cornerRadius(CornerRadius.small)
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(AppFonts.caption)
                .foregroundColor(isSelected ? .white : AppColors.textSecondary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background(isSelected ? AppColors.primary : AppColors.surface)
                .cornerRadius(16)
        }
    }
}

// MARK: - Lead Row View
struct LeadRowView: View {
    let lead: Lead
    let onTap: () -> Void
    let onStatusUpdate: (LeadStatus) async -> Void
    
    @State private var showingStatusPicker = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.md) {
                // Lead icon and score
                VStack {
                    ZStack {
                        Circle()
                            .fill(lead.scoreColor.opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Text("\(lead.leadScore)")
                            .font(AppFonts.headline)
                            .foregroundColor(lead.scoreColor)
                    }
                    
                    Text("Score")
                        .font(.caption2)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                // Lead info
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(lead.displayName)
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1)
                    
                    if let instagram = lead.instagramHandle {
                        Text(instagram)
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.primary)
                    }
                    
                    if let reasoning = lead.reasoning {
                        Text(reasoning)
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(2)
                    }
                    
                    Text(lead.discoveredAt.timeAgo())
                        .font(.caption2)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                // Status and actions
                VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                    StatusBadge(status: lead.leadStatus ?? .new)
                    
                    Button(action: {
                        showingStatusPicker = true
                    }) {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
            .padding(AppSpacing.md)
            .cardStyle()
        }
        .buttonStyle(PlainButtonStyle())
        .confirmationDialog("Update Status", isPresented: $showingStatusPicker) {
            ForEach(LeadStatus.allCases, id: \.self) { status in
                Button(status.displayName) {
                    Task {
                        await onStatusUpdate(status)
                    }
                }
            }
            
            Button("Cancel", role: .cancel) { }
        }
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: LeadStatus
    
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

// MARK: - Lead Detail View
struct LeadDetailView: View {
    let lead: Lead
    let onDismiss: () -> Void

    @State private var outreachMessage = ""
    @State private var selectedPlatform = "instagram"
    @State private var isSendingOutreach = false
    @State private var errorMessage: String?
    @State private var showError = false

    private let apiService = APIService.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        // Header
                        leadHeader
                        
                        // Details
                        leadDetails
                        
                        // Outreach Section
                        if lead.leadStatus == .new || lead.leadStatus == .contacted {
                            outreachSection
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, AppSpacing.md)
                }
            }
            .navigationTitle(lead.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
            .alert("Error Sending Outreach", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
        }
    }
    
    private var leadHeader: some View {
        VStack(spacing: AppSpacing.md) {
            HStack {
                VStack(alignment: .leading) {
                    Text(lead.displayName)
                        .font(AppFonts.title)
                        .foregroundColor(AppColors.textPrimary)
                    
                    if let instagram = lead.instagramHandle {
                        Text(instagram)
                            .font(AppFonts.body)
                            .foregroundColor(AppColors.primary)
                    }
                }
                
                Spacer()
                
                VStack {
                    Text("\(lead.leadScore)")
                        .font(AppFonts.largeTitle)
                        .foregroundColor(lead.scoreColor)
                    
                    Text("Lead Score")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            StatusBadge(status: lead.leadStatus ?? .new)
        }
        .padding(AppSpacing.md)
        .cardStyle()
    }
    
    private var leadDetails: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Details")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)
            
            if let email = lead.contactEmail {
                DetailRow(label: "Email", value: email, icon: "envelope")
            }
            
            DetailRow(label: "Source", value: lead.source, icon: "magnifyingglass")
            DetailRow(label: "Discovered", value: lead.discoveredAt.formattedString(), icon: "calendar")
            
            if let reasoning = lead.reasoning {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("AI Reasoning")
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(reasoning)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .padding(AppSpacing.sm)
                        .background(AppColors.surface)
                        .cornerRadius(CornerRadius.small)
                }
            }
        }
        .padding(AppSpacing.md)
        .cardStyle()
    }
    
    private var outreachSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Send Outreach")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)
            
            // Platform picker
            Picker("Platform", selection: $selectedPlatform) {
                Text("Instagram DM").tag("instagram")
                Text("Email").tag("email")
            }
            .pickerStyle(SegmentedPickerStyle())
            
            // Message field
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Message")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary)
                
                TextEditor(text: $outreachMessage)
                    .frame(minHeight: 100)
                    .padding(AppSpacing.sm)
                    .background(AppColors.surface)
                    .cornerRadius(CornerRadius.small)
                    .foregroundColor(AppColors.textPrimary)
            }
            
            // Send button
            Button(action: sendOutreach) {
                HStack {
                    if isSendingOutreach {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    
                    Text("Send Outreach")
                        .font(AppFonts.headline)
                }
                .frame(maxWidth: .infinity)
            }
            .primaryButton()
            .disabled(outreachMessage.isEmpty || isSendingOutreach)
        }
        .padding(AppSpacing.md)
        .cardStyle()
    }
    
    private func sendOutreach() {
        isSendingOutreach = true
        errorMessage = nil

        Task {
            do {
                try await apiService.sendOutreach(
                    leadId: lead.id,
                    message: outreachMessage,
                    platform: selectedPlatform
                )

                isSendingOutreach = false
                HapticManager.notification(.success)
                onDismiss()
            } catch {
                isSendingOutreach = false
                errorMessage = error.localizedDescription
                showError = true
                HapticManager.notification(.error)
            }
        }
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .foregroundColor(AppColors.primary)
                .frame(width: 20)
            
            Text(label)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(AppFonts.body)
                .foregroundColor(AppColors.textPrimary)
        }
    }
}

#Preview {
    LeadsListView()
}