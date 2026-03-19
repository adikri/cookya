import SwiftUI

struct CookedHistoryView: View {
    @EnvironmentObject private var cookedMealStore: CookedMealStore
    @EnvironmentObject private var profileStore: ProfileStore

    @State private var selectedDate = Calendar.current.startOfDay(for: .now)

    private var records: [CookedMealRecord] {
        cookedMealStore.records(for: profileStore.activeProfile)
    }

    private var availableDates: [Date] {
        Array(Set(records.map { Calendar.current.startOfDay(for: $0.cookedAt) })).sorted(by: >)
    }

    private var recordsForSelectedDate: [CookedMealRecord] {
        records.filter { Calendar.current.isDate($0.cookedAt, inSameDayAs: selectedDate) }
    }

    private var staples: [MealStaple] {
        cookedMealStore.staples(for: profileStore.activeProfile)
    }

    var body: some View {
        List {
            if !staples.isEmpty {
                Section {
                    ForEach(staples.prefix(3)) { staple in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(staple.recipeTitle)
                                    .font(.headline)
                                Spacer()
                                Text("\(staple.cookCount)x")
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.accentColor.opacity(0.12), in: Capsule())
                            }

                            Text("Cooked often • Last made \(staple.lastCookedAt.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                } header: {
                    Text("Staples")
                } footer: {
                    Text("Staples are meals you’ve cooked at least twice.")
                }
            }

            Section("Calendar") {
                DatePicker("Cooked on", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)

                if !availableDates.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(availableDates, id: \.self) { date in
                                Button {
                                    selectedDate = date
                                } label: {
                                    Text(date, format: .dateTime.day().month(.abbreviated))
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            Calendar.current.isDate(date, inSameDayAs: selectedDate)
                                            ? Color.accentColor.opacity(0.18)
                                            : Color.gray.opacity(0.12),
                                            in: Capsule()
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                if availableDates.isEmpty {
                    Text("No meals have been marked as cooked yet.")
                        .foregroundStyle(.secondary)
                } else if !availableDates.contains(where: { Calendar.current.isDate($0, inSameDayAs: selectedDate) }) {
                    Text("No cooked meals for this date.")
                        .foregroundStyle(.secondary)
                }
            }

            if !recordsForSelectedDate.isEmpty {
                Section("Meals") {
                    ForEach(recordsForSelectedDate) { record in
                        NavigationLink {
                            CookedMealDetailView(record: record)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(record.recipeTitle)
                                    .font(.headline)
                                Text(record.cookedAt, style: .time)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if !record.consumptions.isEmpty {
                                    Text(record.consumptions.map { "\($0.pantryItemName)=\($0.usedQuantityText)" }.joined(separator: ", "))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                AppLogger.action(
                                    "cooked_history_deleted",
                                    screen: "CookedHistory",
                                    metadata: ["recipeTitle": record.recipeTitle]
                                )
                                cookedMealStore.deleteRecord(record)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("What Was Cooked?")
        .onAppear {
            if let latestDate = availableDates.first {
                selectedDate = latestDate
            }
            AppLogger.screen("CookedHistory", metadata: ["profile": profileStore.activeProfile?.name ?? "Guest", "count": String(records.count)])
        }
    }
}

private struct CookedMealDetailView: View {
    let record: CookedMealRecord

    var body: some View {
        List {
            Section("Meal") {
                LabeledContent("Recipe", value: record.recipeTitle)
                LabeledContent("Cooked At") {
                    Text(record.cookedAt.formatted(date: .abbreviated, time: .shortened))
                }
                LabeledContent("Profile", value: record.profileNameSnapshot)
            }

            Section("Recipe Ingredients") {
                ForEach(record.recipeIngredients) { ingredient in
                    Text(ingredient.quantity.isEmpty ? ingredient.name : "\(ingredient.name) (\(ingredient.quantity))")
                }
            }

            Section("Used from Pantry") {
                if record.consumptions.isEmpty {
                    Text("No pantry quantities were entered.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(record.consumptions) { consumption in
                        Text("\(consumption.pantryItemName): \(consumption.usedQuantityText)")
                    }
                }
            }

            if !record.warnings.isEmpty {
                Section("Warnings") {
                    ForEach(record.warnings, id: \.self) { warning in
                        Text(warning)
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
        .navigationTitle("Cooked Meal")
        .onAppear {
            AppLogger.action("cooked_history_detail_opened", screen: "CookedMealDetail", metadata: ["recipeTitle": record.recipeTitle])
        }
    }
}

#Preview {
    NavigationStack {
        CookedHistoryView()
            .environmentObject(CookedMealStore())
            .environmentObject(ProfileStore())
    }
}
