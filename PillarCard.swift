import SwiftUI

struct PillarCard: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.title)
            
            Text(title)
                .font(.headline)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black)
                .stroke(Color.gray, lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        PillarCard(icon: "💪", title: "Health")
            .padding()
            .background(Color.black)
        
        PillarCard(icon: "📈", title: "Career")
            .padding()
            .background(Color.black)
    }
} 