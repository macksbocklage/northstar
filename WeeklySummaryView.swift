import SwiftUI
import SwiftData

struct WeeklySummaryView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var pillars: [Pillar]
    let weeklyReviews: [WeeklyReview]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if weeklyReviews.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text("No Weekly Reviews Yet")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            
                            Text("Complete your first weekly review to see insights here")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 100)
                    } else {
                        ForEach(weeklyReviews.prefix(10)) { review in
                            WeeklyReviewSummaryCard(review: review, pillars: pillars)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top)
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .navigationTitle("Weekly Reviews")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .colorScheme(.dark)
    }
}

struct WeeklyReviewSummaryCard: View {
    let review: WeeklyReview
    let pillars: [Pillar]
    
    private var weekDateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let startString = formatter.string(from: review.weekStart)
        let endString = formatter.string(from: review.weekEnd)
        return "\(startString) - \(endString)"
    }
    
    private var averageRating: Double {
        let validRatings = review.pillarRatings.filter { $0 > 0 }
        guard !validRatings.isEmpty else { return 0 }
        return Double(validRatings.reduce(0, +)) / Double(validRatings.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(weekDateRange)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Text("Week Review")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Average rating
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= Int(averageRating.rounded()) ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundColor(star <= Int(averageRating.rounded()) ? .yellow : .gray)
                    }
                }
            }
            
            // Pillar insights
            VStack(spacing: 12) {
                ForEach(pillars.indices, id: \.self) { index in
                    if index < review.pillarRatings.count && review.pillarRatings[index] > 0 {
                        PillarSummaryRow(
                            pillar: pillars[index],
                            rating: review.pillarRatings[index],
                            reflection: index < review.pillarReflections.count ? review.pillarReflections[index] : "",
                            nextWeekFocus: index < review.nextWeekFocus.count ? review.nextWeekFocus[index] : ""
                        )
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

struct PillarSummaryRow: View {
    let pillar: Pillar
    let rating: Int
    let reflection: String
    let nextWeekFocus: String
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Pillar header
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(pillar.emoji ?? "⭐️")
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(pillar.title)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.caption2)
                                    .foregroundColor(star <= rating ? .yellow : .gray)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    if !reflection.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Reflection")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                            Text(reflection)
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                    
                    if !nextWeekFocus.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Focus Area")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                            Text(nextWeekFocus)
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.leading, 8)
                .transition(.opacity.combined(with: .slide))
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    WeeklySummaryView(weeklyReviews: [])
        .modelContainer(for: [WeeklyReview.self, Pillar.self], inMemory: true)
} 