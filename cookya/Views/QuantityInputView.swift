import SwiftUI

struct QuantityInputView: View {
    let title: String
    @Binding var quantityText: String

    @State private var mode: InputMode = .structured
    @State private var amountText = ""
    @State private var unit: QuantityUnit = .count
    @State private var customText = ""
    @State private var isApplyingInternalBindingChange = false

    enum InputMode: String, CaseIterable, Identifiable {
        case structured
        case custom

        var id: String { rawValue }

        var title: String {
            switch self {
            case .structured: return "Quick Pick"
            case .custom: return "Custom"
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker(title, selection: $mode) {
                ForEach(InputMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            if mode == .structured {
                HStack(spacing: 12) {
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)

                    Picker("Unit", selection: $unit) {
                        ForEach(QuantityUnit.allCases, id: \.self) { unit in
                            Text(unit.displayName).tag(unit)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                TextField("Custom quantity", text: $customText)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .onAppear(perform: loadFromBinding)
        .onChange(of: quantityText) { _, newValue in
            if isApplyingInternalBindingChange {
                isApplyingInternalBindingChange = false
                return
            }
            loadFromBinding(using: newValue)
        }
        .onChange(of: mode) { _, _ in syncBinding() }
        .onChange(of: amountText) { _, _ in syncBinding() }
        .onChange(of: unit) { _, _ in syncBinding() }
        .onChange(of: customText) { _, _ in syncBinding() }
    }

    private func loadFromBinding() {
        loadFromBinding(using: quantityText)
    }

    private func loadFromBinding(using value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if let structured = StructuredQuantity.parse(trimmed) {
            mode = .structured
            amountText = structured.formattedAmount
            unit = structured.unit
        } else {
            mode = .custom
            customText = trimmed
        }
    }

    private func syncBinding() {
        let newValue: String
        switch mode {
        case .structured:
            let trimmedAmount = amountText.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedAmount.isEmpty {
                applyBindingValue("")
                return
            }
            guard let amount = Double(trimmedAmount) else {
                return
            }
            newValue = StructuredQuantity(amount: amount, unit: unit).displayText
        case .custom:
            newValue = customText.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        applyBindingValue(newValue)
    }

    private func applyBindingValue(_ newValue: String) {
        guard quantityText != newValue else { return }
        isApplyingInternalBindingChange = true
        quantityText = newValue
    }
}
