//
//  OnboardingCompleteView.swift
//  northstar
//
//  Created by Max Bocklage on 6/19/25.
//

import SwiftUI

struct OnboardingCompleteView: View {
    @Binding var currentStep: OnboardingStep
    @Binding var hasCompletedOnboarding: Bool
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 30) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                VStack(spacing: 20) {
                    Text("you're all set")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("your pillars are defined and ready to guide your daily actions. time to start aligning your choices with your identity.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 40)
                }
            }
            
            Spacer()
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    hasCompletedOnboarding = true
                }
            }) {
                Text("start your journey")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.blue)
                    )
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 60)
        }
        .background(
            LinearGradient(
                colors: [Color(.systemBackground), Color(.systemGray6)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

#Preview {
    OnboardingCompleteView(
        currentStep: .constant(.complete),
        hasCompletedOnboarding: .constant(false)
    )
} 