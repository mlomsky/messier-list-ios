import SwiftUI

/// Filter the list by name, type, compass direction and minimum altitude. Port of ui/SearchDialog.kt.
struct SearchSheet: View {
    @Environment(SkyModel.self) private var model
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var type = ""
    @State private var direction: String?
    @State private var minAltitudeText = ""

    private var minAltitudeValid: Bool {
        minAltitudeText.trimmingCharacters(in: .whitespaces).isEmpty || minAltitude != nil
    }
    private var minAltitude: Double? {
        Double(minAltitudeText.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: "."))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name contains", text: $name).autocorrectionDisabled().themedRow(theme)
                    TextField("Type contains (e.g. Galaxy)", text: $type).autocorrectionDisabled().themedRow(theme)
                }
                Section("Direction in sky") {
                    VStack(spacing: 6) {
                        directionRow(Array(CompassPoints.all.prefix(4)))
                        directionRow(Array(CompassPoints.all.suffix(4)))
                    }
                    .padding(.vertical, 4)
                    .themedRow(theme)
                }
                Section {
                    HStack {
                        Text("Minimum altitude (°)")
                        Spacer()
                        TextField("any", text: $minAltitudeText)
                            .keyboardType(.numbersAndPunctuation)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .foregroundStyle(minAltitudeValid ? theme.text : .red)
                    }
                    .themedRow(theme)
                }
                Section {
                    Button("Clear search", role: .destructive) {
                        model.searchFilter = ObjectSearchFilter()
                        dismiss()
                    }
                    .themedRow(theme)
                }
            }
            .themedForm(theme)
            .navigationTitle("Search Objects")
            .navigationBarTitleDisplayMode(.inline)
            .themedNavigationBar(theme)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Search") {
                        model.searchFilter = ObjectSearchFilter(
                            nameQuery: name.trimmingCharacters(in: .whitespaces),
                            typeQuery: type.trimmingCharacters(in: .whitespaces),
                            direction: direction,
                            minAltitudeDeg: minAltitude)
                        dismiss()
                    }
                    .disabled(!minAltitudeValid)
                }
            }
            .onAppear {
                let f = model.searchFilter
                name = f.nameQuery
                type = f.typeQuery
                direction = f.direction
                minAltitudeText = f.minAltitudeDeg.map { String(format: "%.0f", $0) } ?? ""
            }
        }
    }

    private func directionRow(_ points: [String]) -> some View {
        HStack(spacing: 6) {
            ForEach(points, id: \.self) { point in
                Chip(point, selected: direction == point) {
                    direction = (direction == point) ? nil : point
                }
            }
        }
    }
}
