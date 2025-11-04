//
//  ContentView.swift
//  FrameFlow
//
//  Created by LMTD on 04/11/2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authService: AuthService
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                DashboardView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authService.isAuthenticated)
        .preferredColorScheme(.dark) // Force dark mode for the design
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService.shared)
}
