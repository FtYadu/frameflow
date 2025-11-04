//
//  LeadViewModel.swift
//  FrameFlow
//
//  Created by LMTD on 04/11/2025.
//

import Foundation
import Combine

@MainActor
class LeadViewModel: ObservableObject {
    @Published var leads: [Lead] = []
    @Published var selectedLead: Lead?
    @Published var loadingState: LoadingState = .idle
    @Published var filterStatus: LeadStatus? = nil
    
    private let apiService = APIService.shared
    
    // MARK: - Computed Properties
    var filteredLeads: [Lead] {
        if let filterStatus = filterStatus {
            return leads.filter { $0.leadStatus == filterStatus }
        }
        return leads
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
    
    // MARK: - Data Loading
    func loadLeads() async {
        loadingState = .loading
        
        do {
            leads = try await apiService.fetchLeads()
            loadingState = .success
        } catch {
            loadingState = .failure(error)
            print("Error loading leads: \(error)")
        }
    }
    
    func refreshLeads() async {
        await loadLeads()
    }
    
    // MARK: - Lead Actions
    func updateLeadStatus(_ lead: Lead, status: LeadStatus, notes: String? = nil) async {
        do {
            let updatedLead = try await apiService.updateLeadStatus(
                id: lead.id,
                status: status.rawValue,
                notes: notes
            )
            
            if let index = leads.firstIndex(where: { $0.id == lead.id }) {
                leads[index] = updatedLead
            }
            
            HapticManager.impact(.medium)
            
        } catch {
            print("Error updating lead status: \(error)")
            HapticManager.notification(.error)
        }
    }
    
    func sendOutreach(_ lead: Lead, message: String, platform: String) async {
        do {
            try await apiService.sendOutreach(
                leadId: lead.id,
                message: message,
                platform: platform
            )
            
            // Update lead status to contacted
            await updateLeadStatus(lead, status: .contacted)
            
            HapticManager.notification(.success)
            
        } catch {
            print("Error sending outreach: \(error)")
            HapticManager.notification(.error)
        }
    }
    
    // MARK: - Lead Details
    func selectLead(_ lead: Lead) {
        selectedLead = lead
    }
    
    func clearSelection() {
        selectedLead = nil
    }
}

// MARK: - Lead Stats
extension LeadViewModel {
    var totalLeads: Int {
        return leads.count
    }
    
    var newLeads: Int {
        return leads.filter { $0.leadStatus == .new }.count
    }
    
    var contactedLeads: Int {
        return leads.filter { $0.leadStatus == .contacted }.count
    }
    
    var convertedLeads: Int {
        return leads.filter { $0.leadStatus == .converted }.count
    }
    
    var conversionRate: Double {
        guard totalLeads > 0 else { return 0.0 }
        return Double(convertedLeads) / Double(totalLeads) * 100
    }
    
    var averageScore: Double {
        guard !leads.isEmpty else { return 0.0 }
        let totalScore = leads.reduce(0) { $0 + $1.leadScore }
        return Double(totalScore) / Double(leads.count)
    }
}