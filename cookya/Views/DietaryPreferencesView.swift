import SwiftUI

struct DietaryPreferencesView: View {
    @EnvironmentObject private var profileStore: ProfileStore
    @Environment(\.dismiss) private var dismiss

    @State private var isVegetarian = false
    @State private var customItem = ""
    @State private var selectedAvoidFoods: [String] = []

    private let quickPresets = ["Dairy", "Nuts", "Gluten", "Shellfish", "Soy", "Egg"]

    var body: some View {
        Form {
            Section("Preferences") {
                Toggle("Vegetarian", isOn: $isVegetarian)
            }

            Section("Avoid food presets") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 8)], spacing: 8) {
                    ForEach(quickPresets, id: \.self) { item in
                        Button {
                            toggle(item)
                        } label: {
                            Text(item)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(selectedAvoidFoods.contains(item) ? Color.blue.opacity(0.15) : Color.gray.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Custom avoid items") {
                HStack {
                    TextField("Add item", text: $customItem)
                    Button("Add") {
                        let value = customItem.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !value.isEmpty else { return }
                        if !selectedAvoidFoods.contains(value) {
                            selectedAvoidFoods.append(value)
                        }
                        customItem = ""
                    }
                }

                ForEach(selectedAvoidFoods, id: \.self) { item in
                    Text(item)
                }
                .onDelete { offsets in
                    selectedAvoidFoods.remove(atOffsets: offsets)
                }
            }

            Section {
                Button("Save preferences") {
                    savePreferences()
                }
            }
        }
        .navigationTitle("Dietary Preferences")
        .onAppear {
            loadPreferences()
            AppLogger.screen("DietaryPreferences", metadata: ["profile": profileStore.activeProfile?.name ?? "Guest"])
        }
    }

    private func loadPreferences() {
        let profile = profileStore.primaryProfile ?? profileStore.activeProfile
        isVegetarian = profile?.isVegetarian ?? false
        selectedAvoidFoods = profile?.avoidFoodItems ?? []
    }

    private func toggle(_ item: String) {
        if let index = selectedAvoidFoods.firstIndex(of: item) {
            selectedAvoidFoods.remove(at: index)
        } else {
            selectedAvoidFoods.append(item)
        }
    }

    private func savePreferences() {
        AppLogger.action(
            "dietary_preferences_saved",
            screen: "DietaryPreferences",
            metadata: [
                "vegetarian": isVegetarian ? "true" : "false",
                "avoid_food_count": String(selectedAvoidFoods.count)
            ]
        )
        let current = profileStore.primaryProfile ?? profileStore.activeProfile
        profileStore.updateActiveProfile(
            name: current?.name ?? "Guest",
            age: current?.age,
            weightKg: current?.weightKg,
            heightCm: current?.heightCm,
            location: current?.location,
            isVegetarian: isVegetarian,
            avoidFoodItems: selectedAvoidFoods
        )
        dismiss()
    }
}

#Preview {
    NavigationStack {
        DietaryPreferencesView()
            .environmentObject(ProfileStore())
    }
}
