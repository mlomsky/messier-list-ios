import SwiftUI

/// Magnitude limit and hide-below-horizon. Port of ui/DisplayFiltersDialog.kt.
struct DisplayFiltersSheet: View {
    @Environment(SkyModel.self) private var model
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @State private var magnitudeText = ""
    @State private var hideBelowHorizon = false

    private var parsedMagnitude: Double? {
        Double(magnitudeText.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: "."))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Limiting magnitude")
                        Spacer()
                        TextField("12.0", text: $magnitudeText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .foregroundStyle(parsedMagnitude == nil ? .red : theme.text)
                    }
                    .themedRow(theme)
                } footer: {
                    Text("Only show objects (Planets, Messier, and NGC) at or brighter than this magnitude "
                         + "(lower numbers are brighter). Objects with no published magnitude are always shown.")
                }
                Section {
                    Toggle("Hide objects currently below the horizon", isOn: $hideBelowHorizon)
                        .themedRow(theme)
                }
            }
            .themedForm(theme)
            .navigationTitle("Display Filters")
            .navigationBarTitleDisplayMode(.inline)
            .themedNavigationBar(theme)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let limit = parsedMagnitude, limit != model.settings.ngcMagnitudeLimit {
                            model.setMagnitudeLimit(limit)
                        }
                        model.setHideBelowHorizon(hideBelowHorizon)
                        dismiss()
                    }
                    .disabled(parsedMagnitude == nil)
                }
            }
            .onAppear {
                magnitudeText = String(format: "%.1f", model.settings.ngcMagnitudeLimit)
                hideBelowHorizon = model.settings.hideBelowHorizon
            }
        }
        .presentationDetents([.medium])
    }
}
