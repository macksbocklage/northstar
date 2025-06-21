import SwiftUI
import SwiftData

struct SetDailyActionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var pillars: [Pillar]
    
    @State private var tasks: [String]
    @State private var currentIndex: Int = 0
    @FocusState private var isTextFieldFocused: Bool
    
    init() {
        _tasks = State(initialValue: Array(repeating: "", count: 3))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if pillars.isEmpty {
                    Text("No pillars found.")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    TabView(selection: $currentIndex) {
                        ForEach(pillars.indices, id: \.self) { index in
                            VStack(spacing: 0) {
                                // Top section with title
                                VStack(spacing: 20) {
                                    Spacer()
                                    
                                    Text("Set your task for today")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    
                                    Text(pillars[index].title)
                                        .font(.largeTitle.bold())
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                        .frame(minHeight: 80) // Fixed height for consistent spacing
                                    
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity)
                                
                                // Middle section with emoji and text field
                                VStack(spacing: 30) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.gray.opacity(0.25))
                                            .frame(width: 180, height: 180)
                                        Text(pillars[index].emoji ?? "❓")
                                            .font(.system(size: 80))
                                    }
                                    
                                    TextField("Enter your task...", text: $tasks[index])
                                        .font(.title2)
                                        .multilineTextAlignment(.center)
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(12)
                                        .padding(.horizontal)
                                        .focused($isTextFieldFocused)
                                        .submitLabel(.done)
                                        .onSubmit {
                                            isTextFieldFocused = false
                                        }
                                }
                                
                                // Bottom section with buttons
                                VStack(spacing: 20) {
                                    Spacer()
                                    
                                    if currentIndex < pillars.count - 1 {
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
                                        .disabled(tasks[index].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                        .padding(.horizontal)
                                    } else {
                                        Button(action: {
                                            saveActions()
                                            dismiss()
                                        }) {
                                            Text("Save All")
                                                .font(.headline)
                                                .foregroundColor(.black)
                                                .frame(maxWidth: .infinity)
                                                .padding()
                                                .background(Color.white)
                                                .cornerRadius(12)
                                        }
                                        .disabled(!allTasksSet)
                                        .padding(.horizontal)
                                    }
                                    
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity)
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
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .colorScheme(.dark)
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

struct EditDailyActionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var pillars: [Pillar]
    
    @State var actions: [DailyAction]
    @State private var editedTitles: [String]
    
    init(actions: [DailyAction]) {
        self._actions = State(initialValue: actions)
        self._editedTitles = State(initialValue: actions.map { $0.title })
    }
    
    var body: some View {
        NavigationView {
            VStack {
                ForEach(actions.indices, id: \.self) { index in
                    VStack(alignment: .leading) {
                        HStack {
                            Text(actions[index].pillar?.emoji ?? "")
                                .font(.title)
                            Text(actions[index].pillar?.title ?? "Pillar")
                                .font(.headline)
                        }
                        TextField("Edit your task...", text: $editedTitles[index], axis: .vertical)
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
            .navigationTitle("Edit Daily Actions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEdits()
                        dismiss()
                    }
                    .disabled(!allTasksSet)
                }
            }
        }
        .onAppear {
            // Ensure we have the latest data
            editedTitles = actions.map { $0.title }
        }
    }
    
    private var allTasksSet: Bool {
        !editedTitles.contains { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    
    private func saveEdits() {
        for (index, action) in actions.enumerated() {
            let newTitle = editedTitles[index].trimmingCharacters(in: .whitespacesAndNewlines)
            if !newTitle.isEmpty {
                action.title = newTitle
            }
        }
        try? modelContext.save()
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

struct EditNorthStarView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var northStarStatement: String
    @State private var editedStatement: String
    @FocusState private var isTextFieldFocused: Bool
    
    init(northStarStatement: Binding<String>) {
        self._northStarStatement = northStarStatement
        self._editedStatement = State(initialValue: northStarStatement.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                VStack(spacing: 20) {
                    Image("logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .foregroundColor(.white)
                    
                    Text("Edit your north star")
                        .font(.title)
                        .bold()
                        .foregroundColor(.white)
                    
                    Text("Your guiding principle that captures who you want to become")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                TextField("Enter your north star statement", text: $editedStatement)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .focused($isTextFieldFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        isTextFieldFocused = false
                    }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        northStarStatement = editedStatement.trimmingCharacters(in: .whitespacesAndNewlines)
                        dismiss()
                    }
                    .disabled(editedStatement.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .foregroundColor(.white)
                }
            }
        }
        .colorScheme(.dark)
    }
} 