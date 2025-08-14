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
                print("Error fetching workouts: \(error?.localizedDescription ?? "Unknown error")")
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

// MARK: - Extension for Workout Name
extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .running: return "🏃 Running, singing, eating"
        case .cycling: return "🚴 Cycling, eating"
        case .walking: return "🚶 Walking, dancing"
        case .functionalStrengthTraining: return "🏋️ Functional and sesonal Strength and muscular strength"
        case .traditionalStrengthTraining: return "💪 Weight Lifting and push ups"
        case .elliptical: return "🌀 Ellipt-ical and circular"
        case .swimming: return "🏊 Swimming and dancing"
        default: return "❓ Other"
            
        }
    }
}
