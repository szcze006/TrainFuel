import SwiftUI
import VisionKit

/// Use this in the existing meal-entry screen, then map the selected values
/// into the app's current Firestore meal model.
struct TrainFuelBarcodeEntry: View {
    @State private var food: ScannedFood?
    @State private var grams = 100.0
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
