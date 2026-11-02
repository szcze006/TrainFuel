import SwiftUI
import UIKit
import PhotosUI

// MARK: - MEAL ESTIMATE

struct MealEstimate: Codable {
    let isFood: Bool
    let name: String
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
}

enum MealScanError: Error {
    case missingKey
    case rateLimited
    case notFood
    case noResult
}


// MARK: - MEAL PHOTO ANALYZER

enum MealPhotoAnalyzer {

    private static let endpoint = URL(string: "https://openrouter.ai/api/v1/chat/completions")!

    // Tried in order; OpenRouter falls back to the next one if a model is busy or down.
    private static let models = [
        "google/gemma-4-31b-it:free",
        "nvidia/nemotron-3.5-super-vl:free",
        "openrouter/free"
    ]

    private static let maxImageSide: CGFloat = 1024
    private static let timeout: TimeInterval = 60
    private static let retryDelay: Duration = .seconds(2)

    private struct ChatResponse: Decodable {

        struct Choice: Decodable {

            struct Message: Decodable {
                let content: String?
            }

            let message: Message
        }

        let choices: [Choice]?
    }

    static func estimate(from image: UIImage, note: String) async throws -> MealEstimate {

        guard let apiKey = apiKey() else {
            throw MealScanError.missingKey
        }

        guard let imageData = resized(image).jpegData(compressionQuality: 0.8) else {
            throw MealScanError.noResult
        }

        let request = try makeRequest(apiKey: apiKey, imageData: imageData, note: note)

        var (data, response) = try await URLSession.shared.data(for: request)

        if isBusy(response) {
            try await Task.sleep(for: retryDelay)
            (data, response) = try await URLSession.shared.data(for: request)
        }

        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

        guard statusCode == 200 else {
            print("OpenRouter error \(statusCode): \(String(decoding: data, as: UTF8.self))")
            throw statusCode == 429 ? MealScanError.rateLimited : MealScanError.noResult
        }

        guard let content = try JSONDecoder()
            .decode(ChatResponse.self, from: data)
            .choices?.first?.message.content
        else {
            print("OpenRouter returned no answer: \(String(decoding: data, as: UTF8.self))")
            throw MealScanError.noResult
        }

        let estimate = try decodeEstimate(from: content)

        guard estimate.isFood else {
            throw MealScanError.notFood
        }

        return estimate
    }

    private static func apiKey() -> String? {

        guard
            let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
            let secrets = NSDictionary(contentsOf: url),
            let key = secrets["OpenRouterAPIKey"] as? String,
            key.hasPrefix("sk-or-")
        else {
            return nil
        }

        return key
    }

    private static func makeRequest(apiKey: String, imageData: Data, note: String) throws -> URLRequest {

        let imageURL = "data:image/jpeg;base64,\(imageData.base64EncodedString())"

        let body: [String: Any] = [
            "models": models,
            "response_format": ["type": "json_object"],
            "messages": [
                [
                    "role": "user",
                    "content": [
                        ["type": "text", "text": prompt(note: note)],
                        ["type": "image_url", "image_url": ["url": imageURL]]
                    ]
                ]
            ]
        ]

        var request = URLRequest(url: endpoint, timeoutInterval: timeout)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("TrainFUEL", forHTTPHeaderField: "X-Title")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        return request
    }

    private static func isBusy(_ response: URLResponse) -> Bool {

        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

        return statusCode == 429 || statusCode >= 500
    }

    private static func decodeEstimate(from content: String) throws -> MealEstimate {

        // Some models wrap the JSON in extra text or code fences, so only keep the object itself.
        guard
            let start = content.firstIndex(of: "{"),
            let end = content.lastIndex(of: "}")
        else {
            print("OpenRouter answer had no JSON: \(content)")
            throw MealScanError.noResult
        }

        do {
            return try JSONDecoder().decode(
                MealEstimate.self,
                from: Data(content[start...end].utf8)
            )
        } catch {
            print("OpenRouter answer didn't match the expected format: \(content)")
            throw error
        }
    }

    private static func prompt(note: String) -> String {

        var prompt = """
        Estimate the nutrition of the whole meal in this photo.
        Judge portion sizes from the plate and include likely cooking oil, butter and sauces.
        Reply with only a JSON object with these keys:
        "isFood": true or false,
        "name": a short meal name,
        "calories": total calories as a whole number,
        "protein", "carbs", "fat": total grams as whole numbers.
        If the photo does not show food, set isFood to false, name to "" and all numbers to 0.
        """

        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)

        if !trimmedNote.isEmpty {
            prompt += "\nThe user added this note about the meal: \(trimmedNote)"
        }

        return prompt
    }

    private static func resized(_ image: UIImage) -> UIImage {

        let longestSide = max(image.size.width, image.size.height)

        guard longestSide > maxImageSide else {
            return image
        }

        let scale = maxImageSide / longestSide
        let size = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1

        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}


// MARK: - MEAL SCAN SECTION

struct MealScanSection: View {

    let onEstimate: (MealEstimate) -> Void

    @State private var note = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showCamera = false
    @State private var isScanning = false
    @State private var errorMessage: String?

    var body: some View {

        Section {

            TextField(
                "Optional note (e.g. cooked in butter)",
                text: $note,
                axis: .vertical
            )

            if UIImagePickerController.isSourceTypeAvailable(.camera) {

                Button {
                    showCamera = true
                } label: {
                    Label("Take Photo", systemImage: "camera.fill")
                }
                .fullScreenCover(isPresented: $showCamera) {
                    CameraPicker { image in
                        scan { image }
                    }
                    .ignoresSafeArea()
                }
            }

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Label("Choose Photo", systemImage: "photo.on.rectangle")
            }
            .onChange(of: selectedPhoto) { _, item in

                guard let item else {
                    return
                }

                selectedPhoto = nil

                scan {
                    guard let data = try? await item.loadTransferable(type: Data.self) else {
                        return nil
                    }

                    return UIImage(data: data)
                }
            }

            if isScanning {

                HStack(spacing: 10) {
                    ProgressView()
                    Text("Estimating your meal...")
                }
            }

            if let errorMessage {

                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        } header: {
            Text("Scan Meal")
        } footer: {
            Text("These are estimates. Check the numbers before saving.")
        }
        .disabled(isScanning)
    }

    private func scan(_ loadImage: @escaping () async -> UIImage?) {

        Task {
            isScanning = true
            errorMessage = nil

            defer {
                isScanning = false
            }

            guard let image = await loadImage() else {
                errorMessage = "Couldn't open that photo. Try another one."
                return
            }

            do {
                let estimate = try await MealPhotoAnalyzer.estimate(
                    from: image,
                    note: note
                )

                onEstimate(estimate)
            } catch MealScanError.missingKey {
                errorMessage = "Meal scanning isn't set up. Add an OpenRouter key to Secrets.plist."
            } catch MealScanError.rateLimited {
                errorMessage = "Too many scans for now. Try again later or enter the meal by hand."
            } catch MealScanError.notFood {
                errorMessage = "No food found in that photo. Try another one."
            } catch {
                print("Meal scan failed: \(error)")
                errorMessage = "Couldn't scan that photo. Try again or enter the meal by hand."
            }
        }
    }
}


// MARK: - CAMERA PICKER

struct CameraPicker: UIViewControllerRepresentable {

    @Environment(\.dismiss) private var dismiss

    let onImagePicked: (UIImage) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {

        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator

        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

        private let parent: CameraPicker

        init(parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {

            if let image = info[.originalImage] as? UIImage {
                parent.onImagePicked(image)
            }

            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
