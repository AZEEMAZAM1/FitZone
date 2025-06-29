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
                    List {//List of all workouts there
                        Section(header: Text("-Workouts---there")) {
                            ForEach(workouts, id: \.uuid) { workout in
                                VStack(alignment: .leading) {
                                    Text(workout.workoutActivityType.name)
                                        .font(.headline)
                                    Text("-Duration--: \(Int(workout.duration / 60)) mins")
                                    Text("-Calories--: \(Int(workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0)) kcal")
                                }
                                .padding(.vertical, 4)
                            }
                        }

                        Section {
                            Text("Totals_Calories Burned per body in kcal--: \(Int(totalCalories)) kcal")
                                .font(.title2)
                                .bold()
                        }
                    }
                } else {
                    Button("Authori_ze HealthK_it") {
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
            if success {
                isAuthorized = true
                fetchWorkouts()
            } else {
                print("HealthKit authorization failed (due to low blood pressure--)  : \(error?.localizedDescription ?? "Unknown error")")
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
        ) { _, samples, _ in
            guard let workouts = samples as? [HKWorkout] else { return }

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
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .walking: return "Walking"
        case .functionalStrengthTraining: return "Strength Training"
        case .traditionalStrengthTraining: return "Weight Lifting"
        case .elliptical: return "Elliptical"
        case .swimming: return "Swimming"
        default: return "Other"
        }
    }
}
