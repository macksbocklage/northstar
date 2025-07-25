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
            VStack(spacing: 32) {
                ForEach(actions.indices, id: \.self) { index in
                    VStack(spacing: 20) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.15))
                                    .frame(width: 60, height: 60)
                                Text(actions[index].pillar?.emoji ?? "❓")
                                    .font(.system(size: 32))
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(actions[index].pillar?.title ?? "Pillar")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("Edit Task")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        TextField("Edit your task...", text: $editedTitles[index], axis: .vertical)
                            .font(.title2)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .accentColor(.white)
                            .lineLimit(2...4)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.black)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                    .padding(.horizontal)
                }
                Spacer()
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEdits()
                        dismiss()
                    }
                    .disabled(!allTasksSet)
                    .foregroundColor(.white)
                }
            }
        }
        .colorScheme(.dark)
        .onAppear {
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
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack {
                if actions.isEmpty {
                    VStack {
                        Spacer()
                        Text("No actions to log.")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    TabView(selection: $currentIndex) {
                        ForEach(actions.indices, id: \.self) { index in
                            VStack(spacing: 0) {
                                // Top section with title
                                VStack(spacing: 20) {
                                    Spacer()
                                    
                                    Text("Log your progress")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    
                                    Text(actions[index].pillar?.title ?? "Pillar")
                                        .font(.largeTitle.bold())
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                        .frame(minHeight: 80)
                                    
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity)
                                
                                // Middle section with emoji and task
                                VStack(spacing: 30) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.gray.opacity(0.15))
                                            .frame(width: 160, height: 160)
                                        Text(actions[index].pillar?.emoji ?? "❓")
                                            .font(.system(size: 70))
                                    }
                                    
                                    Text(actions[index].title)
                                        .font(.title2.bold())
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                        .frame(maxWidth: .infinity)
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .padding(.bottom, 24)
                                }
                                .frame(maxWidth: .infinity)
                                
                                // Bottom section with notes and buttons
                                VStack(spacing: 30) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        TextField("Add a note (optional)", text: Binding(
                                            get: { actions[index].notes ?? "" },
                                            set: { actions[index].notes = $0.isEmpty ? nil : $0 }
                                        ), axis: .vertical)
                                        .padding()
                                        .background(Color.gray.opacity(0.15))
                                        .cornerRadius(12)
                                        .padding(.horizontal)
                                        .focused($isTextFieldFocused)
                                        .submitLabel(.done)
                                        .onSubmit {
                                            isTextFieldFocused = false
                                        }
                                    }
                                    
                                    HStack(spacing: 24) {
                                        Button(action: { markStatus(.incomplete) }) {
                                            VStack(spacing: 8) {
                                                ZStack {
                                                    Circle()
                                                        .fill(Color.red.opacity(0.15))
                                                        .frame(width: 70, height: 70)
                                                    Image(systemName: "xmark")
                                                        .font(.title2.bold())
                                                        .foregroundColor(.red)
                                                }
                                                Text("Didn't do it")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        
                                        Button(action: { markStatus(.completed) }) {
                                            VStack(spacing: 8) {
                                                ZStack {
                                                    Circle()
                                                        .fill(Color.green.opacity(0.15))
                                                        .frame(width: 70, height: 70)
                                                    Image(systemName: "checkmark")
                                                        .font(.title2.bold())
                                                        .foregroundColor(.green)
                                                }
                                                Text("Completed")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        
                                        Button(action: { markStatus(.notLogged) }) {
                                            VStack(spacing: 8) {
                                                ZStack {
                                                    Circle()
                                                        .fill(Color.gray.opacity(0.15))
                                                        .frame(width: 70, height: 70)
                                                    Image(systemName: "circle")
                                                        .font(.title2.bold())
                                                        .foregroundColor(.gray)
                                                }
                                                Text("Unlogged")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
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
                    Button("Done") {
                        saveLog()
                        dismiss()
                    }
                }
            }
        }
        .colorScheme(.dark)
    }
    
    private func markStatus(_ status: ActionStatus) {
        actions[currentIndex].actionStatus = status
        
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

struct LogYesterdayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State var actions: [DailyAction]
    @State private var currentIndex: Int = 0
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack {
                if actions.isEmpty {
                    VStack {
                        Spacer()
                        Text("No actions to log for yesterday.")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    TabView(selection: $currentIndex) {
                        ForEach(actions.indices, id: \.self) { index in
                            VStack(spacing: 0) {
                                // Top section with title
                                VStack(spacing: 20) {
                                    Spacer()
                                    
                                    Text("Log yesterday's progress")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    
                                    Text(actions[index].pillar?.title ?? "Pillar")
                                        .font(.largeTitle.bold())
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                        .frame(minHeight: 80)
                                    
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity)
                                
                                // Middle section with emoji and task
                                VStack(spacing: 30) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.orange.opacity(0.15))
                                            .frame(width: 160, height: 160)
                                        Text(actions[index].pillar?.emoji ?? "❓")
                                            .font(.system(size: 70))
                                    }
                                    
                                    Text(actions[index].title)
                                        .font(.title2.bold())
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                        .frame(maxWidth: .infinity)
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .padding(.bottom, 24)
                                }
                                .frame(maxWidth: .infinity)
                                
                                // Bottom section with notes and buttons
                                VStack(spacing: 30) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        TextField("Add a note (optional)", text: Binding(
                                            get: { actions[index].notes ?? "" },
                                            set: { actions[index].notes = $0.isEmpty ? nil : $0 }
                                        ), axis: .vertical)
                                        .padding()
                                        .background(Color.gray.opacity(0.15))
                                        .cornerRadius(12)
                                        .padding(.horizontal)
                                        .focused($isTextFieldFocused)
                                        .submitLabel(.done)
                                        .onSubmit {
                                            isTextFieldFocused = false
                                        }
                                    }
                                    
                                    HStack(spacing: 24) {
                                        Button(action: { markStatus(.incomplete) }) {
                                            VStack(spacing: 8) {
                                                ZStack {
                                                    Circle()
                                                        .fill(Color.red.opacity(0.15))
                                                        .frame(width: 70, height: 70)
                                                    Image(systemName: "xmark")
                                                        .font(.title2.bold())
                                                        .foregroundColor(.red)
                                                }
                                                Text("Didn't do it")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        
                                        Button(action: { markStatus(.completed) }) {
                                            VStack(spacing: 8) {
                                                ZStack {
                                                    Circle()
                                                        .fill(Color.green.opacity(0.15))
                                                        .frame(width: 70, height: 70)
                                                    Image(systemName: "checkmark")
                                                        .font(.title2.bold())
                                                        .foregroundColor(.green)
                                                }
                                                Text("Completed")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        
                                        Button(action: { markStatus(.notLogged) }) {
                                            VStack(spacing: 8) {
                                                ZStack {
                                                    Circle()
                                                        .fill(Color.gray.opacity(0.15))
                                                        .frame(width: 70, height: 70)
                                                    Image(systemName: "circle")
                                                        .font(.title2.bold())
                                                        .foregroundColor(.gray)
                                                }
                                                Text("Unlog")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
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
                    Button("Done") {
                        saveLog()
                        dismiss()
                    }
                }
            }
        }
        .colorScheme(.dark)
    }
    
    private func markStatus(_ status: ActionStatus) {
        actions[currentIndex].actionStatus = status
        
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