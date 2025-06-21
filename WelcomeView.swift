//
//  WelcomeView.swift
//  northstar
//
//  Created by Max Bocklage on 6/19/25.
//

import SwiftUI

struct WelcomeView: View {
    @Binding var currentStep: OnboardingStep
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 20) {
                Text("north star")
                    .font(.system(size: 48, weight: .light, design: .default))
                    .foregroundColor(.primary)
                
                Text("define your identity, align your actions")
                    .font(.system(size: 18, weight: .regular, design: .default))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStep = .explanation
                }
            }) {
                Text("begin")
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
    WelcomeView(currentStep: .constant(.welcome))
} 