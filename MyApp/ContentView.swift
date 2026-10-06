import SwiftUI
import FirebaseAuth
import Combine

// MARK: - COLORS

extension Color {
    static let trainBlue = Color(red: 0.08, green: 0.35, blue: 0.95)
    static let trainLightBlue = Color(red: 0.92, green: 0.96, blue: 1.0)
    static let trainBackground = Color(red: 0.97, green: 0.98, blue: 1.0)
}


// MARK: - MEAL MODEL

struct FoodEntry: Identifiable, Codable {
    var id = UUID()
    let name: String
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
}


// MARK: - MEAL STORE

final class MealStore: ObservableObject {

    @Published var foods: [FoodEntry] = [] {
        didSet {
            saveMeals()
        }
    }

    private var storageKey: String {
        let uid = Auth.auth().currentUser?.uid ?? "guest"
        return "trainfuel_meals_\(uid)"
    }

    init() {
        loadMeals()
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

    func addMeal(_ meal: FoodEntry) {
        foods.append(meal)
    }

    func deleteMeals(at offsets: IndexSet) {
        foods.remove(atOffsets: offsets)
    }

    private func saveMeals() {
        guard let data = try? JSONEncoder().encode(foods) else {
            return
        }

        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func loadMeals() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let savedFoods = try? JSONDecoder().decode(
                [FoodEntry].self,
                from: data
            )
        else {
            foods = []
            return
        }

        foods = savedFoods
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

    private let storageKey: String

    init() {
        let uid = Auth.auth().currentUser?.uid ?? "guest"
        storageKey = "workouts_\(uid)"

        loadWorkouts()
    }

    func addWorkout(
        name: String,
        type: String,
        duration: Int
    ) {

        let workout = WorkoutEntry(
            name: name,
            type: type,
            duration: duration,
            date: Date()
        )

        workouts.append(workout)

        saveWorkouts()
    }

    func deleteWorkouts(at offsets: IndexSet) {

        workouts.remove(atOffsets: offsets)

        saveWorkouts()
    }

    private func saveWorkouts() {

        if let encoded = try? JSONEncoder().encode(workouts) {
            UserDefaults.standard.set(
                encoded,
                forKey: storageKey
            )
        }
    }

    private func loadWorkouts() {

        guard let data = UserDefaults.standard.data(
            forKey: storageKey
        ) else {
            return
        }

        if let decoded = try? JSONDecoder().decode(
            [WorkoutEntry].self,
            from: data
        ) {
            workouts = decoded
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

    var isComplete: Bool {
        !sport.isEmpty && !goal.isEmpty
    }
}


// MARK: - PROFILE STORE

final class ProfileStore: ObservableObject {

    @Published var profile: FitnessProfile {
        didSet {
            saveProfile()
        }
    }

    private var storageKey: String {
        let uid = Auth.auth().currentUser?.uid ?? "guest"
        return "trainfuel_profile_\(uid)"
    }

    init() {
        let uid = Auth.auth().currentUser?.uid ?? "guest"
        let key = "trainfuel_profile_\(uid)"

        if let data = UserDefaults.standard.data(forKey: key),
           let savedProfile = try? JSONDecoder().decode(
                FitnessProfile.self,
                from: data
           ) {
            profile = savedProfile
        } else {
            profile = FitnessProfile()
        }
    }

    private func saveProfile() {
        guard let data = try? JSONEncoder().encode(profile) else {
            return
        }

        UserDefaults.standard.set(data, forKey: storageKey)
    }

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
            return "Stay consistent with your calorie and protein goals and adjust your meals around your training."
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

    var body: some View {
        Group {
            if user != nil {
                MainTabView(user: $user)
            } else {
                WelcomeView(user: $user)
            }
        }
        .preferredColorScheme(.light)
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

            Spacer()
        }
        .padding(25)
        .navigationTitle("Log In")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func login() {

        errorMessage = ""
        isLoading = true

        Auth.auth().signIn(
            withEmail: email,
            password: password
        ) { result, error in

            isLoading = false

            if let error = error {
                errorMessage = error.localizedDescription
                return
            }

            user = result?.user
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

            if let error = error {
                isLoading = false
                errorMessage = error.localizedDescription
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

                isLoading = false

                if let error = error {
                    errorMessage = error.localizedDescription
                    return
                }

                user = Auth.auth().currentUser
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

                    NutritionView(mealStore: mealStore)
                        .tabItem {
                            Label("Nutrition", systemImage: "fork.knife")
                        }
                    FitnessView(workoutStore: workoutStore)
                        .tabItem {
                            Label("Fitness", systemImage: "figure.run")
                        }

                    ProgressScreen(
                        mealStore: mealStore,
                        profileStore: profileStore
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

    @State private var sport = "Weight Training"
    @State private var goal = "Build Muscle"
    @State private var trainingDays = 4
    @State private var calorieGoal = 2500
    @State private var proteinGoal = 180

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

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(alignment: .leading, spacing: 24) {

                    VStack(alignment: .leading, spacing: 8) {

                        Image(systemName: "figure.run.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.trainBlue)

                        Text("Build Your Plan")
                            .font(.largeTitle.bold())

                        Text(
                            "Tell TrainFUEL about your training so we can personalize your nutrition plan."
                        )
                        .foregroundStyle(Color.secondary)
                    }

                    VStack(alignment: .leading, spacing: 10) {

                        Text("Primary Sport")
                            .font(.headline)

                        Picker("Primary Sport", selection: $sport) {
                            ForEach(sports, id: \.self) {
                                Text($0)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.trainLightBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    VStack(alignment: .leading, spacing: 10) {

                        Text("Main Goal")
                            .font(.headline)

                        Picker("Goal", selection: $goal) {
                            ForEach(goals, id: \.self) {
                                Text($0)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
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
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    VStack(alignment: .leading, spacing: 10) {

                        Text("Daily Calorie Goal")
                            .font(.headline)

                        Stepper(
                            "\(calorieGoal) calories",
                            value: $calorieGoal,
                            in: 1200...5000,
                            step: 100
                        )
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    VStack(alignment: .leading, spacing: 10) {

                        Text("Daily Protein Goal")
                            .font(.headline)

                        Stepper(
                            "\(proteinGoal)g protein",
                            value: $proteinGoal,
                            in: 50...300,
                            step: 5
                        )
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button {
                        saveProfile()
                    } label: {

                        Text("Create My Plan")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.trainBlue)
                            .foregroundStyle(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                }
                .padding()
            }
            .background(Color.trainBackground)
            .navigationTitle("Setup")
        }
    }

    private func saveProfile() {

        profileStore.profile = FitnessProfile(
            sport: sport,
            goal: goal,
            trainingDays: trainingDays,
            calorieGoal: calorieGoal,
            proteinGoal: proteinGoal
        )
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

    var caloriePercentage: Int {

        guard calorieGoal > 0 else {
            return 0
        }

        return Int(
            Double(mealStore.totalCalories)
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

                                Text("\(mealStore.totalCalories)")
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
                                    "\(max(calorieGoal - mealStore.totalCalories, 0)) remaining"
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
                                            Double(mealStore.totalCalories)
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
                            amount: "\(mealStore.totalProtein)g",
                            goal: "\(proteinGoal)g"
                        )

                        MacroCard(
                            title: "Carbs",
                            amount: "\(mealStore.totalCarbs)g",
                            goal: "Tracked"
                        )

                        MacroCard(
                            title: "Fat",
                            amount: "\(mealStore.totalFat)g",
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

                        if mealStore.foods.isEmpty {

                            Text("No meals logged yet")
                                .font(.title3.bold())

                            Text(
                                "Go to Nutrition and add your first meal."
                            )
                            .foregroundStyle(Color.secondary)

                        } else {

                            Text(
                                "\(mealStore.foods.count) meal\(mealStore.foods.count == 1 ? "" : "s") logged"
                            )
                            .font(.title3.bold())

                            Text(
                                "\(mealStore.totalCalories) calories and \(mealStore.totalProtein)g protein logged today."
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


// MARK: - NUTRITION

struct NutritionView: View {

    @ObservedObject var mealStore: MealStore

    @State private var showAddMeal = false

    var body: some View {

        NavigationStack {

            VStack(spacing: 12) {

                HStack(spacing: 10) {

                    StatBox(
                        title: "Calories",
                        value: "\(mealStore.totalCalories)"
                    )

                    StatBox(
                        title: "Protein",
                        value: "\(mealStore.totalProtein)g"
                    )
                }
                .padding(.horizontal)

                HStack(spacing: 10) {

                    StatBox(
                        title: "Carbs",
                        value: "\(mealStore.totalCarbs)g"
                    )

                    StatBox(
                        title: "Fat",
                        value: "\(mealStore.totalFat)g"
                    )
                }
                .padding(.horizontal)

                if mealStore.foods.isEmpty {

                    Spacer()

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

                    Spacer()

                } else {

                    List {

                        Section("Today's Meals") {

                            ForEach(mealStore.foods) { food in

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
                                mealStore.deleteMeals(at: offsets)
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

    var calorieProgress: Int {

        guard profileStore.profile.calorieGoal > 0 else {
            return 0
        }

        return Int(
            min(
                Double(mealStore.totalCalories)
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
                Double(mealStore.totalProtein)
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
                            value: "\(mealStore.foods.count)"
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

                        Text("Daily Summary")
                            .font(.title2.bold())

                        SummaryRow(
                            title: "Calories",
                            value:
                                "\(mealStore.totalCalories) / \(profileStore.profile.calorieGoal)"
                        )

                        Divider()

                        SummaryRow(
                            title: "Protein",
                            value:
                                "\(mealStore.totalProtein)g / \(profileStore.profile.proteinGoal)g"
                        )

                        Divider()

                        SummaryRow(
                            title: "Carbs",
                            value: "\(mealStore.totalCarbs)g"
                        )

                        Divider()

                        SummaryRow(
                            title: "Fat",
                            value: "\(mealStore.totalFat)g"
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
    }

    var body: some View {

        NavigationStack {

            Form {

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
                        in: 1200...5000,
                        step: 100
                    )

                    Stepper(
                        "\(proteinGoal)g protein",
                        value: $proteinGoal,
                        in: 50...300,
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

        profileStore.profile = FitnessProfile(
            sport: sport,
            goal: goal,
            trainingDays: trainingDays,
            calorieGoal: calorieGoal,
            proteinGoal: proteinGoal
        )

        dismiss()
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
