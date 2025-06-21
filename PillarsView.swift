import SwiftUI
import SwiftData

struct PillarsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var pillars: [Pillar]
    @State private var selectedPillar: Pillar?
    @State private var showingEditPillar = false
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Your Pillars")
                    .font(.largeTitle)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(pillars) { pillar in
                            NavigationLink(destination: EditPillarView(pillar: pillar)) {
                                PillarCard(
                                    icon: pillar.emoji ?? "⭐️", 
                                    title: pillar.title
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                }
                
                Spacer()
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
        }
        .colorScheme(.dark)
    }
}

struct EmojiPickerView: View {
    @Binding var selectedEmoji: String
    @Environment(\.dismiss) private var dismiss
    private let commonEmojis = ["💪", "📈", "📚", "❤️", "🧠", "💰", "🏃‍♂️", "🎯", "🌟", "🔥", "⚡️", "🎨", "🌱", "🚀", "💡", "🎪"]

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 20) {
                    ForEach(commonEmojis, id: \.self) { emojiOption in
                        Button(action: {
                            selectedEmoji = emojiOption
                            dismiss()
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedEmoji == emojiOption ? Color.blue : Color(.systemGray6))
                                    .aspectRatio(1.0, contentMode: .fit)

                                Text(emojiOption)
                                    .font(.title)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .navigationTitle("Select Emoji")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .colorScheme(.dark)
    }
}

struct EditPillarView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let pillar: Pillar
    @State private var title: String
    @State private var emoji: String
    @State private var details: String
    @State private var showingEmojiPicker = false
    
    private let commonEmojis = ["💪", "📈", "📚", "❤️", "🧠", "💰", "🏃‍♂️", "🎯", "🌟", "🔥", "⚡️", "🎨", "🌱", "🚀", "💡", "🎪"]
    
    init(pillar: Pillar) {
        self.pillar = pillar
        self._title = State(initialValue: pillar.title)
        self._emoji = State(initialValue: pillar.emoji ?? "⭐️")
        self._details = State(initialValue: pillar.details ?? "")
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Button(action: {
                    showingEmojiPicker = true
                }) {
                    Text(emoji)
                        .font(.system(size: 48))
                }
                
                TextField("Pillar Name", text: $title, axis: .vertical)
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                    .textFieldStyle(.plain)
                
                TextField("Description goes here", text: $details, axis: .vertical)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .lineLimit(3...6)
                
                Spacer()
            }
        }
        .padding()
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    saveChanges()
                    dismiss()
                }
                .disabled(title.isEmpty)
            }
        }
        .sheet(isPresented: $showingEmojiPicker) {
            EmojiPickerView(selectedEmoji: $emoji)
                .presentationDetents([.medium])
        }
    }
    
    private func saveChanges() {
        pillar.title = title
        pillar.emoji = emoji
        pillar.details = details.isEmpty ? nil : details
        
        try? modelContext.save()
    }
}

#Preview {
    PillarsView()
        .modelContainer(for: Pillar.self, inMemory: true)
} 