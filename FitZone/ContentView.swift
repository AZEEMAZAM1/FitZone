import SwiftUI
import HealthKit

struct ContentView: View {
    // MARK: - State Variables
    
    /// Tracks if the user has authorized HealthKit access
    @State private var isAuthorized = false
    
    /// Holds the list of fetched workouts from HealthKit
    @State private var workouts: [HKWorkout] = []
    
    /// Stores the total calories burned across all workouts
    @State private var totalCalories: Double = 0
    
    /// HealthKit store instance (used for queries and permissions)
    let healthStore = HKHealthStore()

    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack {
                if isAuthorized {
                    // Show workout data if permission is granted
                    List {
                        // Section 1: Workouts
                        Section(header: Text("Workouts")) {
                            ForEach(workouts, id: \.uuid) { workout in
                                VStack(alignment: .leading, spacing: 4) {
                                    // Workout type (Running, Walking, Cycling, etc.)
                                    Text(workout.workoutActivityType.name)
                                        .font(.headline)

                                    // Duration in minutes
                                    Text("Duration: \(Int(workout.duration / 60)) mins")

                                    // Calories burned in kcal
                                    Text("Calories Burned: \(Int(workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0)) kcal")
                                }
                                .padding(.vertical, 4)
                            }
                        }

                        // Section 2: Total Summary
                        Section {
                            Text("Total Calories Burned: \(Int(totalCalories)) kcal")
                                .font(.title2)
                                .bold()
                        }
                    }
                } else {
                    // Show button if authorization not granted yet
                    Button("Authorize HealthKit") {
                        requestHealthKitPermission()
                    }
                    .padding()
                }
            }
            .navigationTitle("FitZone Tracker")
        }
        .onAppear {
            // Automatically request permission when app launches
            if HKHealthStore.isHealthDataAvailable() {
                requestHealthKitPermission()
            }
        }
    }

    // MARK: - Request HealthKit Permission
    func requestHealthKitPermission() {
        // Data we want permission to write to HealthKit
        let typesToShare: Set = [HKObjectType.workoutType()]
        
        // Data we want permission to read from HealthKit
        let typesToRead: Set = [
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]

        // Request authorization
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                if success {
                    isAuthorized = true
                    fetchWorkouts() // Fetch workouts immediately after approval
                } else {
                    print("❌ HealthKit authorization failed: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }

    // MARK: - Fetch Workouts
    func fetchWorkouts() {
        // Sort workouts by most recent
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        // Query last 10 workouts
        let query = HKSampleQuery(
            sampleType: HKObjectType.workoutType(),
            predicate: nil,
            limit: 10,
            sortDescriptors: [sort]
        ) { _, samples, error in
            guard let workouts = samples as? [HKWorkout], error == nil else {
                print("❌ Error fetching workouts: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            // Update UI with fetched data
            DispatchQueue.main.async {
                self.workouts = workouts
                self.totalCalories = workouts.reduce(0) {
                    $0 + ($1.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0)
                }
            }
        }

        healthStore.execute(query)
    }
}

// MARK: - Extra Helper Functions
extension ContentView {
    
    /// Fetch total calories burned today only (from midnight to now)
    func fetchTodayCalories() {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }

        // Start of current day (e.g., 12:00 AM)
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date())

        // Query for calories burned today
        let query = HKStatisticsQuery(
            quantityType: energyType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                print("❌ Error fetching today's calories: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            DispatchQueue.main.async {
                let todayCalories = sum.doubleValue(for: .kilocalorie())
                print("🔥 Calories burned today: \(Int(todayCalories)) kcal")
            }
        }

        healthStore.execute(query)
    }
    
    /// Calculate average calories burned per workout
    func averageCalories() -> Double {
        guard !workouts.isEmpty else { return 0 }
        return totalCalories / Double(workouts.count)
    }
    
    /// Find the most frequently performed workout type
    func mostFrequentWorkout() -> String {
        let counts = workouts.reduce(into: [HKWorkoutActivityType: Int]()) { dict, workout in
            dict[workout.workoutActivityType, default: 0] += 1
        }
        if let mostFrequent = counts.max(by: { $0.value < $1.value })?.key {
            return mostFrequent.name
        }
        return "No Workouts"
    }
    
    /// Reset stored workout data (useful for testing or refreshing)
    func resetData() {
        workouts.removeAll()
        totalCalories = 0
    }
}

// MARK: - Extension for User-Friendly Workout Names
extension HKWorkoutActivityType {
    /// Converts workout types into emojis + readable names
    var name: String {
        switch self {
        case .running: return "🏃 Running"
        case .cycling: return "🚴 Cycling"
        case .walking: return "🚶 Walking"
        case .functionalStrengthTraining: return "🏋️ Functional Strength Training"
        case .traditionalStrengthTraining: return "💪 Traditional Strength Training"
        case .elliptical: return "🌀 Elliptical"
        case .swimming: return "🏊 Swimming"
        default: return "❓ Other"
        }
    }
}
