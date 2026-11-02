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
