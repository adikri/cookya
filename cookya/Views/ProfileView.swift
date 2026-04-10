//
//  ProfileView.swift
//  cookya
//
//  Created by adi on 05/03/26.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var profileStore: ProfileStore
    @EnvironmentObject private var recipeStore: RecipeStore
    @EnvironmentObject private var cookedMealStore: CookedMealStore

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        EditProfileView()
                    } label: {
                        HStack(spacing: 16) {
                            Circle()
                                .fill(profileStore.activeProfile?.type == .guest ? Color.orange.opacity(0.2) : Color.blue.opacity(0.2))
                                .frame(width: 56, height: 56)
                                .overlay {
                                    Image(systemName: profileStore.activeProfile?.type == .guest ? "person.crop.circle.badge.questionmark" : "person.crop.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(profileStore.activeProfile?.type == .guest ? .orange : .blue)
                                }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(profileStore.activeProfile?.name ?? "Guest")
                                    .font(.headline)
                                Text(profileStore.activeProfile?.type == .guest ? "Guest" : "Registered")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                if let location = profileStore.activeProfile?.location, !location.isEmpty {
                                    Text(location)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text(profileStore.activeProfile?.isVegetarian == true ? "Vegetarian" : "No veg filter")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if let bmi = profileStore.primaryProfile?.bmi {
                                    Text("BMI \(bmi, specifier: "%.1f")")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }

                Section("Cooking") {
                    NavigationLink {
                        CookingProfileView()
                    } label: {
                        settingsRow("Who's cooking today?")
                    }

                    NavigationLink {
                        DietaryPreferencesView()
                    } label: {
                        settingsRow("Dietary preferences")
                    }

                    NavigationLink {
                        SavedRecipesView()
                    } label: {
                        settingsRow("Saved recipes")
                    }

                    NavigationLink {
                        CookedHistoryView()
                    } label: {
                        settingsRow("What was cooked?")
                    }
                }

                Section("Mode") {
                    NavigationLink {
                        GuestModeView()
                    } label: {
                        settingsRow("Guest mode")
                    }
                }

                Section("Access") {
                    NavigationLink {
                        BackendAccessView()
                    } label: {
                        settingsRow("Backend access")
                    }
                }

                Section("Backup") {
                    NavigationLink {
                        BackupExportView()
                    } label: {
                        settingsRow("Export / import backup")
                    }
                }

                #if DEBUG
                Section("Debug") {
                    NavigationLink {
                        DebugLogsView()
                    } label: {
                        settingsRow("Debug logs")
                    }
                }
                #endif

                Section("Summary") {
                    Text("Saved recipes for current profile: \(recipeStore.recipes(for: profileStore.activeProfile).count)")
                        .foregroundStyle(.secondary)
                    Text("Cooked meals for current profile: \(cookedMealStore.records(for: profileStore.activeProfile).count)")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Profile")
            .onAppear {
                AppLogger.screen("Profile", metadata: ["profile": profileStore.activeProfile?.name ?? "Guest"])
            }
        }
    }

    private func settingsRow(_ title: String) -> some View {
        HStack {
            Text(title)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .padding(.vertical, 2)
    }
}

#Preview {
    ProfileView()
        .environmentObject(ProfileStore())
        .environmentObject(RecipeStore())
        .environmentObject(CookedMealStore())
}
