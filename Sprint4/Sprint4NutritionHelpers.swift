import Foundation
import FirebaseFirestore

/// Lightweight utilities for connecting Sprint 4 screens to existing meal documents.
enum Sprint4Nutrition {
    static func calorieBreakdown(proteinGrams: Double, carbGrams: Double, fatGrams: Double) -> (protein: Double, carbs: Double, fat: Double) {
        (max(0, proteinGrams) * 4, max(0, carbGrams) * 4, max(0, fatGrams) * 9)
    }

    static func countsByDay(dates: [Date], calendar: Calendar = .current) -> [Date: Int] {
        var counts: [Date: Int] = [:]
        for date in dates {
            let day = calendar.startOfDay(for: date)
            counts[day, default: 0] += 1
        }
        return counts
    }
}

/// One-time fetch for profile values, which should not hold a live stream open.
struct Sprint4ProfileFetcher {
    let db = Firestore.firestore()
    func fetch(userID: String) async throws -> [String: Any]? {
        let snapshot = try await db.collection("users").document(userID).getDocument()
        return snapshot.data()
    }
}

/// Call start when calendar is visible and stop when leaving the screen.
/// Adjust collection paths/field names to match TrainFUEL's existing schema.
final class Sprint4MealObserver {
    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()

    func start(userID: String, month: Date, onUpdate: @escaping (Result<[QueryDocumentSnapshot], Error>) -> Void) {
        stop()
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .month, for: month) else { return }
        listener = db.collection("users").document(userID).collection("meals")
            .whereField("createdAt", isGreaterThanOrEqualTo: Timestamp(date: interval.start))
            .whereField("createdAt", isLessThan: Timestamp(date: interval.end))
            .addSnapshotListener { snapshot, error in
                if let error { onUpdate(.failure(error)); return }
                onUpdate(.success(snapshot?.documents ?? []))
            }
    }

    func stop() {
        listener?.remove()
        listener = nil
    }

    deinit { stop() }
}
