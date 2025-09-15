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
                Form {
                    Section(header: Text("Add New Task")) {
                        TextField("Task Title", text: $newTaskTitle)
                        Picker("Category", selection: $newTaskCategory) {
                            ForEach(categories, id: \.self) { category in
                                Text(category)
                            }
                        }
                        DatePicker("Due-Date", selection: $newTaskDueDate, displayedComponents: .date)
                        Button("Add Task") { addTask() }
                    }
                }

                List {
                    ForEach(tasks) { task in
                        VStack(alignment: .leading) {
                            Text(task.title).font(.headline)
                            Text("Category: \(task.category)").font(.subheadline)
                            Text("Due: \(task.dueDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                        }
                    }
                    .onDelete(perform: deleteTasks)
                }

                VStack(alignment: .leading) {
                    Text("💡 AI Suggestions").bold()
                    Text(aiSuggestion)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)

                    Button("Get AI Suggestions") {
                        sendTasksToLLaMA()
                    }
                    .padding(.top, 5)
                }
                .padding()
            }
            .navigationTitle("TaskTango + LLaMA")
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
                let category = categories.randomElement() ?? "Missc"
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

        URLSession.shared.dataTask(with: request) { data, _, error in
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
