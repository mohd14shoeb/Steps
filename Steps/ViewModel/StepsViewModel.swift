//
//  StepsViewModel.swift
//  Steps
//
//  Created by Brittany Rima on 12/14/22.
//

import Foundation
import HealthKit

class StepsViewModel: ObservableObject {
    var healthStore: HKHealthStore?
    var query: HKStatisticsCollectionQuery?

    @Published var steps: [Step] = []
    @Published var goas = 10000

    init() {
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
        }
    }

    func calculateSteps(completion: @escaping (HKStatisticsCollection?) -> Void) {
        let stepType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())
        let anchorDate = Date.sundayAt12AM()
        let daily = DateComponents(day: 1)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)

        query = HKStatisticsCollectionQuery(quantityType: stepType,
                                    quantitySamplePredicate: predicate,
                                    options: .cumulativeSum,
                                    anchorDate: anchorDate,
                                    intervalComponents: daily)
        query!.initialResultsHandler = { query, statsCollection, error in
            completion(statsCollection)
        }

        if let healthStore = healthStore, let query = self.query {
            healthStore.execute(query)
        }
    }

    func updateUIFromStats(_ statsCollection: HKStatisticsCollection) {
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let endDate = Date()

        statsCollection.enumerateStatistics(from: startDate, to: endDate) { stats, stop in
            let count = stats.sumQuantity()?.doubleValue(for: .count())
            let step = Step(count: Int(count ?? 0), date: stats.startDate)
            self.steps.append(step)
        }
    }

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        let stepType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
        guard let healthStore = self.healthStore else { return  completion(false) }

        healthStore.requestAuthorization(toShare: [], read: [stepType]) { success, error in
            completion(success)
        }
    }

}














// CHAT GPT WAY
//class StepsViewModel: ObservableObject {
//    let healthStore = HKHealthStore()
//    var query: HKStatisticsCollectionQuery?
//
//    @Published var currentSteps = 0
//    @Published var goal = 10000
//    var stepsPerDay = [Int]()
//
//    func loadSteps() {
//        let now = Date()
//        let stepCount = HKQuantityType.quantityType(forIdentifier: .stepCount)!
//
//        let startOfDay = Calendar.current.startOfDay(for: now)
//        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
//
//        let query = HKStatisticsQuery(quantityType: stepCount, quantitySamplePredicate: predicate, options: .cumulativeSum) { query, result, error in
//            guard let result = result, let sum = result.sumQuantity() else {
//                return
//            }
//
//            DispatchQueue.main.async {
//                self.currentSteps = Int(sum.doubleValue(for: HKUnit.count()))
//            }
//        }
//
//        healthStore.requestAuthorization(toShare: [stepCount], read: [stepCount]) { success, error in
//            if success {
//                self.healthStore.execute(query)
//            } else {
//                print("User didn't grant authorization: \(error?.localizedDescription)")
//                // handle error here
//            }
//        }
//    }
//}