//
//  AgentCardView.swift
//  FrameFlow
//
//  Created by LMTD on 04/11/2025.
//

import SwiftUI

struct AgentCardView: View {
    let agent: Agent
    let onToggle: () async -> Void
    let onTrigger: (String) async -> Void
    
    @State private var isToggling = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header
            HStack {
                // Icon with status
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: agent.type?.gradientColors ?? [AppColors.primary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: agent.type?.icon ?? "gear")
                        .foregroundColor(.white)
                        .font(.title3)
                }
                
                Spacer()
                
                // Status indicator
                StatusDot(isActive: agent.isActive, isWorking: agent.isWorking)
            }
            
            // Agent info
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(agent.type?.displayName ?? agent.agentType.capitalized)
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(agent.statusDisplayName)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Controls
            HStack {
                Toggle("", isOn: Binding(
                    get: { agent.isActive },
                    set: { _ in
                        Task {
                            isToggling = true
                            await onToggle()
                            isToggling = false
                        }
                    }
                ))
                .toggleStyle(SwitchToggleStyle(tint: agent.type?.gradientColors.first ?? AppColors.primary))
                .disabled(isToggling)
                
                Spacer()
                
                if agent.isActive {
                    triggerButton
                }
            }
        }
        .padding(AppSpacing.md)
        .cardStyle()
        .opacity(isToggling ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isToggling)
    }
    
    private var triggerButton: some View {
        Button(action: {
            Task {
                let action = getDefaultAction(for: agent.type)
                await onTrigger(action)
            }
        }) {
            Image(systemName: "play.circle.fill")
                .foregroundColor(agent.type?.gradientColors.first ?? AppColors.primary)
                .font(.title3)
        }
        .disabled(agent.isWorking)
    }
    
    private func getDefaultAction(for agentType: AgentType?) -> String {
        switch agentType {
        case .scout:
            return "find_leads"
        case .marketing:
            return "generate_posts"
        case .editor:
            return "start_editing"
        case .finance:
            return "generate_invoice"
        case .none:
            return "start"
        }
    }
}

// MARK: - Status Dot
struct StatusDot: View {
    let isActive: Bool
    let isWorking: Bool
    
    var body: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 8, height: 8)
            .overlay(
                Circle()
                    .stroke(AppColors.cardBackground, lineWidth: 2)
            )
            .scaleEffect(isWorking ? 1.2 : 1.0)
            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isWorking)
    }
    
    private var statusColor: Color {
        if !isActive {
            return AppColors.textSecondary
        } else if isWorking {
            return AppColors.warning
        } else {
            return AppColors.success
        }
    }
}

#Preview {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
        AgentCardView(
            agent: Agent(
                id: "1",
                userId: "user1",
                agentType: "scout",
                isActive: true,
                status: "working",
                currentTask: "Finding wedding photographers in NYC",
                lastActivityAt: Date(),
                createdAt: Date()
            ),
            onToggle: {},
            onTrigger: { _ in }
        )
        
        AgentCardView(
            agent: Agent(
                id: "2",
                userId: "user1",
                agentType: "marketing",
                isActive: false,
                status: "idle",
                currentTask: nil,
                lastActivityAt: Date(),
                createdAt: Date()
            ),
            onToggle: {},
            onTrigger: { _ in }
        )
    }
    .padding()
    .background(AppColors.background)
}