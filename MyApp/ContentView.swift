// xcode: set sdk=iOS

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

// MARK: - COLORS

extension Color {
    static let trainBlue = Color(red: 0.08, green: 0.35, blue: 0.95)
    static let trainLightBlue = Color(red: 0.92, green: 0.96, blue: 1.0)
    static let trainBackground = Color(red: 0.97, green: 0.98, blue: 1.0)
}


// MARK: - MEAL MODEL


struct FoodEntry: Identifiable, Codable {
    let id: UUID
    let name: String
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let date: Date

    init(
        id: UUID = UUID(),
        name: String,
        calories: Int,
        protein: Int,
        carbs: Int,
        fat: Int,
        date: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.date = date
    }
}



// MARK: - MEAL STORE

final class MealStore: ObservableObject {
    
    @Published var foods: [FoodEntry] = []
    
    private let db = Firestore.firestore()
    
    init() {
        loadMealsFromFirebase()
    }
    
    var totalCalories: Int {
        foods.reduce(0) { $0 + $1.calories }
    }
    
    var totalProtein: Int {
        foods.reduce(0) { $0 + $1.protein }
    }
    
    var totalCarbs: Int {
        foods.reduce(0) { $0 + $1.carbs }
    }
    
    var totalFat: Int {
        foods.reduce(0) { $0 + $1.fat }
    }
    
    func meals(on date: Date) -> [FoodEntry] {
        foods.filter {
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }
    }
    
    func totalCalories(on date: Date) -> Int {
        meals(on: date).reduce(0) { $0 + $1.calories }
    }
    
    func totalProtein(on date: Date) -> Int {
        meals(on: date).reduce(0) { $0 + $1.protein }
    }
    
    func totalCarbs(on date: Date) -> Int {
        meals(on: date).reduce(0) { $0 + $1.carbs }
    }
    
    func totalFat(on date: Date) -> Int {
        meals(on: date).reduce(0) { $0 + $1.fat }
    }
    
    
    // MARK: - Add Meal
    
    func addMeal(_ meal: FoodEntry) {
        
        // Immediately show the meal in the app
        foods.append(meal)
        
        // Make sure the user is logged in
        guard let uid = Auth.auth().currentUser?.uid else {
            print("No logged-in user.")
            return
        }
        
        // Data that will be stored in Firestore
        let mealData: [String: Any] = [
            "name": meal.name,
            "calories": meal.calories,
            "protein": meal.protein,
            "carbs": meal.carbs,
            "fat": meal.fat,
            "date": Timestamp(date: meal.date)
        ]
        
        // users → UID → meals → meal ID
        db.collection("users")
            .document(uid)
            .collection("meals")
            .document(meal.id.uuidString)
            .setData(mealData) { error in
                
                if let error = error {
                    print("Error saving meal: \(error.localizedDescription)")
                } else {
                    print("Meal successfully saved to Firestore.")
                }
            }
    }
    
    // MARK: - Delete Meal
    
    func deleteMeals(at offsets: IndexSet) {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        for index in offsets {
            
            let meal = foods[index]
            
            db.collection("users")
                .document(uid)
                .collection("meals")
                .document(meal.id.uuidString)
                .delete { error in
                    
                    if let error = error {
                        print("Error deleting meal: \(error.localizedDescription)")
                    } else {
                        print("Meal deleted from Firestore.")
                    }
                }
        }
        
        foods.remove(atOffsets: offsets)
    }
    
    // MARK: - Load Meals
    
    
    private func loadMealsFromFirebase() {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            print("No logged-in user.")
            return
        }
        
        db.collection("users")
            .document(uid)
            .collection("meals")
            .getDocuments { snapshot, error in
                
                if let error = error {
                    print("Error loading meals: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    return
                }
                
                let loadedMeals = documents.compactMap { document -> FoodEntry? in
                    
                    let data = document.data()
                    
                    guard
                        let name = data["name"] as? String,
                        let calories = data["calories"] as? Int,
                        let protein = data["protein"] as? Int,
                        let carbs = data["carbs"] as? Int,
                        let fat = data["fat"] as? Int
                    else {
                        return nil
                    }
                    
                    // Read the saved date from Firebase.
                    let mealDate: Date
                    
                    if let timestamp = data["date"] as? Timestamp {
                        mealDate = timestamp.dateValue()
                    } else {
                        // Don't count older records with missing dates as today's meals.
                        mealDate = .distantPast
                    }
    
                    return FoodEntry(
                        id: UUID(uuidString: document.documentID) ?? UUID(),
                        name: name,
                        calories: calories,
                        protein: protein,
                        carbs: carbs,
                        fat: fat,
                        date: mealDate
                    )
                }
                
                DispatchQueue.main.async {
                    self.foods = loadedMeals
                }
            }
    }
}
// MARK: - WORKOUT MODEL
struct WorkoutEntry: Identifiable, Codable {
    var id = UUID()
    let name: String
    let type: String
    let duration: Int
    let date: Date
}

// MARK: - WORKOUT STORE

final class WorkoutStore: ObservableObject {

    @Published var workouts: [WorkoutEntry] = []

    private let db = Firestore.firestore()

    init() {
        loadWorkoutsFromFirebase()
    }

    // MARK: - Add Workout

    func addWorkout(
        name: String,
        type: String,
        duration: Int
    ) {

        guard let uid = Auth.auth().currentUser?.uid else {
            print("No logged-in user.")
            return
        }

        let workout = WorkoutEntry(
            name: name,
            type: type,
            duration: duration,
            date: Date()
        )

        // Show immediately in the app
        workouts.append(workout)

        let workoutData: [String: Any] = [
            "name": workout.name,
            "type": workout.type,
            "duration": workout.duration,
            "date": FirebaseFirestore.Timestamp(date: workout.date)
        ]

        db.collection("users")
            .document(uid)
            .collection("workouts")
            .document(workout.id.uuidString)
            .setData(workoutData) { error in

                if let error = error {
                    print(
                        "Error saving workout: \(error.localizedDescription)"
                    )
                } else {
                    print("Workout successfully saved to Firestore.")
                }
            }
    }

    // MARK: - Delete Workout

    func deleteWorkouts(at offsets: IndexSet) {

        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }

        for index in offsets {

            let workout = workouts[index]

            db.collection("users")
                .document(uid)
                .collection("workouts")
                .document(workout.id.uuidString)
                .delete { error in

                    if let error = error {
                        print(
                            "Error deleting workout: \(error.localizedDescription)"
                        )
                    } else {
                        print("Workout deleted from Firestore.")
                    }
                }
        }

        workouts.remove(atOffsets: offsets)
    }

    // MARK: - Load Workouts

    private func loadWorkoutsFromFirebase() {

        guard let uid = Auth.auth().currentUser?.uid else {
            print("No logged-in user.")
            return
        }

        db.collection("users")
            .document(uid)
            .collection("workouts")
            .getDocuments { snapshot, error in

                if let error = error {
                    print(
                        "Error loading workouts: \(error.localizedDescription)"
                    )
                    return
                }

                guard let documents = snapshot?.documents else {
                    return
                }

                let loadedWorkouts = documents.compactMap {
                    document -> WorkoutEntry? in

                    let data = document.data()

                    guard
                        let name = data["name"] as? String,
                        let type = data["type"] as? String,
                        let duration = data["duration"] as? Int,
                        let timestamp =
                            data["date"]
                            as? FirebaseFirestore.Timestamp
                    else {
                        return nil
                    }

                    return WorkoutEntry(
                        id: UUID(
                            uuidString: document.documentID
                        ) ?? UUID(),
                        name: name,
                        type: type,
                        duration: duration,
                        date: timestamp.dateValue()
                    )
                }

                DispatchQueue.main.async {
                    self.workouts = loadedWorkouts

                    print(
                        "Workouts successfully loaded from Firestore."
                    )
                }
            }
    }
}


// MARK: - TRAINING NOTE STORE


final class NoteStore: ObservableObject {

    // Keyed by "yyyy-MM-dd", one note per day
    @Published var notes: [String: String] = [:]

    private let db = Firestore.firestore()
    private var pendingSaves: [String: DispatchWorkItem] = [:]

    init() {
        // Old single note shared by every day; no longer used
        UserDefaults.standard.removeObject(forKey: "sprint3.calendar.notes")
        loadNotesFromFirebase()
    }

    static func dateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    func note(for day: Date) -> String {
        notes[Self.dateKey(day)] ?? ""
    }

    // MARK: - Save Note

    func saveNote(_ text: String, for day: Date) {

        let key = Self.dateKey(day)

        // Show immediately in the app
        notes[key] = text.isEmpty ? nil : text

        // Wait until typing pauses before writing to Firestore
        pendingSaves[key]?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.writeNote(text, key: key)
        }
        pendingSaves[key] = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: work)
    }

    private func writeNote(_ text: String, key: String) {

        pendingSaves[key] = nil

        guard let uid = Auth.auth().currentUser?.uid else {
            print("No logged-in user.")
            return
        }

        let document = db.collection("users")
            .document(uid)
            .collection("trainingNotes")
            .document(key)

        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            document.delete { error in
                if let error = error {
                    print("Error deleting note: \(error.localizedDescription)")
                }
            }
        } else {
            document.setData([
                "text": text,
                "updatedAt": FirebaseFirestore.Timestamp(date: Date())
            ]) { error in
                if let error = error {
                    print("Error saving note: \(error.localizedDescription)")
                } else {
                    print("Note successfully saved to Firestore.")
                }
            }
        }
    }

    // MARK: - Load Notes

    private func loadNotesFromFirebase() {

        guard let uid = Auth.auth().currentUser?.uid else {
            print("No logged-in user.")
            return
        }

        db.collection("users")
            .document(uid)
            .collection("trainingNotes")
            .getDocuments { snapshot, error in

                if let error = error {
                    print(
                        "Error loading notes: \(error.localizedDescription)"
                    )
                    return
                }

                guard let documents = snapshot?.documents else {
                    return
                }

                var loadedNotes: [String: String] = [:]
                for document in documents {
                    if let text = document.data()["text"] as? String {
                        loadedNotes[document.documentID] = text
                    }
                }

                DispatchQueue.main.async {
                    // Keep anything typed before the load finished
                    self.notes = loadedNotes.merging(self.notes) { _, local in local }

                    print("Notes successfully loaded from Firestore.")
                }
            }
    }
}
// MARK: - FITNESS PROFILE


struct FitnessProfile: Codable {
    var sport: String = ""
    var goal: String = ""
    var trainingDays: Int = 4
    var calorieGoal: Int = 2500
    var proteinGoal: Int = 180
    var carbsGoal: Int = 300
    var fatGoal: Int = 80

    // Personal details for TFUEL-54
    // Zero means the user has not entered this measurement.
    var age: Int = 0
    var heightCm: Double = 0
    var weightKg: Double = 0
    var activityLevel: String = "Moderately Active"
    var metabolicEquationSex: String = "Prefer not to say"
    var measurementUnits: String = "Metric"

    var isComplete: Bool {
        !sport.isEmpty && !goal.isEmpty
    }

    var hasValidPersonalDetails: Bool {
        (18...100).contains(age) &&
        (100...250).contains(heightCm) &&
        (30...350).contains(weightKg)
    }
}

struct NutritionTargets {
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
}

enum NutritionCalculator {

    static func calculate(
        profile: FitnessProfile
    ) -> NutritionTargets? {

        guard profile.hasValidPersonalDetails else {
            return nil
        }

        let weight = profile.weightKg
        let height = profile.heightCm
        let age = Double(profile.age)

        // Mifflin–St Jeor equation.
        let sexAdjustment: Double

        switch profile.metabolicEquationSex {
        case "Male":
            sexAdjustment = 5
        case "Female":
            sexAdjustment = -161
        default:
            // Neutral midpoint when the user prefers not to say.
            sexAdjustment = -78
        }

        let bmr =
            (10 * weight) +
            (6.25 * height) -
            (5 * age) +
            sexAdjustment

        let activityMultiplier: Double

        switch profile.activityLevel {
        case "Sedentary":
            activityMultiplier = 1.2
        case "Lightly Active":
            activityMultiplier = 1.375
        case "Moderately Active":
            activityMultiplier = 1.55
        case "Very Active":
            activityMultiplier = 1.725
        case "Extra Active":
            activityMultiplier = 1.9
        default:
            activityMultiplier = 1.55
        }

        let maintenanceCalories = bmr * activityMultiplier

        let calorieAdjustment: Double

        switch profile.goal {
        case "Build Muscle":
            calorieAdjustment = 1.10
        case "Lose Fat":
            calorieAdjustment = 0.85
        case "Maintain Weight":
            calorieAdjustment = 1.0
        case "Improve Performance":
            calorieAdjustment = 1.05
        default:
            calorieAdjustment = 1.0
        }

        let calories = max(
            1200,
            Int((maintenanceCalories * calorieAdjustment).rounded())
        )

        // Protein targets in grams per kilogram of body weight.
        let proteinMultiplier: Double

        switch profile.goal {
        case "Build Muscle":
            proteinMultiplier = 2.0
        case "Lose Fat":
            proteinMultiplier = 2.0
        case "Maintain Weight":
            proteinMultiplier = 1.6
        case "Improve Performance":
            proteinMultiplier = 1.8
        default:
            proteinMultiplier = 1.6
        }

        let protein = Int(
            (weight * proteinMultiplier).rounded()
        )

        let macros = carbsAndFat(
            calories: calories,
            protein: protein
        )

        return NutritionTargets(
            calories: calories,
            protein: protein,
            carbs: macros.carbs,
            fat: macros.fat
        )
    }

    // Split remaining calories 2:1 between carbs and fat.
    static func carbsAndFat(
        calories: Int,
        protein: Int
    ) -> (carbs: Int, fat: Int) {

        let remainingCalories = max(
            0,
            calories - (protein * 4)
        )

        let carbs = Int(
            (Double(remainingCalories) * (2.0 / 3.0) / 4).rounded()
        )

        let fat = Int(
            (Double(remainingCalories) * (1.0 / 3.0) / 9).rounded()
        )

        return (carbs, fat)
    }
}

// MARK: - PROFILE STORE

final class ProfileStore: ObservableObject {

    @Published var profile: FitnessProfile {
        didSet {
            saveProfileToFirebase()
        }
    }
    func updateNutritionTargets() {
        guard let targets = NutritionCalculator.calculate(
            profile: profile
        ) else {
            return
        }

        var updatedProfile = profile
        updatedProfile.calorieGoal = targets.calories
        updatedProfile.proteinGoal = targets.protein
        updatedProfile.carbsGoal = targets.carbs
        updatedProfile.fatGoal = targets.fat

        profile = updatedProfile
    }

    private let db = Firestore.firestore()

    init() {
        profile = FitnessProfile()
        loadProfileFromFirebase()
    }

    private var userID: String? {
        Auth.auth().currentUser?.uid
    }

    private var profileReference: DocumentReference? {
        guard let uid = userID else {
            return nil
        }

        return db
            .collection("users")
            .document(uid)
            .collection("profile")
            .document("profile")
    }

    // MARK: - Save Profile

    private func saveProfileToFirebase() {

        guard let profileReference = profileReference else {
            print("No logged-in user. Profile was not saved.")
            return
        }

        let profileData: [String: Any] = [
            "sport": profile.sport,
            "goal": profile.goal,
            "trainingDays": profile.trainingDays,
            "calorieGoal": profile.calorieGoal,
            "proteinGoal": profile.proteinGoal,
            "carbsGoal": profile.carbsGoal,
            "fatGoal": profile.fatGoal,
            
            "age": profile.age,
            "heightCm": profile.heightCm,
            "weightKg": profile.weightKg,
            "activityLevel": profile.activityLevel,
            "metabolicEquationSex": profile.metabolicEquationSex,
            "measurementUnits": profile.measurementUnits

        ]

        profileReference.setData(profileData) { error in

            if let error = error {
                print(
                    "Error saving profile: \(error.localizedDescription)"
                )
            } else {
                print("Profile successfully saved to Firestore.")
            }
        }
    }

    // MARK: - Load Profile

    private func loadProfileFromFirebase() {

        guard let profileReference = profileReference else {
            print("No logged-in user. Cannot load profile.")
            return
        }

        profileReference.getDocument { document, error in

            if let error = error {
                print(
                    "Error loading profile: \(error.localizedDescription)"
                )
                return
            }

            guard
                let document = document,
                document.exists,
                let data = document.data()
            else {
                print("No profile found in Firestore.")
                return
            }

            let loadedProfile = FitnessProfile(
                sport: data["sport"] as? String ?? "",
                goal: data["goal"] as? String ?? "",
                trainingDays: data["trainingDays"] as? Int ?? 4,
                calorieGoal: data["calorieGoal"] as? Int ?? 2500,
                proteinGoal: data["proteinGoal"] as? Int ?? 180,
                carbsGoal: data["carbsGoal"] as? Int ?? 300,
                fatGoal: data["fatGoal"] as? Int ?? 80,
                
                age: data["age"] as? Int ?? 0,
                heightCm: data["heightCm"] as? Double ?? 0,
                weightKg: data["weightKg"] as? Double ?? 0,
                activityLevel: data["activityLevel"] as? String ?? "Moderately Active",
                metabolicEquationSex: data["metabolicEquationSex"] as? String ?? "Prefer not to say",
                
                measurementUnits: data["measurementUnits"] as? String ?? "Metric"

            )

            DispatchQueue.main.async {
                self.profile = loadedProfile
                print("Profile successfully loaded from Firestore.")
            }
        }
    }

    // MARK: - Recommendations

    var recommendationTitle: String {
        switch profile.sport {
        case "Soccer":
            return "Soccer Fuel Plan"

        case "Basketball":
            return "Basketball Fuel Plan"

        case "Football":
            return "Football Fuel Plan"

        case "Running":
            return "Running Fuel Plan"

        case "Volleyball":
            return "Volleyball Fuel Plan"

        case "Weight Training":
            return "Strength Fuel Plan"

        default:
            return "Your Fuel Plan"
        }
    }

    var recommendation: String {

        switch profile.sport {

        case "Weight Training":

            switch profile.goal {

            case "Build Muscle":
                return "Focus on reaching your calorie and protein goals. Include carbohydrates around your workouts to support training and recovery."

            case "Lose Fat":
                return "Keep protein high while staying within your calorie goal. Build meals around lean protein and filling foods."

            case "Improve Performance":
                return "Fuel your workouts with enough carbohydrates and keep protein consistent throughout the day."

            default:
                return "Stay consistent with your calories and protein while supporting your workouts with balanced meals."
            }

        case "Soccer":
            return "Prioritize carbohydrates before practices and games for energy. After training, combine protein and carbohydrates to support recovery."

        case "Basketball":
            return "Eat enough carbohydrates before training for repeated bursts of energy. Include protein after sessions to support recovery."

        case "Football":
            return "Focus on enough total calories, carbohydrates, and protein to support strength, power, and recovery."

        case "Running":
            return "Carbohydrates are important for running performance. Fuel before longer sessions and include protein afterward for recovery."

        case "Volleyball":
            return "Use carbohydrates for training energy and spread protein throughout the day to support recovery."

        default:
            return "Build balanced meals around your training goals and stay consistent with your nutrition."
        }
    }
    
    var hydrationRecommendation: String {
        switch profile.sport {
        case "Soccer":
            return "Hydration Tip: Drink water throughout the day and make sure you are hydrated before practices and games."

        case "Basketball":
            return "Hydration Tip: Keep water available during training and replace fluids after intense sessions."

        case "Football":
            return "Hydration Tip: Hydration is especially important during long practices and hot weather."

        case "Running":
            return "Hydration Tip: Drink consistently throughout the day and pay extra attention to fluids during longer runs."

        case "Volleyball":
            return "Hydration Tip: Stay hydrated before practice and drink fluids during longer training sessions."

        case "Weight Training":
            return "Hydration Tip: Drink water before, during, and after your workout to support training and recovery."

        default:
            return "Hydration Tip: Drink water consistently throughout the day, especially around exercise."
        }
    }
}


// MARK: - ROOT


struct ContentView: View {

    @State private var user = Auth.auth().currentUser
    @State private var verificationCompleted = false

    var body: some View {
        Group {
            if let currentUser = user {
                if currentUser.isEmailVerified ||
                    verificationCompleted ||
                    currentUser.providerData.contains(where: {
                        $0.providerID == "apple.com"
                    }) {
                    MainTabView(user: $user)
                } else {
                    EmailVerificationView(
                        user: $user,
                        onVerified: {
                            verificationCompleted = true
                            user = Auth.auth().currentUser
                        }
                    )
                }
            } else {
                WelcomeView(user: $user)
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            user = Auth.auth().currentUser
        }
    }
}



// MARK: - WELCOME

struct WelcomeView: View {

    @Binding var user: User?

    @State private var showLogin = false
    @State private var showSignup = false

    var body: some View {

        NavigationStack {

            ZStack {

                LinearGradient(
                    colors: [
                        Color.trainBlue,
                        Color.blue.opacity(0.65)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 22) {

                    Spacer()

                    Image(systemName: "bolt.heart.fill")
                        .font(.system(size: 76))
                        .foregroundStyle(Color.white)

                    Text("TrainFUEL")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(Color.white)

                    Text("Fuel your goals. Train your way.")
                        .font(.headline)
                        .foregroundStyle(Color.white.opacity(0.85))

                    Spacer()

                    Button {
                        showSignup = true
                    } label: {
                        Text("Create Account")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundStyle(Color.trainBlue)
                            .clipShape(
                                RoundedRectangle(cornerRadius: 16)
                            )
                    }

                    Button {
                        showLogin = true
                    } label: {
                        Text("I Already Have an Account")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundStyle(Color.white)
                            .overlay {
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white, lineWidth: 2)
                            }
                    }
                }
                .padding(30)
                .padding(.bottom, 30)
            }

            .navigationDestination(isPresented: $showLogin) {
                LoginView(user: $user)
            }

            .navigationDestination(isPresented: $showSignup) {
                SignUpView(user: $user)
            }
        }
    }
}


// MARK: - LOGIN

struct LoginView: View {

    @Binding var user: User?

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showResetAlert = false
    @State private var resetMessage = ""

    var body: some View {

        VStack(spacing: 20) {

            Spacer()

            Image(systemName: "bolt.fill")
                .font(.system(size: 52))
                .foregroundStyle(Color.trainBlue)

            Text("Welcome Back")
                .font(.largeTitle.bold())

            Text("Sign in to continue to TrainFUEL")
                .foregroundStyle(Color.secondary)

            TextField("Email", text: $email)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.emailAddress)
                .padding()
                .background(Color.trainLightBlue)
                .clipShape(RoundedRectangle(cornerRadius: 14))

            SecureField("Password", text: $password)
                .padding()
                .background(Color.trainLightBlue)
                .clipShape(RoundedRectangle(cornerRadius: 14))

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(Color.red)
            }

            Button {
                login()
            } label: {

                if isLoading {
                    ProgressView()
                        .tint(Color.white)
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Log In")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .background(Color.trainBlue)
            .foregroundStyle(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .disabled(isLoading || email.isEmpty || password.isEmpty)
            
            Button("Forgot Password?") {
                sendPasswordReset()
            }
            .font(.subheadline)
            .foregroundStyle(Color.trainBlue)
            .disabled(isLoading || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            Spacer()
        }
        .padding(25)
        .navigationTitle("Log In")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Password Reset", isPresented: $showResetAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(resetMessage)
        }
    }

    private func login() {

        errorMessage = ""
        isLoading = true

        Auth.auth().signIn(
            withEmail: email,
            password: password
        ) { result, error in

            isLoading = false

            if let error = error as NSError? {
                switch AuthErrorCode(rawValue: error.code) {
                case .wrongPassword, .invalidCredential:
                    errorMessage = "Email or password is incorrect."
                case .invalidEmail:
                    errorMessage = "Please enter a valid email address."
                case .userDisabled:
                    errorMessage = "This account has been disabled. Contact support."
                case .networkError:
                    errorMessage = "Network error. Check your internet connection."
                case .tooManyRequests:
                    errorMessage = "Too many attempts. Please try again later."
                default:
                    errorMessage = "Unable to log in. Please try again."
                }
                return
            }

            user = result?.user
        }
    }
    
    private func sendPasswordReset() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        errorMessage = ""

        guard !trimmedEmail.isEmpty else {
            errorMessage = "Please enter your email address first."
            return
        }

        isLoading = true

        Auth.auth().sendPasswordReset(withEmail: trimmedEmail) { error in
            isLoading = false

            if let error = error {
                errorMessage = "Unable to send reset email. Check the email address and try again."
                print("Password reset error: \(error.localizedDescription)")
                return
            }

            resetMessage = "If an account exists for this email, a password reset email has been sent."
            showResetAlert = true
        }
    }
}


// MARK: - SIGN UP

struct SignUpView: View {

    @Binding var user: User?

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false


    var body: some View {

        ScrollView {

            VStack(spacing: 20) {

                Image(systemName: "figure.run.circle.fill")
                    .font(.system(size: 68))
                    .foregroundStyle(Color.trainBlue)
                    .padding(.top, 30)

                Text("Create Your Account")
                    .font(.largeTitle.bold())

                Text("Start building your nutrition plan.")
                    .foregroundStyle(Color.secondary)

                TextField("Name", text: $name)
                    .padding()
                    .background(Color.trainLightBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
                    .padding()
                    .background(Color.trainLightBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                SecureField("Password", text: $password)
                    .padding()
                    .background(Color.trainLightBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                Text("Password must contain at least 6 characters.")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(Color.red)
                }

                Button {
                    createAccount()
                } label: {

                    if isLoading {
                        ProgressView()
                            .tint(Color.white)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Create Account")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(Color.trainBlue)
                .foregroundStyle(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .disabled(isLoading)
            }
            .padding(25)
        }
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
        
        
    }
    

    private func createAccount() {

        errorMessage = ""

        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter your name."
            return
        }

        guard !email.isEmpty else {
            errorMessage = "Please enter your email."
            return
        }

        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            return
        }

        isLoading = true

        Auth.auth().createUser(
            withEmail: email,
            password: password
        ) { result, error in

            if let error = error as NSError? {
                isLoading = false

                switch AuthErrorCode(rawValue: error.code) {
                case .emailAlreadyInUse:
                    errorMessage = "An account with this email already exists."
                case .invalidEmail:
                    errorMessage = "Please enter a valid email address."
                case .weakPassword:
                    errorMessage = "Please choose a stronger password."
                case .networkError:
                    errorMessage = "Network error. Check your internet connection."
                case .tooManyRequests:
                    errorMessage = "Too many attempts. Please try again later."
                default:
                    errorMessage = "Unable to create your account. Please try again."
                }

                return
            }

            guard let firebaseUser = result?.user else {
                isLoading = false
                errorMessage = "Account could not be created."
                return
            }

            let request = firebaseUser.createProfileChangeRequest()
            request.displayName = name

            request.commitChanges { error in

                if error != nil {
                    DispatchQueue.main.async {
                        isLoading = false
                        errorMessage = "Your account was created, but your profile could not be saved. Please try signing in again."
                    }
                    return
                }

                firebaseUser.sendEmailVerification { error in
                    DispatchQueue.main.async {
                        isLoading = false

                        if error != nil {
                            errorMessage = "Your account was created, but we couldn't send the verification email. Please try signing in to resend it."
                            return
                        }

                        user = Auth.auth().currentUser
                    }
                }
            }
        }
    }
}

// MARK: - EMAIL VERIFICATION VIEW
struct EmailVerificationView: View {

    @Binding var user: User?
    var onVerified: () -> Void
    @Environment(\.scenePhase) private var scenePhase

    @State private var message = ""
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 22) {

            Image(systemName: "envelope.badge.shield.half.filled")
                .font(.system(size: 68))
                .foregroundStyle(Color.trainBlue)

            Text("Verify Your Email")
                .font(.largeTitle.bold())

            Text("We've sent a verification link to:")
                .foregroundStyle(.secondary)

            Text(user?.email ?? "your email address")
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            Text("Verify your email using the link we sent. Then return here to continue to TrainFUEL.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            if !message.isEmpty {
                Text(message)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.trainBlue)
            }

            Button {
                checkVerification()
            } label: {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("I've Verified My Email")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .background(Color.trainBlue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .disabled(isLoading)

            Button("Resend Verification Email") {
                resendVerification()
            }
            .foregroundStyle(Color.trainBlue)
            .disabled(isLoading)

            Button("Sign Out", role: .destructive) {
                do {
                    try Auth.auth().signOut()
                    user = nil
                } catch {
                    message = "Unable to sign out. Please try again."
                }
            }
        }
        .padding(28)
        .onAppear {
            checkVerification()
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                checkVerification()
            }
        }
    }

    private func checkVerification() {
        guard let currentUser = Auth.auth().currentUser else {
            user = nil
            return
        }

        isLoading = true

        currentUser.reload { error in
            DispatchQueue.main.async {
                isLoading = false

                if error != nil {
                    message = "Couldn't check verification status. Check your connection and try again."
                    return
                }

                guard let refreshedUser = Auth.auth().currentUser else {
                    user = nil
                    return
                }

                
                user = refreshedUser
                print("Email verified:", refreshedUser.isEmailVerified)

                if refreshedUser.isEmailVerified {
                    message = "Email verified! Opening TrainFUEL..."
                    onVerified()
                } else {
                    message = "Your email isn't verified yet. Open the verification link in your inbox, then try again."
                }

            }
        }
    }

    private func resendVerification() {
        guard let currentUser = Auth.auth().currentUser else {
            user = nil
            return
        }

        isLoading = true

        currentUser.sendEmailVerification { error in
            DispatchQueue.main.async {
                isLoading = false

                if error != nil {
                    message = "Couldn't send the email. Check your connection and try again."
                } else {
                    message = "Verification email sent. Check your inbox and spam folder."
                }
            }
        }
    }
}

// MARK: - MAIN APP

struct MainTabView: View {

    @Binding var user: User?

    @StateObject private var mealStore = MealStore()
    @StateObject private var profileStore = ProfileStore()
    @StateObject private var workoutStore = WorkoutStore()
    @StateObject private var noteStore = NoteStore()

    var body: some View {

        Group {

            if profileStore.profile.isComplete {

                TabView {

                    DashboardView(
                        mealStore: mealStore,
                        profileStore: profileStore
                    )
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }

                    NutritionView(
                        mealStore: mealStore,
                        profileStore: profileStore
                    )
                        .tabItem {
                            Label("Nutrition", systemImage: "fork.knife")
                        }
                    TrainingPlanView(profileStore: profileStore, workoutStore: workoutStore, mealStore: mealStore, noteStore: noteStore)
                        .tabItem { Label("Plan", systemImage: "calendar") }

                    FitnessView(workoutStore: workoutStore)
                        .tabItem {
                            Label("Fitness", systemImage: "figure.run")
                        }

                    PerformanceHubView(
                        profileStore: profileStore,
                        workoutStore: workoutStore,
                        mealStore: mealStore,
                        noteStore: noteStore
                    )
                    .tabItem {
                        Label("Performance", systemImage: "chart.bar.fill")
                    }

                    ProgressScreen(
                        mealStore: mealStore,
                        profileStore: profileStore,
                        workoutStore: workoutStore
                    )
                    .tabItem {
                        Label(
                            "Progress",
                            systemImage: "chart.line.uptrend.xyaxis"
                        )
                    }

                    ProfileView(
                        user: $user,
                        mealStore: mealStore,
                        profileStore: profileStore
                    )
                    .tabItem {
                        Label("Profile", systemImage: "person.fill")
                    }
                }
                .tint(Color.trainBlue)

            } else {

                SetupProfileView(profileStore: profileStore)
            }
        }
    }
}


// MARK: - PROFILE SETUP


struct SetupProfileView: View {

    @ObservedObject var profileStore: ProfileStore

    @State private var currentPage = 0
    @State private var validationError: String?

    @State private var sport = "Weight Training"
    @State private var goal = "Build Muscle"
    @State private var trainingDays = 4

    // Fallback targets; replaced by NutritionCalculator in saveProfile().
    @State private var calorieGoal = 2500
    @State private var proteinGoal = 180

    @State private var age = 0
    @State private var heightCm = 0.0
    @State private var weightKg = 0.0
    @State private var activityLevel = "Moderately Active"
    @State private var metabolicEquationSex = "Prefer not to say"
    @State private var measurementUnits = "Metric"

    private let sports = [
        "Weight Training", "Soccer", "Basketball",
        "Football", "Running", "Volleyball", "Other"
    ]

    private let goals = [
        "Build Muscle", "Lose Fat",
        "Maintain Weight", "Improve Performance"
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {

                VStack(alignment: .leading, spacing: 6) {
                    Text(currentPage == 0 ? "Personal Details" : "Training Profile")
                        .font(.largeTitle.bold())

                    Text(currentPage == 0
                         ? "Tell us about yourself."
                         : "Tell us about your training goals.")

                    Text("Step \(currentPage + 1) of 2")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.trainBlue)

                    ProgressView(value: Double(currentPage + 1), total: 2)
                        .tint(Color.trainBlue)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Group {
                    if currentPage == 0 {
                        personalDetailsPage
                    } else {
                        trainingProfilePage
                    }
                }
                .frame(maxHeight: .infinity)

                if let validationError {
                    Text(validationError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack(spacing: 12) {
                    if currentPage == 1 {
                        Button("Back") {
                            validationError = nil
                            currentPage = 0
                        }
                        .buttonStyle(.bordered)
                    }

                    Button {
                        if currentPage == 0 {
                            if validatePersonalDetails() {
                                validationError = nil
                                currentPage = 1
                            }
                        } else {
                            saveProfile()
                        }
                    } label: {
                        Text(currentPage == 0 ? "Continue" : "Create My Plan")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.trainBlue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                }
            }
            .padding()
            .background(Color.trainBackground)
            .navigationTitle("Setup")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Page 1: Personal Details

    private var personalDetailsPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {

                Text("Your Measurements")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Age")
                        .font(.subheadline.weight(.semibold))

                    TextField("Age in years", value: $age, format: .number)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Picker("Units", selection: $measurementUnits) {
                    Text("Metric (cm, kg)").tag("Metric")
                    Text("Imperial (ft, lb)").tag("Imperial")
                }
                .pickerStyle(.menu)
                .padding()
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                if measurementUnits == "Metric" {
                    measurementField(
                        title: "Height (cm)",
                        placeholder: "Height in centimeters",
                        value: $heightCm
                    )

                    measurementField(
                        title: "Weight (kg)",
                        placeholder: "Weight in kilograms",
                        value: $weightKg
                    )
                } else {
                    imperialHeightFields

                    measurementField(
                        title: "Weight (lb)",
                        placeholder: "Weight in pounds",
                        value: Binding(
                            get: { weightKg * 2.20462 },
                            set: { weightKg = $0 / 2.20462 }
                        )
                    )
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Activity Level")
                        .font(.subheadline.weight(.semibold))

                    Text("Consider your overall daily movement, including work and exercise.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Picker("Select activity level", selection: $activityLevel) {
                        Text("Sedentary").tag("Sedentary")
                        Text("Lightly Active").tag("Lightly Active")
                        Text("Moderately Active").tag("Moderately Active")
                        Text("Very Active").tag("Very Active")
                        Text("Extra Active").tag("Extra Active")
                    }
                    .pickerStyle(.menu)
                    .padding()
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Sex for Calorie Equation")
                        .font(.subheadline.weight(.semibold))

                    Picker("Calculation preference", selection: $metabolicEquationSex) {
                        Text("Male").tag("Male")
                        Text("Female").tag("Female")
                        Text("Prefer not to say").tag("Prefer not to say")
                    }
                    .pickerStyle(.menu)
                    .padding()
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Text("Your measurements help estimate your nutrition needs. You can update them later.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Page 2: Training Profile

    private var trainingProfilePage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {

                VStack(alignment: .leading, spacing: 10) {
                    Text("Primary Sport")
                        .font(.headline)

                    Picker("Primary Sport", selection: $sport) {
                        ForEach(sports, id: \.self) { item in
                            Text(item).tag(item)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.trainLightBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Main Goal")
                        .font(.headline)

                    Picker("Main Goal", selection: $goal) {
                        ForEach(goals, id: \.self) { item in
                            Text(item).tag(item)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.trainLightBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Training Schedule")
                        .font(.headline)

                    Stepper(
                        "\(trainingDays) days per week",
                        value: $trainingDays,
                        in: 1...7
                    )
                    .padding()
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Text("TrainFUEL will use your details and goals to personalize your nutrition recommendations.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Reusable Measurement Field

    private func measurementField(
        title: String,
        placeholder: String,
        value: Binding<Double>
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))

            TextField(placeholder, value: value, format: .number)
                .keyboardType(.decimalPad)
                .padding()
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - Imperial Height

    private var imperialHeightFields: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Height")
                .font(.subheadline.weight(.semibold))

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Feet")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    TextField(
                        "Feet",
                        value: Binding<Int>(
                            get: { Int(heightCm / 2.54) / 12 },
                            set: { feet in
                                let inches = Int(heightCm / 2.54) % 12
                                heightCm = Double(feet * 12 + inches) * 2.54
                            }
                        ),
                        format: .number
                    )
                    .keyboardType(.numberPad)
                    .padding()
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Inches")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    TextField(
                        "Inches",
                        value: Binding<Int>(
                            get: { Int(heightCm / 2.54) % 12 },
                            set: { inches in
                                let feet = Int(heightCm / 2.54) / 12
                                heightCm = Double(feet * 12 + inches) * 2.54
                            }
                        ),
                        format: .number
                    )
                    .keyboardType(.numberPad)
                    .padding()
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    // MARK: - Validation

    private func validatePersonalDetails() -> Bool {
        guard (18...100).contains(age) else {
            validationError = "Enter an age between 18 and 100."
            return false
        }

        guard heightCm.isFinite, (100...250).contains(heightCm) else {
            validationError = "Enter a valid height between 100 and 250 cm, or the equivalent in feet and inches."
            return false
        }

        guard weightKg.isFinite, (30...350).contains(weightKg) else {
            validationError = "Enter a valid weight between 30 and 350 kg, or the equivalent in pounds."
            return false
        }

        return true
    }

    // MARK: - Save Profile

    private func saveProfile() {
        guard validatePersonalDetails() else {
            currentPage = 0
            return
        }

        var newProfile = FitnessProfile(
            sport: sport,
            goal: goal,
            trainingDays: trainingDays,
            calorieGoal: calorieGoal,
            proteinGoal: proteinGoal,
            carbsGoal: 300,
            fatGoal: 80,
            age: age,
            heightCm: heightCm,
            weightKg: weightKg,
            activityLevel: activityLevel,
            metabolicEquationSex: metabolicEquationSex,
            measurementUnits: measurementUnits
        )

        if let targets = NutritionCalculator.calculate(
            profile: newProfile
        ) {
            newProfile.calorieGoal = targets.calories
            newProfile.proteinGoal = targets.protein
            newProfile.carbsGoal = targets.carbs
            newProfile.fatGoal = targets.fat
        }

        profileStore.profile = newProfile
    }
}



// MARK: - DASHBOARD

struct DashboardView: View {

    @ObservedObject var mealStore: MealStore
    @ObservedObject var profileStore: ProfileStore

    var calorieGoal: Int {
        profileStore.profile.calorieGoal
    }

    var proteinGoal: Int {
        profileStore.profile.proteinGoal
    }
    var todayCalories: Int {
        mealStore.totalCalories(on: Date())
    }

    var todayProtein: Int {
        mealStore.totalProtein(on: Date())
    }

    var todayCarbs: Int {
        mealStore.totalCarbs(on: Date())
    }

    var todayFat: Int {
        mealStore.totalFat(on: Date())
    }

    var todayMeals: [FoodEntry] {
        mealStore.meals(on: Date())
    }

    var caloriePercentage: Int {

        guard calorieGoal > 0 else {
            return 0
        }

        return Int(
            Double(todayCalories)
            / Double(calorieGoal)
            * 100
        )
    }

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(alignment: .leading, spacing: 22) {

                    VStack(alignment: .leading, spacing: 5) {

                        Text("Welcome back,")
                            .foregroundStyle(Color.secondary)

                        Text(
                            Auth.auth().currentUser?.displayName
                            ?? "Athlete"
                        )
                        .font(.largeTitle.bold())

                        Text(
                            "\(profileStore.profile.sport) • \(profileStore.profile.goal)"
                        )
                        .foregroundStyle(Color.trainBlue)
                        .fontWeight(.semibold)
                    }

                    VStack(alignment: .leading, spacing: 16) {

                        Text("Daily Nutrition")
                            .font(.title2.bold())

                        HStack {

                            VStack(alignment: .leading, spacing: 4) {

                                Text("\(todayCalories)")
                                    .font(
                                        .system(
                                            size: 34,
                                            weight: .bold
                                        )
                                    )
                                    .foregroundStyle(Color.trainBlue)

                                Text("of \(calorieGoal) calories")
                                    .foregroundStyle(Color.secondary)

                                Text(
                                    "\(max(calorieGoal - todayCalories, 0)) remaining"
                                )
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                            }

                            Spacer()

                            ZStack {

                                Circle()
                                    .stroke(
                                        Color.gray.opacity(0.2),
                                        lineWidth: 10
                                    )

                                Circle()
                                    .trim(
                                        from: 0,
                                        to: min(
                                            Double(todayCalories)
                                            / Double(calorieGoal),
                                            1
                                        )
                                    )
                                    .stroke(
                                        Color.trainBlue,
                                        style: StrokeStyle(
                                            lineWidth: 10,
                                            lineCap: .round
                                        )
                                    )
                                    .rotationEffect(.degrees(-90))

                                Text("\(caloriePercentage)%")
                                    .font(.headline.bold())
                            }
                            .frame(width: 90, height: 90)
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(
                        color: Color.black.opacity(0.05),
                        radius: 8
                    )

                    Text("Macros")
                        .font(.title2.bold())

                    HStack(spacing: 10) {

                        MacroCard(
                            title: "Protein",
                            amount: "\(todayProtein)g",
                            goal: "\(proteinGoal)g"
                        )

                        MacroCard(
                            title: "Carbs",
                            amount: "\(todayCarbs)g",
                            goal: "Tracked"
                        )

                        MacroCard(
                            title: "Fat",
                            amount: "\(todayFat)g",
                            goal: "Tracked"
                        )
                    }

                    VStack(alignment: .leading, spacing: 12) {

                        Label(
                            "Today's Recommendation",
                            systemImage: "lightbulb.fill"
                        )
                        .font(.headline)
                        .foregroundStyle(Color.trainBlue)

                        Text(profileStore.recommendationTitle)
                            .font(.title3.bold())

                        Text(profileStore.recommendation)
                            .foregroundStyle(Color.secondary)
                        
                        Text(profileStore.hydrationRecommendation)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.trainBlue)

                        Divider()

                        Label(
                            "\(profileStore.profile.trainingDays) training days per week",
                            systemImage: "calendar"
                        )
                        .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(Color.trainLightBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                    VStack(alignment: .leading, spacing: 12) {

                        Label(
                            "Today's Meals",
                            systemImage: "fork.knife"
                        )
                        .font(.headline)
                        .foregroundStyle(Color.trainBlue)

                        if todayMeals.isEmpty {

                            Text("No meals logged yet")
                                .font(.title3.bold())

                            Text(
                                "Go to Nutrition and add your first meal."
                            )
                            .foregroundStyle(Color.secondary)

                        } else {

                            Text(
                                "\(todayMeals.count) meal\(todayMeals.count == 1 ? "" : "s") logged"
                            )
                            .font(.title3.bold())

                            Text(
                                "\(todayCalories) calories and \(todayProtein)g protein logged today."
                            )
                            .foregroundStyle(Color.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .padding()
            }
            .background(Color.trainBackground)
            .navigationTitle("TrainFUEL")
        }
    }
}


// MARK: - MACRO CARD

struct MacroCard: View {

    let title: String
    let amount: String
    let goal: String

    var body: some View {

        VStack(spacing: 6) {

            Text(title)
                .font(.caption)
                .foregroundStyle(Color.secondary)

            Text(amount)
                .font(.title3.bold())
                .foregroundStyle(Color.trainBlue)

            Text(goal)
                .font(.caption2)
                .foregroundStyle(Color.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(
            color: Color.black.opacity(0.05),
            radius: 6
        )
    }
}

struct NutritionProgressRow: View {

    let title: String
    let consumed: Int
    let target: Int
    let unit: String

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(consumed) / Double(target), 1.0)
    }

    private var remaining: Int {
        max(target - consumed, 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            HStack {
                Text(title)
                    .font(.headline)

                Spacer()

                Text("\(consumed) / \(target) \(unit)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: progress)
                .tint(Color.trainBlue)

            HStack {
                if consumed >= target {
                    Text("Target reached")
                        .foregroundStyle(.green)
                } else {
                    Text("\(remaining) \(unit) remaining")
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(Int(progress * 100))%")
                    .foregroundStyle(.secondary)
            }
            .font(.caption)
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.05), radius: 5)
    }
}


// MARK: - NUTRITION

struct NutritionView: View {

    @ObservedObject var mealStore: MealStore
    @ObservedObject var profileStore: ProfileStore

    @State private var showAddMeal = false
    private var todayMeals: [FoodEntry] {
        mealStore.meals(on: Date())
    }

    var body: some View {

        NavigationStack {

            VStack(spacing: 12) {

                
                VStack(spacing: 12) {

                    NutritionProgressRow(
                        title: "Calories",
                        consumed: mealStore.totalCalories(on: Date()),
                        target: profileStore.profile.calorieGoal,
                        unit: "kcal"
                    )

                    NutritionProgressRow(
                        title: "Protein",
                        consumed: mealStore.totalProtein(on: Date()),
                        target: profileStore.profile.proteinGoal,
                        unit: "g"
                    )

                    NutritionProgressRow(
                        title: "Carbohydrates",
                        consumed: mealStore.totalCarbs(on: Date()),
                        target: profileStore.profile.carbsGoal,
                        unit: "g"
                    )

                    NutritionProgressRow(
                        title: "Fat",
                        consumed: mealStore.totalFat(on: Date()),
                        target: profileStore.profile.fatGoal,
                        unit: "g"
                    )

                    Text(
                        profileStore.profile.hasValidPersonalDetails
                        ? "Targets are estimates based on your profile, not medical advice."
                        : "Default targets shown. Add your age, height and weight in Edit Training Plan for personalized estimates."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)


               if todayMeals.isEmpty {

                    // Scrolls like the meal list so the screen never overflows.
                    ScrollView {

                        VStack(spacing: 12) {

                            Image(systemName: "fork.knife.circle")
                                .font(.system(size: 70))
                                .foregroundStyle(Color.trainBlue)

                            Text("No Meals Yet")
                                .font(.title2.bold())

                            Text(
                                "Add your first meal to start tracking today's nutrition."
                            )
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.secondary)
                            .padding(.horizontal, 35)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 24)
                    }

                } else {

                    List {

                        Section("Today's Meals") {

                            ForEach(todayMeals) { food in

                                VStack(alignment: .leading, spacing: 8) {

                                    HStack {

                                        Text(food.name)
                                            .fontWeight(.semibold)

                                        Spacer()

                                        Text("\(food.calories) cal")
                                            .foregroundStyle(Color.trainBlue)
                                            .fontWeight(.semibold)
                                    }

                                    HStack(spacing: 14) {

                                        Text("\(food.protein)g protein")
                                        Text("\(food.carbs)g carbs")
                                        Text("\(food.fat)g fat")
                                    }
                                    .font(.caption)
                                    .foregroundStyle(Color.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                            .onDelete { offsets in
                                let selectedMeals = offsets.map { todayMeals[$0] }

                                let allIndices = IndexSet(
                                    selectedMeals.compactMap { selectedMeal in
                                        mealStore.foods.firstIndex {
                                            $0.id == selectedMeal.id
                                        }
                                    }
                                )

                                mealStore.deleteMeals(at: allIndices)
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }

                Button {
                    showAddMeal = true
                } label: {

                    Label(
                        "Add Meal",
                        systemImage: "plus.circle.fill"
                    )
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.trainBlue)
                    .foregroundStyle(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                }
                .padding()
            }
            .background(Color.trainBackground)
            .navigationTitle("Nutrition")
            .sheet(isPresented: $showAddMeal) {
                AddMealView(mealStore: mealStore)
            }
        }
    }
}


// MARK: - STAT BOX

struct StatBox: View {

    let title: String
    let value: String

    var body: some View {

        VStack(spacing: 5) {

            Text(value)
                .font(.title2.bold())
                .foregroundStyle(Color.trainBlue)

            Text(title)
                .font(.caption)
                .foregroundStyle(Color.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}


// MARK: - ADD MEAL

struct AddMealView: View {

    @Environment(\.dismiss) private var dismiss

    @ObservedObject var mealStore: MealStore

    @State private var name = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""

    var formIsValid: Bool {

        !name.trimmingCharacters(in: .whitespaces).isEmpty
        && Int(calories) != nil
        && Int(protein) != nil
        && Int(carbs) != nil
        && Int(fat) != nil
    }

    var body: some View {

        NavigationStack {

            Form {

                Section("Meal Information") {

                    TextField("Food or meal name", text: $name)

                    TextField("Calories", text: $calories)
                        .keyboardType(.numberPad)

                    TextField("Protein (g)", text: $protein)
                        .keyboardType(.numberPad)

                    TextField("Carbs (g)", text: $carbs)
                        .keyboardType(.numberPad)

                    TextField("Fat (g)", text: $fat)
                        .keyboardType(.numberPad)
                }

                Section {

                    Button {
                        addFood()
                    } label: {

                        HStack {

                            Spacer()

                            Label(
                                "Add to Today",
                                systemImage: "plus.circle.fill"
                            )
                            .fontWeight(.bold)

                            Spacer()
                        }
                    }
                    .disabled(!formIsValid)
                }
            }
            .navigationTitle("Add Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(placement: .cancellationAction) {

                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func addFood() {

        guard
            let calorieAmount = Int(calories),
            let proteinAmount = Int(protein),
            let carbAmount = Int(carbs),
            let fatAmount = Int(fat)
        else {
            return
        }

        let meal = FoodEntry(
            name: name.trimmingCharacters(in: .whitespaces),
            calories: calorieAmount,
            protein: proteinAmount,
            carbs: carbAmount,
            fat: fatAmount
        )

        mealStore.addMeal(meal)

        dismiss()
    }
}

// MARK: - PROGRESS

struct ProgressScreen: View {

    @ObservedObject var mealStore: MealStore
    @ObservedObject var profileStore: ProfileStore
    @ObservedObject var workoutStore: WorkoutStore

    var calorieProgress: Int {

        guard profileStore.profile.calorieGoal > 0 else {
            return 0
        }

        return Int(
            min(
                Double(mealStore.totalCalories(on: Date()))
                / Double(profileStore.profile.calorieGoal),
                1
            ) * 100
        )
    }

    var proteinProgress: Int {

        guard profileStore.profile.proteinGoal > 0 else {
            return 0
        }

        return Int(
            min(
                Double(mealStore.totalProtein(on: Date()))
                / Double(profileStore.profile.proteinGoal),
                1
            ) * 100
        )
    }

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(spacing: 20) {

                    Image(
                        systemName:
                            "chart.line.uptrend.xyaxis.circle.fill"
                    )
                    .font(.system(size: 80))
                    .foregroundStyle(Color.trainBlue)

                    Text("Today's Progress")
                        .font(.largeTitle.bold())

                    Text(
                        "\(profileStore.profile.sport) • \(profileStore.profile.goal)"
                    )
                    .foregroundStyle(Color.secondary)

                    HStack {

                        ProgressCard(
                            title: "Meals",
                            value: "\(mealStore.meals(on: Date()).count)"
                        )

                        ProgressCard(
                            title: "Calories",
                            value: "\(calorieProgress)%"
                        )
                    }

                    HStack {

                        ProgressCard(
                            title: "Protein",
                            value: "\(proteinProgress)%"
                        )

                        ProgressCard(
                            title: "Training",
                            value: "\(profileStore.profile.trainingDays)x/week"
                        )
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {

                        Text("Training Summary")
                            .font(.title2.bold())

                        SummaryRow(
                            title: "Workouts Completed",
                            value: "\(workoutStore.workouts.count)"
                        )

                        Divider()

                        SummaryRow(
                            title: "Total Training Time",
                            value: "\(workoutStore.workouts.reduce(0) { $0 + $1.duration }) min"
                        )
                    }
                    .padding(20)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                    VStack(alignment: .leading, spacing: 12) {

                        Text("Daily Summary")
                            .font(.title2.bold())

                        SummaryRow(
                            title: "Calories",
                            value:
                                "\(mealStore.totalCalories(on: Date())) / \(profileStore.profile.calorieGoal)"
                        )

                        Divider()

                        SummaryRow(
                            title: "Protein",
                            value:
                                "\(mealStore.totalProtein(on: Date()))g / \(profileStore.profile.proteinGoal)g"
                        )

                        Divider()

                        SummaryRow(
                            title: "Carbs",
                            value: "\(mealStore.totalCarbs(on: Date()))g"
                        )

                        Divider()

                        SummaryRow(
                            title: "Fat",
                            value: "\(mealStore.totalFat(on: Date()))g"
                        )
                    }
                    .padding(20)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .padding()
            }
            .background(Color.trainBackground)
            .navigationTitle("Progress")
        }
    }
}


// MARK: - PROGRESS CARD

struct ProgressCard: View {

    let title: String
    let value: String

    var body: some View {

        VStack(spacing: 8) {

            Text(title)
                .foregroundStyle(Color.secondary)

            Text(value)
                .font(.title3.bold())
                .foregroundStyle(Color.trainBlue)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}


// MARK: - SUMMARY ROW

struct SummaryRow: View {

    let title: String
    let value: String

    var body: some View {

        HStack {

            Text(title)

            Spacer()

            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(Color.trainBlue)
        }
    }
}


// MARK: - PROFILE

struct ProfileView: View {

    @Binding var user: User?

    @ObservedObject var mealStore: MealStore
    @ObservedObject var profileStore: ProfileStore

    @State private var showEditProfile = false

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(spacing: 22) {

                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 90))
                        .foregroundStyle(Color.trainBlue)

                    Text(
                        Auth.auth().currentUser?.displayName
                        ?? "TrainFUEL Athlete"
                    )
                    .font(.title.bold())

                    Text(
                        Auth.auth().currentUser?.email
                        ?? ""
                    )
                    .foregroundStyle(Color.secondary)

                    VStack(spacing: 0) {

                        ProfileRow(
                            title: "Primary Sport",
                            value: profileStore.profile.sport
                        )

                        Divider()

                        ProfileRow(
                            title: "Goal",
                            value: profileStore.profile.goal
                        )

                        Divider()

                        ProfileRow(
                            title: "Training",
                            value:
                                "\(profileStore.profile.trainingDays) days/week"
                        )

                        Divider()

                        ProfileRow(
                            title: "Daily Calories",
                            value:
                                "\(profileStore.profile.calorieGoal)"
                        )

                        Divider()

                        ProfileRow(
                            title: "Protein Goal",
                            value:
                                "\(profileStore.profile.proteinGoal)g"
                        )

                        Divider()

                        ProfileRow(
                            title: "Meals Logged",
                            value: "\(mealStore.foods.count)"
                        )
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                    Button {
                        showEditProfile = true
                    } label: {

                        Label(
                            "Edit Training Plan",
                            systemImage: "slider.horizontal.3"
                        )
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.trainBlue)
                        .foregroundStyle(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button(role: .destructive) {
                        logout()
                    } label: {

                        Text("Log Out")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding()
            }
            .background(Color.trainBackground)
            .navigationTitle("Profile")
            .sheet(isPresented: $showEditProfile) {
                EditProfileView(profileStore: profileStore)
            }
        }
    }

    private func logout() {

        do {
            try Auth.auth().signOut()
            user = nil
        } catch {
            print(
                "Logout error: \(error.localizedDescription)"
            )
        }
    }
}


// MARK: - EDIT PROFILE

struct EditProfileView: View {

    @Environment(\.dismiss) private var dismiss

    @ObservedObject var profileStore: ProfileStore

    @State private var sport: String
    @State private var goal: String
    @State private var trainingDays: Int
    @State private var calorieGoal: Int
    @State private var proteinGoal: Int
    
    @State private var age: Int
    @State private var heightCm: Double
    @State private var weightKg: Double
    @State private var activityLevel: String
    @State private var metabolicEquationSex: String
    @State private var validationError: String?
    
    @State private var measurementUnits: String
    @State private var heightFeet: Int
    @State private var heightInches: Int
    @State private var weightPounds: Double


    let sports = [
        "Weight Training",
        "Soccer",
        "Basketball",
        "Football",
        "Running",
        "Volleyball",
        "Other"
    ]

    let goals = [
        "Build Muscle",
        "Lose Fat",
        "Maintain Weight",
        "Improve Performance"
    ]

    init(profileStore: ProfileStore) {

        self.profileStore = profileStore

        _sport = State(
            initialValue: profileStore.profile.sport
        )

        _goal = State(
            initialValue: profileStore.profile.goal
        )

        _trainingDays = State(
            initialValue: profileStore.profile.trainingDays
        )

        _calorieGoal = State(
            initialValue: profileStore.profile.calorieGoal
        )

        _proteinGoal = State(
            initialValue: profileStore.profile.proteinGoal
        )
        
        // Profiles without an age store 0; start the stepper at its minimum.
        _age = State(initialValue: max(18, profileStore.profile.age))
        _heightCm = State(initialValue: profileStore.profile.heightCm)
        _weightKg = State(initialValue: profileStore.profile.weightKg)
        _activityLevel = State(
            initialValue: profileStore.profile.activityLevel
        )
        _metabolicEquationSex = State(
            initialValue: profileStore.profile.metabolicEquationSex
        )
        _measurementUnits = State(
            initialValue: profileStore.profile.measurementUnits
        )

        let totalInches = profileStore.profile.heightCm / 2.54
        _heightFeet = State(initialValue: Int(totalInches) / 12)
        _heightInches = State(initialValue: Int(totalInches) % 12)

        _weightPounds = State(
            initialValue: profileStore.profile.weightKg * 2.20462
        )

    }

    var body: some View {

        NavigationStack {

            Form {
                if let validationError = validationError {
                    Section {
                        Text(validationError)
                            .foregroundStyle(.red)
                    }
                }
                
                Section("Personal Details") {
                    Picker(
                        "Units",
                        selection: Binding(
                            get: { measurementUnits },
                            set: { changeUnits(to: $0) }
                        )
                    ) {
                        Text("Metric (cm, kg)").tag("Metric")
                        Text("Imperial (ft, lb)").tag("Imperial")
                    }
                    Stepper("Age: \(age)", value: $age, in: 18...100)

                    if measurementUnits == "Metric" {
                        HStack {
                            Text("Height (cm)")
                            Spacer()
                            TextField(
                                "Height",
                                value: $heightCm,
                                format: .number.precision(.fractionLength(1))
                            )
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        }

                        HStack {
                            Text("Weight (kg)")
                            Spacer()
                            TextField(
                                "Weight",
                                value: $weightKg,
                                format: .number.precision(.fractionLength(1))
                            )
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        }
                    } else {
                        HStack {
                            Text("Height")
                            Spacer()

                            Picker("Feet", selection: $heightFeet) {
                                ForEach(3...8, id: \.self) { feet in
                                    Text("\(feet) ft").tag(feet)
                                }
                            }
                            .labelsHidden()

                            Picker("Inches", selection: $heightInches) {
                                ForEach(0...11, id: \.self) { inches in
                                    Text("\(inches) in").tag(inches)
                                }
                            }
                            .labelsHidden()
                        }

                        HStack {
                            Text("Weight (lb)")
                            Spacer()
                            TextField(
                                "Weight",
                                value: $weightPounds,
                                format: .number.precision(.fractionLength(1))
                            )
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        }
                    }

                    Picker("Activity Level", selection: $activityLevel) {
                        Text("Sedentary").tag("Sedentary")
                        Text("Lightly Active").tag("Lightly Active")
                        Text("Moderately Active").tag("Moderately Active")
                        Text("Very Active").tag("Very Active")
                        Text("Extra Active").tag("Extra Active")
                    }

                    Picker(
                        "Equation Setting",
                        selection: $metabolicEquationSex
                    ) {
                        Text("Male").tag("Male")
                        Text("Female").tag("Female")
                        Text("Prefer not to say").tag("Prefer not to say")
                    }

                    Text(
                        "The equation setting is used to estimate energy needs. " +
                        "These calculations are estimates, not medical advice."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }


                Section("Training") {

                    Picker(
                        "Primary Sport",
                        selection: $sport
                    ) {
                        ForEach(sports, id: \.self) {
                            Text($0)
                        }
                    }

                    Picker(
                        "Goal",
                        selection: $goal
                    ) {
                        ForEach(goals, id: \.self) {
                            Text($0)
                        }
                    }

                    Stepper(
                        "Training: \(trainingDays) days/week",
                        value: $trainingDays,
                        in: 1...7
                    )
                }

                Section("Nutrition Goals") {

                    Stepper(
                        "\(calorieGoal) calories",
                        value: $calorieGoal,
                        in: 1200...8000,
                        step: 100
                    )

                    Stepper(
                        "\(proteinGoal)g protein",
                        value: $proteinGoal,
                        in: 50...500,
                        step: 5
                    )
                }

                Section {

                    Button("Save Changes") {
                        save()
                    }
                    .fontWeight(.bold)
                }
            }
            .navigationTitle("Edit Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(placement: .cancellationAction) {

                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func save() {

        // Imperial inputs are only converted when switching units,
        // so convert them here before validating and saving.
        if measurementUnits == "Imperial" {
            let totalInches = heightFeet * 12 + heightInches

            // Keep the original cm value if the height wasn't changed,
            // avoiding rounding loss from whole inches.
            if totalInches != Int(heightCm / 2.54) {
                heightCm = Double(totalInches) * 2.54
            }

            weightKg = weightPounds / 2.20462
        }

        guard (18...100).contains(age) else {
            validationError = "Age must be between 18 and 100."
            return
        }

        guard heightCm.isFinite,
              (100...250).contains(heightCm) else {
            validationError = "Height must be between 100 and 250 cm."
            return
        }

        guard weightKg.isFinite, (30...350).contains(weightKg) else {
            validationError = "Weight must be between 30 and 350 kg."
            return
        }

        validationError = nil

        var updatedProfile = FitnessProfile(
            sport: sport,
            goal: goal,
            trainingDays: trainingDays,
            calorieGoal: calorieGoal,
            proteinGoal: proteinGoal,
            carbsGoal: profileStore.profile.carbsGoal,
            fatGoal: profileStore.profile.fatGoal,
            age: age,
            heightCm: heightCm,
            weightKg: weightKg,
            activityLevel: activityLevel,
            metabolicEquationSex: metabolicEquationSex,
            measurementUnits: measurementUnits
        )

        // Recalculate targets only when a calculation input changed,
        // so manual calorie/protein adjustments are otherwise kept.
        let current = profileStore.profile
        let inputsChanged =
            age != current.age ||
            abs(heightCm - current.heightCm) > 0.05 ||
            abs(weightKg - current.weightKg) > 0.05 ||
            activityLevel != current.activityLevel ||
            metabolicEquationSex != current.metabolicEquationSex ||
            goal != current.goal

        if inputsChanged,
           let targets = NutritionCalculator.calculate(
               profile: updatedProfile
           ) {
            updatedProfile.calorieGoal = targets.calories
            updatedProfile.proteinGoal = targets.protein
            updatedProfile.carbsGoal = targets.carbs
            updatedProfile.fatGoal = targets.fat
        } else if calorieGoal != current.calorieGoal ||
                    proteinGoal != current.proteinGoal {
            // Manual calorie/protein change: keep carbs and fat consistent.
            let macros = NutritionCalculator.carbsAndFat(
                calories: calorieGoal,
                protein: proteinGoal
            )
            updatedProfile.carbsGoal = macros.carbs
            updatedProfile.fatGoal = macros.fat
        }

        profileStore.profile = updatedProfile

        dismiss()
    }
    private func changeUnits(to newUnits: String) {
        guard newUnits != measurementUnits else { return }

        if newUnits == "Imperial" {
            let totalInches = heightCm / 2.54
            heightFeet = Int(totalInches) / 12
            heightInches = Int(totalInches) % 12
            weightPounds = weightKg * 2.20462
        } else {
            heightCm = Double(heightFeet * 12 + heightInches) * 2.54
            weightKg = weightPounds / 2.20462
        }

        measurementUnits = newUnits
    }
}


// MARK: - PROFILE ROW

struct ProfileRow: View {

    let title: String
    let value: String

    var body: some View {

        HStack {

            Text(title)

            Spacer()

            Text(value)
                .foregroundStyle(Color.secondary)
        }
        .padding()
    }
}

// MARK: - FITNESS

// MARK: - FITNESS

struct FitnessView: View {
    
    @ObservedObject var workoutStore: WorkoutStore

    @State private var showAddWorkout = false

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(alignment: .leading, spacing: 20) {

                    // MARK: Header

                    VStack(alignment: .leading, spacing: 8) {

                        Image(systemName: "figure.run.circle.fill")
                            .font(.system(size: 70))
                            .foregroundStyle(Color.trainBlue)

                        Text("Fitness")
                            .font(.largeTitle.bold())

                        Text("Track your workouts and training.")
                            .foregroundStyle(Color.secondary)
                    }

                    // MARK: Today's Workout

                    VStack(alignment: .leading, spacing: 12) {

                        Label(
                            "Today's Workout",
                            systemImage: "figure.run"
                        )
                        .font(.headline)
                        .foregroundStyle(Color.trainBlue)

                        let todaysWorkouts = workoutStore.workouts.filter {
                            Calendar.current.isDateInToday($0.date)
                        }

                        if todaysWorkouts.isEmpty {

                            Text("No workout logged yet")
                                .font(.title3.bold())

                            Text(
                                "Log your workout to keep track of your training."
                            )
                            .foregroundStyle(Color.secondary)

                        } else {

                            ForEach(todaysWorkouts) { workout in

                                WorkoutRow(workout: workout)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(Color.white)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 18)
                    )

                    // MARK: All Workouts

                    VStack(alignment: .leading, spacing: 12) {

                        Label(
                            "Your Workouts",
                            systemImage: "list.bullet"
                        )
                        .font(.headline)
                        .foregroundStyle(Color.trainBlue)

                        if workoutStore.workouts.isEmpty {

                            Text("No workouts logged yet.")
                                .foregroundStyle(Color.secondary)

                        } else {

                            ForEach(workoutStore.workouts.sorted {
                                $0.date > $1.date
                            }) { workout in

                                WorkoutRow(workout: workout)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(Color.white)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 18)
                    )

                    // MARK: Log Workout Button

                    Button {
                        showAddWorkout = true
                    } label: {

                        Label(
                            "Log Workout",
                            systemImage: "plus.circle.fill"
                        )
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.trainBlue)
                        .foregroundStyle(Color.white)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 15)
                        )
                    }
                }
                .padding()
            }
            .background(Color.trainBackground)
            .navigationTitle("Fitness")
            .sheet(isPresented: $showAddWorkout) {
                AddWorkoutView(
                    workoutStore: workoutStore
                )
            }
        }
    }
}

struct WorkoutRow: View {

    let workout: WorkoutEntry

    var body: some View {

        HStack(spacing: 15) {

            Image(systemName: iconForWorkout)
                .font(.title2)
                .foregroundStyle(Color.trainBlue)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {

                Text(workout.name)
                    .font(.headline)

                Text(workout.type)
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)

                Text(
                    "\(workout.duration) minutes"
                )
                .font(.caption)
                .foregroundStyle(Color.secondary)
            }

            Spacer()

            Text(
                workout.date.formatted(
                    date: .abbreviated,
                    time: .shortened
                )
            )
            .font(.caption)
            .foregroundStyle(Color.secondary)
        }
        .padding(.vertical, 6)
    }

    private var iconForWorkout: String {

        switch workout.type {

        case "Strength":
            return "dumbbell.fill"

        case "Cardio":
            return "heart.fill"

        case "Running":
            return "figure.run"

        case "Sports":
            return "sportscourt.fill"

        case "Mobility":
            return "figure.flexibility"

        default:
            return "figure.mixed.cardio"
        }
    }
}
// MARK: - ADD WORKOUT

struct AddWorkoutView: View {

    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var workoutStore: WorkoutStore

    @State private var workoutName = ""
    @State private var workoutType = "Strength"
    @State private var duration = ""

    let workoutTypes = [
        "Strength",
        "Cardio",
        "Running",
        "Sports",
        "Mobility",
        "Other"
    ]

    var body: some View {

        NavigationStack {

            Form {

                Section("Workout Information") {

                    TextField(
                        "Workout Name",
                        text: $workoutName
                    )

                    Picker(
                        "Workout Type",
                        selection: $workoutType
                    ) {
                        ForEach(workoutTypes, id: \.self) {
                            Text($0)
                        }
                    }

                    TextField(
                        "Duration (minutes)",
                        text: $duration
                    )
                    .keyboardType(.numberPad)
                }

                Section {

                    Button("Save Workout") {

                        guard let durationValue = Int(duration) else {
                            return
                        }

                        workoutStore.addWorkout(
                            name: workoutName,
                            type: workoutType,
                            duration: durationValue
                        )

                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(
                        workoutName
                            .trimmingCharacters(
                                in: .whitespaces
                            )
                            .isEmpty
                        || Int(duration) == nil
                    )
                }
            }
            .navigationTitle("Log Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(
                    placement: .cancellationAction
                ) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - PREVIEW

#Preview {
    ContentView()
}
