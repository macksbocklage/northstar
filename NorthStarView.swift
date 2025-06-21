import SwiftUI

struct NorthStarView: View {
    @Binding var currentStep: OnboardingStep
    @AppStorage("northStarStatement") private var northStarStatement = "Excellence in all areas."
    @State private var statement = ""
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 30) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                VStack(spacing: 20) {
                    Text("your north star")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("define your guiding principle - the one statement that captures who you want to become")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 40)
                }
            }
            
            TextField("Enter your north star statement", text: $statement)
                .font(.system(size: 18))
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal, 40)
                .textInputAutocapitalization(.never)
            
            Spacer()
            
            Button(action: {
                if !statement.isEmpty {
                    northStarStatement = statement
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep = .definePillars
                    }
                }
            }) {
                Text("continue")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(statement.isEmpty ? Color.gray : Color.blue)
                    )
            }
            .disabled(statement.isEmpty)
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
    NorthStarView(currentStep: .constant(.northStar))
} 