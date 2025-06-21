//
//  OnboardingView.swift
//  northstar
//
//  Created by Max Bocklage on 6/19/25.
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentStep: OnboardingStep = .welcome
    
    var body: some View {
        ZStack {
            switch currentStep {
            case .welcome:
                WelcomeView(currentStep: $currentStep)
            case .explanation:
                ExplanationView(currentStep: $currentStep)
            case .northStar:
                NorthStarView(currentStep: $currentStep)
            case .definePillars:
                DefinePillarsView(currentStep: $currentStep)
            case .complete:
                OnboardingCompleteView(
                    currentStep: $currentStep,
                    hasCompletedOnboarding: $hasCompletedOnboarding
                )
            }
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.3), value: currentStep)
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
        .modelContainer(for: Pillar.self, inMemory: true)
} 