import SwiftUI

// Sprint 3 extension. Works with existing ProfileStore, WorkoutStore, MealStore, and SportCoach.
// Water, calendar notes, and recovery check-ins are local to this device.
// Logged meals and completed workouts use the existing Firebase-backed stores.

struct SuggestedMeal: Identifiable {
    let id: String
    let calories: Int
    let protein: Int
    let reason: String
}

enum AthleteNutrition {
    static func meals(for sport: String) -> [SuggestedMeal] {
        let baseline = [
            SuggestedMeal(id: "Eggs, toast & fruit", calories: 460, protein: 26, reason: "Balanced breakfast"),
            SuggestedMeal(id: "Chicken rice bowl", calories: 650, protein: 45, reason: "Protein and carbohydrates for recovery"),
            SuggestedMeal(id: "Greek yogurt & berries", calories: 230, protein: 20, reason: "Convenient snack")
        ]
        switch sport {
        case "Soccer", "Running":
            return [SuggestedMeal(id: "Oatmeal, banana & yogurt", calories: 520, protein: 24, reason: "Carbohydrate-rich training fuel")] + baseline
        case "Basketball", "Volleyball":
            return [SuggestedMeal(id: "Turkey sandwich & fruit", calories: 540, protein: 35, reason: "Portable practice-day meal")] + baseline
        case "Football":
            return [SuggestedMeal(id: "Beef, potatoes & vegetables", calories: 720, protein: 48, reason: "Substantial strength-day meal")] + baseline
        default: return baseline
        }
    }
    static func estimatedMacros(calories: Int, protein: Int) -> (carbs: Int, fat: Int) {
        // Illustrative split of remaining energy; not a prescribed target.
        let remaining = max(0, calories - protein * 4)
        return (Int(Double(remaining) * 0.60 / 4.0), Int(Double(remaining) * 0.40 / 9.0))
    }
}

struct PerformanceHubView: View {
    @ObservedObject var profileStore: ProfileStore
    @ObservedObject var workoutStore: WorkoutStore
    @ObservedObject var mealStore: MealStore
    @ObservedObject var noteStore: NoteStore
    @State private var section = 0
    @AppStorage("sprint3.water.date") private var waterDate = ""
    @AppStorage("sprint3.water.ml") private var waterML = 0
    @AppStorage("sprint3.water.goal") private var waterGoal = 2500

    private var sport: String { profileStore.profile.sport }
    private var todayKey: String { Self.dateKey(Date()) }
    private var todayWater: Int { waterDate == todayKey ? waterML : 0 }
    private var currentWeekWorkouts: [WorkoutEntry] {
        workoutStore.workouts.filter {
            Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear)
        }
    }
    private var weekMinutes: Int { currentWeekWorkouts.reduce(0) { $0 + $1.duration } }

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                Picker("Performance", selection: $section) {
                    Text("Coach").tag(0)
                    Text("Nutrition").tag(1)
                    Text("Water").tag(2)
                    Text("Insights").tag(3)
                }
                .pickerStyle(.menu)
                .padding(.horizontal)
                Group {
                    switch section {
                    case 0: TrainingPlanView(profileStore: profileStore, workoutStore: workoutStore, mealStore: mealStore, noteStore: noteStore)
                    case 1: nutritionPage
                    case 2: waterPage
                    default: insightsPage
                    }
                }
            }
            .navigationTitle("Performance")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var nutritionPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Fuel your \(sport) training").font(.title2.bold())
                Text("Targets are taken from your saved profile. Adjust them with qualified guidance when needed.")
                    .font(.footnote).foregroundStyle(.secondary)
                let target = max(1, profileStore.profile.calorieGoal)
                let proteinTarget = max(1, profileStore.profile.proteinGoal)
                metric("Calories logged", value: mealStore.totalCalories(on: Date()), goal: target, unit: "kcal")
                metric("Protein logged", value: mealStore.totalProtein(on: Date()), goal: profileStore.profile.proteinGoal, unit: "g")
                let macros = AthleteNutrition.estimatedMacros(calories: target, protein: proteinTarget)
                Text("Illustrative remaining-energy split: ~\(macros.carbs) g carbohydrate and ~\(macros.fat) g fat. Not a clinical recommendation.")
                    .font(.caption).foregroundStyle(.secondary)
                Text("Meal ideas").font(.title3.bold())
                ForEach(AthleteNutrition.meals(for: sport)) { meal in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(meal.id).font(.headline)
                        Text("Approx. \(meal.calories) kcal · \(meal.protein) g protein")
                        Text(meal.reason).foregroundStyle(.secondary)
                        Button("Log this meal") {
                            // Macro breakdown is an estimate until a food database is integrated.
                            let remaining = max(0, meal.calories - meal.protein * 4)
                            mealStore.addMeal(FoodEntry(name: meal.id, calories: meal.calories,
                                protein: meal.protein, carbs: Int(Double(remaining) * 0.6 / 4),
                                fat: Int(Double(remaining) * 0.4 / 9)))
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding().background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                }
                Text("Meal quantities and macros are examples. Confirm serving sizes before logging.")
                    .font(.caption).foregroundStyle(.secondary)
            }.padding()
        }
    }

    private var waterPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Daily hydration").font(.title2.bold())
                metric("Water today", value: todayWater, goal: waterGoal, unit: "mL")
                Text("Daily goal (mL): \(waterGoal)")
                Stepper("Adjust goal", value: $waterGoal, in: 500...6000, step: 250)
                HStack {
                    Button("+250 mL") { addWater(250) }
                    Button("+500 mL") { addWater(500) }
                }.buttonStyle(.borderedProminent)
                Button("Undo 250 mL") { addWater(-250) }.buttonStyle(.bordered)
                Text("Water logs are stored on this device and reset for a new day. Your hydration needs vary with climate, exercise, and sweat losses.")
                    .font(.footnote).foregroundStyle(.secondary)
            }.padding()
        }
    }

    private var insightsPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Performance insights").font(.title2.bold())
                metric("Weekly workouts", value: currentWeekWorkouts.count, goal: max(1, profileStore.profile.trainingDays), unit: "sessions")
                HStack {
                    insightCard("Minutes this week", "\(weekMinutes)")
                    insightCard("Meals loaded", "\(mealStore.foods.count)")
                }
                metric("Calories logged", value: mealStore.totalCalories, goal: max(1, profileStore.profile.calorieGoal), unit: "kcal")
                metric("Protein logged", value: mealStore.totalProtein, goal: max(1, profileStore.profile.proteinGoal), unit: "g")
                metric("Water today", value: todayWater, goal: waterGoal, unit: "mL")
                Text("Recent workout activity").font(.headline)
                ForEach(Array(workoutStore.workouts.sorted { $0.date > $1.date }.prefix(7))) { workout in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(workout.name)
                            Text(workout.date, style: .date).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(workout.duration) min").foregroundStyle(.secondary)
                    }
                }
                Text("Nutrition figures reflect meals currently loaded by the existing meal store, not a verified seven-day trend. Water is stored locally.")
                    .font(.caption).foregroundStyle(.secondary)
            }.padding()
        }
    }

    private func metric(_ title: String, value: Int, goal: Int, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            Text("\(value) / \(goal) \(unit)")
            ProgressView(value: Double(max(0, value)), total: Double(max(1, goal)))
                .tint(.blue)
        }.padding().frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
    private func insightCard(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title.bold())
        }.frame(maxWidth: .infinity, alignment: .leading).padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
    private func addWater(_ amount: Int) {
        if waterDate != todayKey { waterDate = todayKey; waterML = 0 }
        waterML = max(0, waterML + amount)
    }
    private static func dateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// Shared by the Plan tab and the Performance hub so both show the same calendar and notes.
struct TrainingCalendarView: View {
    @ObservedObject var profileStore: ProfileStore
    @ObservedObject var workoutStore: WorkoutStore
    @ObservedObject var mealStore: MealStore
    @ObservedObject var noteStore: NoteStore
    @State private var selectedDay = Date()

    private var dayNote: Binding<String> {
        Binding(
            get: { noteStore.note(for: selectedDay) },
            set: { noteStore.saveNote($0, for: selectedDay) }
        )
    }

    private var plan: [PlannedSession] {
        SportCoach.weeklyPlan(profileStore.profile.sport, days: profileStore.profile.trainingDays)
    }
    private var currentWeekWorkouts: [WorkoutEntry] {
        workoutStore.workouts.filter {
            Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly training schedule").font(.title2.bold())
            Text("\(plan.count) planned sessions · \(currentWeekWorkouts.count) workouts logged this week")
                .foregroundStyle(.secondary)
            DatePicker("View day", selection: $selectedDay, displayedComponents: .date)
                .datePickerStyle(.graphical)
            let calendar = Calendar.current
            let weekday = (calendar.component(.weekday, from: selectedDay) + 5) % 7
            if weekday < plan.count {
                let session = plan[weekday]
                Text("Suggested: \(session.id)").font(.headline)
                Text("\(session.focus) · \(session.minutes) min")
                ForEach(session.exercises) { exercise in
                    Text("• \(exercise.id): \(exercise.prescription)")
                }
            } else {
                Text("Recovery or flexible training day").font(.headline)
            }
            let logged = workoutStore.workouts.filter { calendar.isDate($0.date, inSameDayAs: selectedDay) }
            Text("Logged workouts: \(logged.count)").font(.headline)
            ForEach(logged) { workout in
                Text("✓ \(workout.name) · \(workout.duration) min")
            }
            let meals = mealStore.meals(on: selectedDay)
            Text("Logged meals: \(meals.count)").font(.headline)
            if meals.isEmpty {
                Text("No meals logged").foregroundStyle(.secondary)
            } else {
                Text("Total: \(mealStore.totalCalories(on: selectedDay)) kcal · \(mealStore.totalProtein(on: selectedDay)) g protein · \(mealStore.totalCarbs(on: selectedDay)) g carbs · \(mealStore.totalFat(on: selectedDay)) g fat")
                    .font(.subheadline)
                ForEach(meals) { meal in
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(meal.name) · \(meal.calories) kcal")
                        Text("\(meal.protein) g protein · \(meal.carbs) g carbs · \(meal.fat) g fat")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            Text("Notes for \(selectedDay.formatted(.dateTime.month(.abbreviated).day()))").font(.headline)
            TextEditor(text: dayNote).frame(height: 90)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.gray.opacity(0.3)))
            Text("This calendar maps your weekly plan to Monday onward. It does not create calendar events or reschedule sessions automatically.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}
