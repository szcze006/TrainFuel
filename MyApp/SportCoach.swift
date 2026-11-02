import SwiftUI

// Sprint 3: deterministic templates; educational guidance, not individualized medical advice.
struct PlannedExercise: Identifiable {
    let id: String
    let prescription: String
    init(_ id: String, _ prescription: String) { self.id = id; self.prescription = prescription }
}
struct PlannedSession: Identifiable {
    let id: String
    let focus: String
    let minutes: Int
    let exercises: [PlannedExercise]
    init(_ id: String, _ focus: String, _ minutes: Int, _ exercises: [PlannedExercise]) {
        self.id = id; self.focus = focus; self.minutes = minutes; self.exercises = exercises
    }
}

// Pure functions make the recommendations easy to unit test.
enum SportCoach {
    static func templates(_ sport: String) -> [PlannedSession] {
        switch sport {
        case "Soccer": return [
            PlannedSession("Soccer Speed & Agility", "Acceleration and direction changes", 40, [.init("Dynamic warm-up", "8 min"), .init("Short accelerations", "6 x 15 m, full recovery"), .init("Cone changes of direction", "4 x 4 reps"), .init("Cooldown walk", "5 min")]),
            PlannedSession("Soccer Strength", "Lower-body strength and stability", 45, [.init("Goblet squat", "3 x 8"), .init("Reverse lunge", "3 x 8/leg"), .init("Calf raise", "3 x 12"), .init("Side plank", "3 x 25 sec/side")]),
            PlannedSession("Soccer Endurance", "Aerobic conditioning", 35, [.init("Easy warm-up", "8 min"), .init("Conversational run", "20 min"), .init("Walk and stretch", "7 min")])]
        case "Basketball": return [
            PlannedSession("Basketball Agility", "Lateral movement and quick feet", 40, [.init("Dynamic warm-up", "8 min"), .init("Defensive slides", "5 x 20 sec"), .init("Shuttle runs", "5 reps"), .init("Cooldown", "5 min")]),
            PlannedSession("Basketball Power", "Landing mechanics and strength", 45, [.init("Step-ups", "3 x 8/leg"), .init("Squat jumps", "3 x 5, controlled landings"), .init("Dumbbell row", "3 x 10"), .init("Dead bug", "3 x 10")]),
            PlannedSession("Basketball Conditioning", "Repeated efforts", 35, [.init("Warm-up", "8 min"), .init("Court intervals", "8 x 20 sec with 60 sec easy"), .init("Cooldown", "5 min")])]
        case "Football": return [
            PlannedSession("Football Acceleration", "Short-distance speed", 40, [.init("Dynamic warm-up", "10 min"), .init("10 m starts", "6 reps, full recovery"), .init("20 m accelerations", "4 reps"), .init("Cooldown", "5 min")]),
            PlannedSession("Football Strength", "Total-body strength", 50, [.init("Squat variation", "3 x 6-8"), .init("Push-ups", "3 x 8-12"), .init("Dumbbell row", "3 x 10"), .init("Farmer carry", "3 x 30 sec")]),
            PlannedSession("Football Mobility", "Recovery and movement quality", 30, [.init("Mobility circuit", "10 min"), .init("Easy cycling", "15 min"), .init("Stretching", "5 min")])]
        case "Running": return [
            PlannedSession("Running Easy Run", "Aerobic base", 35, [.init("Brisk walk", "5 min"), .init("Conversational run", "20-25 min"), .init("Walk cooldown", "5 min")]),
            PlannedSession("Running Strength", "Supporting muscles and stability", 40, [.init("Split squat", "3 x 8/leg"), .init("Glute bridge", "3 x 12"), .init("Calf raise", "3 x 12"), .init("Plank", "3 x 30 sec")]),
            PlannedSession("Running Intervals", "Controlled pace changes", 35, [.init("Easy jog", "10 min"), .init("Moderate intervals", "5 x 1 min with 2 min easy"), .init("Cooldown jog", "5 min")])]
        case "Volleyball": return [
            PlannedSession("Volleyball Jump Skills", "Controlled takeoff and landing", 40, [.init("Dynamic warm-up", "8 min"), .init("Landing practice", "3 x 5"), .init("Low jump practice", "3 x 5"), .init("Lateral shuffle", "4 x 20 sec")]),
            PlannedSession("Volleyball Strength", "Leg and shoulder stability", 45, [.init("Goblet squat", "3 x 8"), .init("Single-leg RDL", "3 x 8/leg"), .init("Band external rotation", "3 x 12"), .init("Side plank", "3 x 25 sec")]),
            PlannedSession("Volleyball Footwork", "Approach and court movement", 35, [.init("Warm-up", "8 min"), .init("Approach footwork", "5 x 4 reps"), .init("Side-to-side shuffle", "5 x 20 sec"), .init("Cooldown", "5 min")])]
        default: return [PlannedSession("General Fitness", "Movement and consistency", 30, [.init("Brisk walk", "15 min"), .init("Bodyweight squat", "3 x 10"), .init("Push-ups", "3 x 8")])]
        }
    }
    static func weeklyPlan(_ sport: String, days: Int) -> [PlannedSession] {
        let base = templates(sport)
        return (0..<max(1, min(days, 7))).map { base[$0 % base.count] }
    }
    static func fueling(_ sport: String) -> [String] {
        let shared = ["Include protein and carbohydrates in meals after training.", "Drink fluids regularly; replace extra losses during long or hot sessions."]
        switch sport {
        case "Soccer": return ["Before a long practice, choose a familiar carbohydrate-rich meal or snack.", "After extended field sessions, replenish carbohydrates and fluids."] + shared
        case "Basketball": return ["Fuel repeated court efforts with carbohydrates across the day.", "Pack an easy snack between practices or games."] + shared
        case "Football": return ["Eat enough overall to support demanding strength and field sessions.", "Include protein-containing foods across meals."] + shared
        case "Running": return ["For longer runs, plan carbohydrate fueling appropriate to duration.", "Practice race-day foods during training, not for the first time on race day."] + shared
        case "Volleyball": return ["Have a familiar snack before long practices or tournaments.", "Eat regular meals to support repeated jumping and court sessions."] + shared
        default: return shared
        }
    }
    static func recovery(_ sport: String, soreness: Int, sleep: Int) -> String {
        if soreness >= 4 || sleep <= 5 { return "Consider an easier session or rest today. Prioritize sleep and recovery." }
        if soreness == 3 || sleep <= 6 { return "Keep intensity moderate and focus on technique and warm-up." }
        return "If you feel ready, follow your plan and adjust effort to how you feel."
    }
}

struct TrainingPlanView: View {
    @ObservedObject var profileStore: ProfileStore
    @ObservedObject var workoutStore: WorkoutStore
    @ObservedObject var mealStore: MealStore
    @ObservedObject var noteStore: NoteStore
    @AppStorage("sprint3.soreness") private var soreness = 2
    @AppStorage("sprint3.sleep") private var sleep = 8
    @State private var selectedSection = 0
    @State private var completedName: String? = nil
    private var sport: String { profileStore.profile.sport }
    private var plan: [PlannedSession] { SportCoach.weeklyPlan(sport, days: profileStore.profile.trainingDays) }
    private var weekWorkouts: [WorkoutEntry] {
        let calendar = Calendar.current
        return workoutStore.workouts.filter { calendar.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear) }
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Your \(sport) Coach").font(.largeTitle.bold())
                        Text("\(profileStore.profile.trainingDays) sessions/week · \(profileStore.profile.goal)").foregroundStyle(.secondary)
                        Text("\(weekWorkouts.count) workouts logged this week").font(.subheadline).foregroundStyle(.blue)
                    }
                    Picker("Coach section", selection: $selectedSection) {
                        Text("Training").tag(0)
                        Text("Fueling").tag(1)
                        Text("Recovery").tag(2)
                        Text("Calendar").tag(3)
                    }.pickerStyle(.segmented)
                    if selectedSection == 0 { trainingContent }
                    else if selectedSection == 1 { fuelingContent }
                    else if selectedSection == 2 { recoveryContent }
                    else { TrainingCalendarView(profileStore: profileStore, workoutStore: workoutStore, mealStore: mealStore, noteStore: noteStore) }
                    Text("Starter recommendations for general education. Adapt exercise difficulty to your ability and seek qualified guidance for injuries or medical nutrition needs.")
                        .font(.caption).foregroundStyle(.secondary)
                }.padding()
            }
            .navigationTitle("TrainFuel Plan")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Workout logged", isPresented: Binding(get: { completedName != nil }, set: { if !$0 { completedName = nil } })) {
                Button("OK") { completedName = nil }
            } message: { Text("Your workout was added to the Fitness and Progress history.") }
        }
    }
    private var trainingContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Suggested Weekly Sessions").font(.title3.bold())
            ForEach(Array(plan.enumerated()), id: \.offset) { index, session in
                VStack(alignment: .leading, spacing: 10) {
                    Text("Session \(index + 1): \(session.id)").font(.headline)
                    Text("\(session.focus) · ~\(session.minutes) min").font(.subheadline).foregroundStyle(.secondary)
                    ForEach(session.exercises) { exercise in
                        HStack(alignment: .top) {
                            Text(exercise.id)
                            Spacer(minLength: 8)
                            Text(exercise.prescription).foregroundStyle(.secondary).multilineTextAlignment(.trailing)
                        }.font(.subheadline)
                    }
                    Button {
                        workoutStore.addWorkout(name: session.id, type: sport, duration: session.minutes)
                        completedName = session.id
                    } label: {
                        Label("Log Completed Workout", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }.buttonStyle(.borderedProminent)
                }.padding().background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }
    private var fuelingContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Fueling for \(sport)").font(.title3.bold())
            Text("Current goals: \(profileStore.profile.calorieGoal) kcal and \(profileStore.profile.proteinGoal) g protein/day")
                .font(.subheadline).foregroundStyle(.secondary)
            ForEach(SportCoach.fueling(sport), id: \.self) { tip in
                Label(tip, systemImage: "fork.knife.circle").padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
            }
            Text("Targets above are your saved profile goals, not newly calculated medical prescriptions.").font(.caption).foregroundStyle(.secondary)
        }
    }
    private var recoveryContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Recovery Check-in").font(.title3.bold())
            VStack(alignment: .leading) {
                Text("Muscle soreness: \(soreness)/5")
                Slider(value: Binding(get: { Double(soreness) }, set: { soreness = Int($0) }), in: 1...5, step: 1)
                Text("Sleep last night: \(sleep) hours")
                Stepper("Hours slept", value: $sleep, in: 0...14)
            }.padding().background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
            Label(SportCoach.recovery(sport, soreness: soreness, sleep: sleep), systemImage: "heart.text.square")
                .padding().frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
            Text("This check-in is stored on this device, not synchronized to Firebase.").font(.caption).foregroundStyle(.secondary)
        }
    }
}
