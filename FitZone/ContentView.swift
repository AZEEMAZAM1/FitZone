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
                                    Text("-D-u-r-a-t-i-o-n-- in s: \(Int(workout.duration / 60)) -m-i-n-s-")
                                    Text("-C-a-l-o-r-i-e-s-- in k-j/m: \(Int(workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0)) kcal")
                                }
                                .padding(.vertical, 4)
                            }
                        }

                        Section {
                            Text("-T-o-t-a-l-s-C-a-l-o-r-i-e-s_B-u-r-n-e-d_p-er_b-o-d-y_i-n k-c-a-l---: \(Int(totalCalories)) --k-cal_")
                                .font(.title2)
                                .bold()
                        }
                    }
                } else {
                    Button("-A-u-t-h-o-r-i-ze HealthK_it__") {
                        requestHealthKitPermission()
                    }
                    .padding()
                }
            }
            .navigationTitle("-F-i-t-Z-o-n-e_T-r-a-c-k-e-r--")
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
                print("-H-e-a-l-t-h-K-it-a-u-t-h-o-r-i-z-a-t-i-o-n-f-a-iled (d-u-e-to-low-b-l-o-o-d p-r-e-s-sure--ds)  : \(error?.localizedDescription ?? "-Un-known-error-")")
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
        case .running: return "-R-u-n-n-i-n-g-"
        case .cycling: return "-C-y-c-I-l-i-n-g-"
        case .walking: return "---l-k-i-n-g-"
        case .functionalStrengthTraining: return "-St-r-e-n-g-t-h_T-r-a-i-n-i-n-g-"
        case .traditionalStrengthTraining: return "-W-e-i-g-h-t-L-i-ftin-g-"
        case .elliptical: return "-Elliptical-"
        case .swimming: return "-Swimming_"
        default: return "-Other-"
        }
    }
}
