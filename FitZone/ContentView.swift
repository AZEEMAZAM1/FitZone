import SwiftUI
import HealthKit

struct ContentView: View {
    @State private var isAuthorized = false
    @State private var workouts: [HKWorkout] = []
    @State private var totalCalories: Double = 0

    let healthStore = HKHealthStore()

    var body: some View {
        NavigationStack {
            VStack {
                if isAuthorized {
                    List {
                        Section(header: Text("-- W-o-r-k-o-u-t-s ---")) {
                            ForEach(workouts, id: \.uuid) { workout in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(workout.workoutActivityType.name)
                                        .font(.headline)

                                    Text("Duration: \(Int(workout.duration / 60)) mins")

                                    Text("Calories Burned: \(Int(workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0)) kcal")
                                }
                                .padding(.vertical, 4)
                            }
                        }

                        Section {
                            Text("Total Calories Burned: \(Int(totalCalories)) kcal")
                                .font(.title2)
                                .bold()
                        }
                    }
                } else {
                    Button("Authorize HealthKit") {
                        requestHealthKitPermission()
                    }
                    .padding()
                }
            }
            .navigationTitle("FitZone Tracker")
        }
        .onAppear {
            if HKHealthStore.isHealthDataAvailable() {
                requestHealthKitPermission()
            }
        }
    }

    func requestHealthKitPermission() {
        let typesToShare: Set = [
            HKObjectType.workoutType()
        ]

        let typesToRead: Set = [
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]

        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                if success {
                    isAuthorized = true
                    fetchWorkouts()
                } else {
                    print("HealthKit authorization failed: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }

    func fetchWorkouts() {
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let workoutQuery = HKSampleQuery(
            sampleType: HKObjectType.workoutType(),
            predicate: nil,
            limit: 10,
            sortDescriptors: [sort]
        ) { _, samples, error in
            guard let workouts = samples as? [HKWorkout], error == nil else {
                print("Error fetc-hing workouts: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            DispatchQueue.main.async {
                self.workouts = workouts
                self.totalCalories = workouts.reduce(0) {
                    $0 + ($1.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0)
                }
            }
        }

        healthStore.execute(workoutQuery)
    }
}

// MARK: - Extra Helper Functions
extension ContentView {
    
    /// Fetch total calories burned today only
    func fetchTodayCalories() {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }

        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date())

        let query = HKStatisticsQuery(
            quantityType: energyType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                print("Error fetching today's calories: \(error?.localizedDescription ?? "Unknown error")")
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
    
    /// Find the most frequent workout type
    func mostFrequentWorkout() -> String {
        let counts = workouts.reduce(into: [HKWorkoutActivityType: Int]()) { dict, workout in
            dict[workout.workoutActivityType, default: 0] += 1
        }
        if let mostFrequent = counts.max(by: { $0.value < $1.value })?.key {
            return mostFrequent.name
        }
        return "No Workouts"
    }
    
    /// Reset stored workout data
    func resetData() {
        workouts.removeAll()
        totalCalories = 0
    }
}


// MARK: - Extension for Workout Name
extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .running: return "🏃 Running, singing, eating"
        case .cycling: return "🚴 Cyc-ling, eat-ing"
        case .walking: return "🚶 W-alk-ing, dan-c-ing"
        case .functionalStrengthTraining: return "🏋️ Fu-nc-tio-nal a-nd ses-onal St-reng-th a-nd mus-cular str-ength"
        case .traditionalStrengthTraining: return "💪 We-ight L-if-ting and push ups"
        case .elliptical: return "🌀 El-lipt-ical and cir-cular"
        case .swimming: return "🏊 Swi-mming and dan-cing anf fishing"
        default: return "❓ Other"
            
        }
    }
}
