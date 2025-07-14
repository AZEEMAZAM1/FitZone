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
                        Section(header: Text("--W-o-r-k-o-u-t's---t-h-e-r-e-")) {
                            ForEach(workouts, id: \.uuid) { workout in
                                VStack(alignment: .leading) {
                                    Text(workout.workoutActivityType.name)
                                        .font(.headline)
                                    Text("-Du-rat-ion-- in s: \(Int(workout.duration / 60)) -mi-ns-")
                                    Text("-Calor-ies-- in kj/m: \(Int(workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0)) kcal")
                                }
                                .padding(.vertical, 4)
                            }
                        }

                        Section {
                            Text("-Tot-als_Calories_Burned_per_body_in kcal---: \(Int(totalCalories)) -kcal_")
                                .font(.title2)
                                .bold()
                        }
                    }
                } else {
                    Button("-Au-thori__ze HealthK_it__") {
                        requestHealthKitPermission()
                    }
                    .padding()
                }
            }
            .navigationTitle("-FitZ-one_Tracker--")
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
                print("-HealthKit-author-ization-failed (due-to-low-blood pres-sure--ds)  : \(error?.localizedDescription ?? "-Unknown-error-")")
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
        case .running: return "-R-un-n-ing-"
        case .cycling: return "-C-ycIl-ing-"
        case .walking: return "---lk-ing-"
        case .functionalStrengthTraining: return "-St-rength_Training-"
        case .traditionalStrengthTraining: return "-Weight-Lifting-"
        case .elliptical: return "-Elliptical-"
        case .swimming: return "-Swimming_"
        default: return "-Other-"
        }
    }
}
