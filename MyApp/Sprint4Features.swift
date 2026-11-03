import Foundation

/// Lookup for packaged foods using Open Food Facts. All values are per 100 g.
struct ScannedFood: Identifiable, Codable {
    var id: String { barcode }
    let barcode: String
    let name: String
    let caloriesPer100g: Double
    let proteinPer100g: Double
    let carbsPer100g: Double
    let fatPer100g: Double

    func nutrients(forGrams grams: Double) -> (calories: Double, protein: Double, carbs: Double, fat: Double) {
        let factor = max(0, grams) / 100
        return (caloriesPer100g * factor, proteinPer100g * factor, carbsPer100g * factor, fatPer100g * factor)
    }
}

enum FoodLookupError: LocalizedError {
    case invalidBarcode, notFound, invalidResponse
    var errorDescription: String? {
        switch self {
        case .invalidBarcode: return "Please scan a valid food barcode."
        case .notFound: return "This barcode is not in the food database."
        case .invalidResponse: return "Nutrition details are not available for this product."
        }
    }
}

final class FoodLookupService {
    private struct Response: Decodable {
        let status: Int
        let product: Product?
    }
    private struct Product: Decodable {
        let product_name: String?
        let nutriments: Nutriments?
    }
    private struct Nutriments: Decodable {
        let energy_kcal_100g: Double?
        let proteins_100g: Double?
        let carbohydrates_100g: Double?
        let fat_100g: Double?
    }

    func lookup(barcode: String) async throws -> ScannedFood {
        guard barcode.count >= 8, barcode.allSatisfy({ $0.isNumber }) else { throw FoodLookupError.invalidBarcode }
        guard let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(barcode).json?fields=product_name,nutriments") else {
            throw FoodLookupError.invalidBarcode
        }
        var request = URLRequest(url: url)
        request.setValue("TrainFUEL/1.0 (student project; nutrition lookup)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 12
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw FoodLookupError.invalidResponse
        }
        let result = try JSONDecoder().decode(Response.self, from: data)
        guard result.status == 1, let product = result.product else { throw FoodLookupError.notFound }
        guard let nutrients = product.nutriments else { throw FoodLookupError.invalidResponse }
        return ScannedFood(
            barcode: barcode,
            name: product.product_name?.isEmpty == false ? product.product_name! : "Scanned food",
            caloriesPer100g: nutrients.energy_kcal_100g ?? 0,
            proteinPer100g: nutrients.proteins_100g ?? 0,
            carbsPer100g: nutrients.carbohydrates_100g ?? 0,
            fatPer100g: nutrients.fat_100g ?? 0
        )
    }
}


import SwiftUI
import VisionKit

/// Use this in the existing meal-entry screen, then map the selected values
/// into the app's current Firestore meal model.
struct TrainFuelBarcodeEntry: View {
    @State private var food: ScannedFood?
    @State private var grams = 100.0
    @State private var manualBarcode = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    let onUseFood: (ScannedFood, Double) -> Void

    var body: some View {
        VStack(spacing: 14) {
            Text("Scan a food barcode").font(.headline)
            if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                BarcodeCameraView { code in
                    Task { await loadFood(code) }
                }
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                Text("Barcode scanning requires a supported iPhone with camera access.")
                    .foregroundStyle(.secondary)
            }
            HStack {
                TextField("Enter barcode numbers", text: $manualBarcode)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                Button("Look up") {
                    Task { await loadFood(manualBarcode.trimmingCharacters(in: .whitespacesAndNewlines)) }
                }
                .disabled(manualBarcode.count < 8 || isLoading)
            }
            #if targetEnvironment(simulator)
            Text("Camera scanning is unavailable in the simulator. Enter a barcode above to test the food API.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            #endif
            if isLoading { ProgressView("Looking up nutrition…") }
            if let food {
                Text(food.name).font(.title3.bold())
                HStack {
                    Text("Serving size (grams)")
                    TextField("100", value: $grams, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                }
                let n = food.nutrients(forGrams: grams)
                Text("\(Int(n.calories.rounded())) kcal · P \(n.protein, specifier: "%.1f")g · C \(n.carbs, specifier: "%.1f")g · F \(n.fat, specifier: "%.1f")g")
                    .font(.footnote)
                Button("Use this food") { onUseFood(food, grams) }
                    .buttonStyle(.borderedProminent)
                    .disabled(grams <= 0)
            }
            if let errorMessage { Text(errorMessage).foregroundStyle(.red).font(.footnote) }
        }
        .padding()
    }

    @MainActor private func loadFood(_ code: String) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        do { food = try await FoodLookupService().lookup(barcode: code) }
        catch { errorMessage = error.localizedDescription }
        isLoading = false
    }
}

@available(iOS 16.0, *)
private struct BarcodeCameraView: UIViewControllerRepresentable {
    let onBarcode: (String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onBarcode: onBarcode) }
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let controller = DataScannerViewController(
            recognizedDataTypes: [.barcode()],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        controller.delegate = context.coordinator
        try? controller.startScanning()
        return controller
    }
    func updateUIViewController(_ controller: DataScannerViewController, context: Context) {}
    static func dismantleUIViewController(_ controller: DataScannerViewController, coordinator: Coordinator) {
        controller.stopScanning()
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onBarcode: (String) -> Void
        private var lastCode: String?
        init(onBarcode: @escaping (String) -> Void) { self.onBarcode = onBarcode }
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            for item in addedItems {
                guard case .barcode(let barcode) = item, let value = barcode.payloadStringValue, value != lastCode else { continue }
                lastCode = value
                onBarcode(value)
                break
            }
        }
    }
}


import SwiftUI

/// Month-at-a-glance counts. Select a day to show its logged meals below.
struct Sprint4MealCalendar: View {
    @ObservedObject var mealStore: MealStore
    @Binding var selectedDay: Date
    private let calendar = Calendar.current
    private var month: Date { calendar.dateInterval(of: .month, for: selectedDay)?.start ?? selectedDay }
    private var days: [Date] {
        guard let interval = calendar.dateInterval(of: .month, for: month),
              let count = calendar.range(of: .day, in: .month, for: month) else { return [] }
        let offset = (calendar.component(.weekday, from: interval.start) - calendar.firstWeekday + 7) % 7
        return Array(repeating: Date.distantPast, count: offset) + count.compactMap {
            calendar.date(byAdding: .day, value: $0 - 1, to: interval.start)
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Meals this month").font(.headline)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 8) {
                ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                    if day == .distantPast {
                        Color.clear.frame(height: 42)
                    } else {
                        let count = mealStore.meals(on: day).count
                        Button {
                            selectedDay = day
                        } label: {
                            VStack(spacing: 2) {
                                Text("\(calendar.component(.day, from: day))").font(.caption)
                                if count > 0 {
                                    Text("\(count)").font(.caption2.bold()).foregroundStyle(.white)
                                        .frame(minWidth: 17, minHeight: 17)
                                        .background(Color.trainBlue, in: Circle())
                                } else {
                                    Color.clear.frame(height: 17)
                                }
                            }
                            .frame(maxWidth: .infinity, minHeight: 42)
                            .background(calendar.isDate(day, inSameDayAs: selectedDay) ? Color.trainLightBlue : Color.clear, in: RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            Text("A numbered dot shows how many meals you logged that day.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}
