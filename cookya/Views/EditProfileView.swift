import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject private var profileStore: ProfileStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var age = ""
    @State private var weightKg = ""
    @State private var heightCm = ""
    @State private var location = ""

    var body: some View {
        Form {
            Section("Profile Info") {
                TextField("Name", text: $name)
                TextField("Age", text: $age)
                    .keyboardType(.numberPad)
                TextField("Weight (kg)", text: $weightKg)
                    .keyboardType(.decimalPad)
                TextField("Height (cm)", text: $heightCm)
                    .keyboardType(.decimalPad)
                TextField("Location", text: $location)
            }

            if let bmi = calculatedBMI {
                Section("BMI") {
                    Text("\(bmi, specifier: "%.1f")")
                }
            }

            Section {
                Button("Save changes") {
                    saveProfile()
                }
            }
        }
        .navigationTitle("Edit Profile")
        .onAppear {
            loadProfile()
            AppLogger.screen("EditProfile", metadata: ["profile": profileStore.activeProfile?.name ?? "Guest"])
        }
    }

    private var calculatedBMI: Double? {
        guard let weight = Double(weightKg),
              let height = Double(heightCm),
              height > 0 else { return nil }
        let meters = height / 100
        let bmi = weight / (meters * meters)
        return (bmi * 10).rounded() / 10
    }

    private func loadProfile() {
        let profile = profileStore.primaryProfile ?? profileStore.activeProfile
        name = profile?.name == "Guest" ? "" : (profile?.name ?? "")
        age = profile?.age.map { String($0) } ?? ""
        weightKg = profile?.weightKg.map { String($0) } ?? ""
        heightCm = profile?.heightCm.map { String($0) } ?? ""
        location = profile?.location ?? ""
    }

    private func saveProfile() {
        AppLogger.action(
            "profile_saved",
            screen: "EditProfile",
            metadata: [
                "has_age": Int(age) == nil ? "false" : "true",
                "has_weight": Double(weightKg) == nil ? "false" : "true",
                "has_height": Double(heightCm) == nil ? "false" : "true",
                "has_location": location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "false" : "true"
            ]
        )
        let current = profileStore.primaryProfile ?? profileStore.activeProfile
        profileStore.updateActiveProfile(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? (current?.name ?? "Guest") : name.trimmingCharacters(in: .whitespacesAndNewlines),
            age: Int(age),
            weightKg: Double(weightKg),
            heightCm: Double(heightCm),
            location: location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : location.trimmingCharacters(in: .whitespacesAndNewlines),
            isVegetarian: current?.isVegetarian ?? false,
            avoidFoodItems: current?.avoidFoodItems ?? []
        )
        dismiss()
    }
}

#Preview {
    NavigationStack {
        EditProfileView()
            .environmentObject(ProfileStore())
    }
}
