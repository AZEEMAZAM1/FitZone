import SwiftUI

// MARK: - Task Model
struct Task: Identifiable {
    let id = UUID()
    var title: String
    var category: String
    var dueDate: Date
}

// MARK: - Main Content View
struct ContentView: View {
    @State private var tasks: [Task] = []
    @State private var newTaskTitle = ""
    @State private var newTaskCategory = "Work"
    @State private var newTaskDueDate = Date()
    @State private var aiSuggestion = "AI suggestions will appear here."

    let categories = ["Work", "Personal", "Urgent", "Long-Term", "Misc"]

    var body: some View {
        NavigationView {
            VStack {
                // MARK: - Task Form
                Form {
                    Section(header: Text("➕ :Add New Task").foregroundColor(.blue)) {
                        TextField("Task Title", text: $newTaskTitle)

                        Picker("Category", selection: $newTaskCategory) {
                            ForEach(categories, id: \.self) { category in
                                Text(category)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())

                        DatePicker("Due-Date", selection: $newTaskDueDate, displayedComponents: .date)

                        Button(action: addTask) {
                            Label("Add Task", systemImage: "plus.circle.fill")
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle()) // macOS-safe
                    }
                }
                .background(Color.gray.opacity(0.05))

                // MARK: - Task List
                List {
                    ForEach(tasks) { task in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title)
                                .font(.headline)
                                .foregroundColor(.primary)

                            Text("Category: \(task.category)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text("Due: \(task.dueDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(6)
                        .background(Color.blue.opacity(0.05))
                        .cornerRadius(10)
                    }
                    .onDelete(perform: deleteTasks)
                }
                .listStyle(SidebarListStyle()) // ✅ works on macOS

                // MARK: - AI Suggestions
                VStack(alignment: .leading, spacing: 8) {
                    Text("💡 AI related Suggestions")
                        .font(.headline)
                        .foregroundColor(.purple)

                    Text(aiSuggestion)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(8)

                    Button(action: sendTasksToLLaMA) {
                        Label("Get AI Suggestions", systemImage: "sparkles")
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.purple)
                            .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle()) // ✅ macOS safe
                }
                .padding()
            }
            .navigationTitle("✨ TaskTango + LLaMA")
            .background(Color.gray.opacity(0.1).ignoresSafeArea()) // ✅ macOS friendly
        }
        .onAppear { loadMockTasks() }
    }

    // MARK: - Helper Functions
    private func addTask() {
        guard !newTaskTitle.isEmpty else { return }
        let task = Task(title: newTaskTitle, category: newTaskCategory, dueDate: newTaskDueDate)
        tasks.append(task)
        newTaskTitle = ""
    }

    private func deleteTasks(at offsets: IndexSet) {
        tasks.remove(atOffsets: offsets)
    }

    private func loadMockTasks() {
        if tasks.isEmpty {
            for i in 1...10 {
                let category = categories.randomElement() ?? "Misc"
                let task = Task(title: "Sample Task \(i)", category: category, dueDate: Date())
                tasks.append(task)
            }
        }
    }

    // MARK: - LLaMA Integration (API Call)
    private func sendTasksToLLaMA() {
        let taskTitles = tasks.map { $0.title }.joined(separator: ", ")
        let prompt = "Categorize these tasks: \(taskTitles)"

        guard let url = URL(string: "http://localhost:5000/llama") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["prompt": prompt, "max_tokens": 100]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data else { return }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let text = choices.first?["text"] as? String {
                DispatchQueue.main.async { aiSuggestion = text }
            }
        }.resume()
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
