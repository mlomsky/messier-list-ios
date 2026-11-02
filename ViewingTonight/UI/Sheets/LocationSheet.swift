import SwiftUI

/// Search for a city/address, or go back to GPS. Port of ui/LocationSearchDialog.kt.
struct LocationSheet: View {
    @Environment(SkyModel.self) private var model
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var isSearching = false
    @State private var errorMessage: String?
    @FocusState private var fieldFocused: Bool

    private var canSearch: Bool { !query.trimmingCharacters(in: .whitespaces).isEmpty && !isSearching }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("City or address", text: $query)
                        .textContentType(.fullStreetAddress)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .focused($fieldFocused)
                        .onSubmit(search)
                        .themedRow(theme)
                    if let errorMessage {
                        Text(errorMessage).foregroundStyle(theme.night ? AppTheme.nightRed : .red).themedRow(theme)
                    }
                } footer: {
                    Text("Currently: \(model.location.label)")
                }
                Section {
                    Button(action: search) {
                        HStack {
                            Text(isSearching ? "Searching…" : "Search")
                            if isSearching { Spacer(); ProgressView() }
                        }
                    }
                    .disabled(!canSearch)
                    .themedRow(theme)
                    Button {
                        Task { await model.useGpsLocation() }
                        dismiss()
                    } label: {
                        Label("Use GPS", systemImage: "location.fill")
                    }
                    .themedRow(theme)
                }
            }
            .themedForm(theme)
            .navigationTitle("Set Location")
            .navigationBarTitleDisplayMode(.inline)
            .themedNavigationBar(theme)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
            .onAppear { fieldFocused = true }
        }
        .presentationDetents([.medium])
    }

    private func search() {
        guard canSearch else { return }
        isSearching = true
        errorMessage = nil
        Task {
            let result = await model.searchLocation(query)
            isSearching = false
            if let result {
                await model.setCustomLocation(result)
                dismiss()
            } else {
                errorMessage = "Location not found"
            }
        }
    }
}
