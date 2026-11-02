import SwiftUI

/// Record which nebula filter works best for an object. Port of ui/FilterEditDialog.kt.
struct FilterEditSheet: View {
    @Environment(SkyModel.self) private var model
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    let target: CatalogTarget
    @State private var selection = FilterSelection()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("UHC - Narrowband", isOn: $selection.uhc).themedRow(theme)
                    Toggle("OIII", isOn: $selection.oiii).themedRow(theme)
                    Toggle("H-Beta", isOn: $selection.hBeta).themedRow(theme)
                    Toggle("Light Pollution - Wideband", isOn: $selection.lightPollution).themedRow(theme)
                    Toggle("Other", isOn: $selection.otherChecked).themedRow(theme)
                    if selection.otherChecked {
                        TextField("Other filter", text: $selection.otherText).themedRow(theme)
                    }
                } footer: {
                    if DefaultFilters.byId[target.id] != nil {
                        Text("Starting recommendation: \(DefaultFilters.byId[target.id]!)")
                    }
                }
            }
            .themedForm(theme)
            .navigationTitle("Filter - \(target.displayName)")
            .navigationBarTitleDisplayMode(.inline)
            .themedNavigationBar(theme)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        model.setFilter(FilterText.build(selection), for: target)
                        dismiss()
                    }
                }
            }
            .onAppear { selection = FilterText.parse(model.filterText(for: target) ?? "") }
        }
        .presentationDetents([.medium, .large])
    }
}
