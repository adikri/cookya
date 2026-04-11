import SwiftUI

struct ProfileOnboardingView: View {
    @EnvironmentObject private var profileStore: ProfileStore

    @State private var name = ""
    @State private var age = ""
    @State private var weightKg = ""
    @State private var heightCm = ""
    @State private var location = ""
    @State private var isVegetarian = false
    @State private var avoidFoodCSV = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile Setup") {
                    TextField("Name", text: $name)
                    TextField("Age", text: $age)
                        .keyboardType(.numberPad)
                    TextField("Weight (kg)", text: $weightKg)
                        .keyboardType(.decimalPad)
                    TextField("Height (cm)", text: $heightCm)
                        .keyboardType(.decimalPad)
                    TextField("Location", text: $location)
                    Toggle("Vegetarian", isOn: $isVegetarian)
                    TextField("Avoid food items (comma separated)", text: $avoidFoodCSV)
                }

                if let bmi = calculatedBMI {
                    Section("BMI") {
                        Text("\(bmi, specifier: "%.1f")")
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }

                Section {
                    Button("Create Profile") {
                        createProfile()
                    }
                    Button("Continue as Guest") {
                        AppLogger.action("continue_as_guest", screen: "ProfileOnboarding")
                        profileStore.continueAsGuest()
                    }
                }
            }
            .navigationTitle("Welcome to Cookya")
            .onAppear {
                AppLogger.screen("ProfileOnboarding")
            }
        }
    }

    private var calculatedBMI: Double? {
        guard let weight = Double(weightKg),
              let height = Double(heightCm),
              height > 0
        else { return nil }

        let meters = height / 100
        let value = weight / (meters * meters)
        return (value * 10).rounded() / 10
    }

    private func createProfile() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Name is required to create profile."
            return
        }

        errorMessage = nil

        let parsedAge = Int(age)
        let parsedWeight = Double(weightKg)
        let parsedHeight = Double(heightCm)
        let parsedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
        let parsedAvoidFoods = avoidFoodCSV
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        profileStore.createRegisteredProfile(
            name: trimmedName,
            age: parsedAge,
            weightKg: parsedWeight,
            heightCm: parsedHeight,
            location: parsedLocation.isEmpty ? nil : parsedLocation,
            isVegetarian: isVegetarian,
            avoidFoodItems: parsedAvoidFoods
        )
        AppLogger.action(
            "profile_created",
            screen: "ProfileOnboarding",
            metadata: [
                "name": trimmedName,
                "location": parsedLocation,
                "vegetarian": String(isVegetarian)
            ]
        )
    }
}

struct ProfileOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileOnboardingView()
            .environmentObject(ProfileStore())
    }
}
