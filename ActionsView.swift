import SwiftUI
import SwiftData

struct SetDailyActionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var pillars: [Pillar]
    
    @State private var tasks: [String]
    
    init() {
        _tasks = State(initialValue: Array(repeating: "", count: 3))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                ForEach(pillars.indices, id: \.self) { index in
                    VStack(alignment: .leading) {
                        HStack {
                            Text(pillars[index].emoji ?? "")
                                .font(.title)
                            Text(pillars[index].title)
                                .font(.headline)
                        }
                        TextField("Set your task for today...", text: $tasks[index], axis: .vertical)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .lineLimit(2...4)
                    }
                    .padding(.bottom)
                }
                Spacer()
            }
            .padding()
            .navigationTitle("Set Daily Actions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveActions()
                        dismiss()
                    }
                    .disabled(!allTasksSet)
                }
            }
        }
        .onAppear {
            if pillars.count == 3 && tasks.count != 3 {
                tasks = Array(repeating: "", count: pillars.count)
            }
        }
    }
    
    private var allTasksSet: Bool {
        !tasks.contains { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    
    private func saveActions() {
        for (index, pillar) in pillars.enumerated() {
            let title = tasks[index].trimmingCharacters(in: .whitespacesAndNewlines)
            if !title.isEmpty {
                let action = DailyAction(title: title, date: .now, pillar: pillar)
                modelContext.insert(action)
            }
        }
    }
}

struct LogTodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State var actions: [DailyAction]
    @State private var currentIndex: Int = 0
    
    var body: some View {
        NavigationView {
            VStack {
                if actions.isEmpty {
                    Text("No actions to log.")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    TabView(selection: $currentIndex) {
                        ForEach(actions.indices, id: \.self) { index in
                            ScrollView {
                                VStack(spacing: 20) {
                                    Spacer()
                                    Text(actions[index].pillar?.title ?? "Pillar")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    
                                    Text(actions[index].title)
                                        .font(.largeTitle.bold())
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                    
                                    Spacer()
                                    
                                    ZStack {
                                        Circle()
                                            .fill(Color.gray.opacity(0.25))
                                            .frame(width: 180, height: 180)
                                        Text(actions[index].pillar?.emoji ?? "❓")
                                            .font(.system(size: 80))
                                    }
                                    
                                    TextField("Add a note...", text: Binding(
                                        get: { actions[index].notes ?? "" },
                                        set: { actions[index].notes = $0.isEmpty ? nil : $0 }
                                    ), axis: .vertical)
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(12)
                                    .padding(.horizontal)

                                    Spacer()
                                    
                                    HStack(spacing: 20) {
                                        Button(action: { markCompleted(true) }) {
                                            Text("YES")
                                                .font(.title.bold())
                                                .foregroundColor(.white)
                                                .frame(width: 80, height: 80)
                                                .background(Circle().fill(.green))
                                        }
                                        
                                        Button(action: { markCompleted(false) }) {
                                            Text("NO")
                                                .font(.title.bold())
                                                .foregroundColor(.white)
                                                .frame(width: 80, height: 80)
                                                .background(Circle().fill(.red))
                                        }
                                    }
                                    
                                    if currentIndex < actions.count - 1 {
                                        Button(action: {
                                            withAnimation {
                                                currentIndex += 1
                                            }
                                        }) {
                                            Text("Next")
                                                .font(.headline)
                                                .foregroundColor(.black)
                                                .frame(maxWidth: .infinity)
                                                .padding()
                                                .background(Color.white)
                                                .cornerRadius(12)
                                        }
                                        .padding(.horizontal)
                                    }
                                    
                                    Spacer()
                                }
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if currentIndex > 0 {
                        Button {
                            withAnimation { currentIndex -= 1 }
                        } label: {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveLog()
                        dismiss()
                    }
                }
            }
        }
        .colorScheme(.dark)
    }
    
    private func markCompleted(_ status: Bool) {
        actions[currentIndex].isCompleted = status
        
        if currentIndex < actions.count - 1 {
            withAnimation {
                currentIndex += 1
            }
        } else {
            saveLog()
            dismiss()
        }
    }
    
    private func saveLog() {
        try? modelContext.save()
    }
} 