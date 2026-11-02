import Charts
import SwiftUI

// Ports of ui/ElevationChartDialog.kt and ui/SunMoonChartDialog.kt, drawn with Swift Charts.

private func hourAxis() -> some AxisContent {
    AxisMarks(values: .stride(by: .hour, count: 2)) { _ in
        AxisGridLine()
        AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .abbreviated)))
    }
}

private func altitudeAxis() -> some AxisContent {
    AxisMarks(position: .leading, values: [0.0, 30.0, 60.0, 90.0]) { value in
        AxisGridLine()
        AxisValueLabel { if let v = value.as(Double.self) { Text("\(Int(v))°") } }
    }
}

/// Altitude of one object across tonight's session, with the below-horizon band shaded.
struct ElevationChartSheet: View {
    @Environment(SkyModel.self) private var model
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    let target: CatalogTarget
    @State private var samples: [AltitudeSample] = []

    private let minAlt = -20.0, maxAlt = 90.0

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Elevation tonight (6pm - 6am)").font(.caption)
                if let first = samples.first, let last = samples.last {
                    Chart {
                        RectangleMark(xStart: .value("Start", first.time), xEnd: .value("End", last.time),
                                      yStart: .value("Low", minAlt), yEnd: .value("Horizon", 0.0))
                            .foregroundStyle(Color.gray.opacity(0.15))
                        ForEach(samples, id: \.time) { s in
                            LineMark(x: .value("Time", s.time), y: .value("Altitude", min(max(s.altitudeDeg, minAlt), maxAlt)))
                                .foregroundStyle(theme.accent)
                                .lineStyle(StrokeStyle(lineWidth: 2.5))
                        }
                        if (first.time...last.time).contains(model.now) {
                            RuleMark(x: .value("Now", model.now))
                                .foregroundStyle(theme.accent.opacity(0.5))
                                .lineStyle(StrokeStyle(lineWidth: 1.5))
                        }
                    }
                    .chartYScale(domain: minAlt...maxAlt)
                    .chartXScale(domain: first.time...last.time)
                    .chartXAxis { hourAxis() }
                    .chartYAxis { altitudeAxis() }
                    .frame(height: 240)
                } else {
                    ProgressView().frame(maxWidth: .infinity, minHeight: 240)
                }
                Spacer()
            }
            .foregroundStyle(theme.text)
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.background)
            .navigationTitle(target.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .themedNavigationBar(theme)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Close") { dismiss() } } }
            .task { samples = await model.elevationSeries(for: target) }
        }
        .presentationDetents([.medium, .large])
    }
}

/// Sun and Moon altitude across tonight's session, shaded by how dark the sky is.
struct SunMoonChartSheet: View {
    @Environment(SkyModel.self) private var model
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @State private var sun: [AltitudeSample] = []
    @State private var moon: [AltitudeSample] = []

    private let minAlt = -24.0, maxAlt = 90.0
    private var sunColor: Color { theme.night ? AppTheme.nightRed : Color(red: 0.984, green: 0.549, blue: 0) }   // #FB8C00
    private var moonColor: Color { theme.night ? Color(red: 0.545, green: 0, blue: 0) : Color(red: 0.471, green: 0.565, blue: 0.612) } // #8B0000 / #78909C
    /// The shading color: black by day; at night (black background) a faint red so the bands still show.
    private var shade: Color { theme.night ? AppTheme.nightRed.opacity(0.5) : .black }

    /// Daylight clear, civil+nautical twilight light, astronomical twilight medium, full night darkest.
    static func bandOpacity(sunAltitude: Double) -> Double {
        if sunAltitude >= RiseSetThresholds.sun { return 0 }
        if sunAltitude >= -12 { return 0.25 }
        if sunAltitude >= -18 { return 0.45 }
        return 0.65
    }

    private struct Band: Identifiable { let id: Int; let start: Date; let end: Date; let opacity: Double }

    private var bands: [Band] {
        guard sun.count > 1 else { return [] }
        return (0..<(sun.count - 1)).compactMap { i in
            let mid = (sun[i].altitudeDeg + sun[i + 1].altitudeDeg) / 2
            let o = Self.bandOpacity(sunAltitude: mid)
            return o > 0 ? Band(id: i, start: sun[i].time, end: sun[i + 1].time, opacity: o) : nil
        }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Altitude by hour (6pm - 6am)").font(.caption)
                if let first = sun.first, let last = sun.last {
                    Chart {
                        ForEach(bands) { b in
                            RectangleMark(xStart: .value("Start", b.start), xEnd: .value("End", b.end),
                                          yStart: .value("Low", minAlt), yEnd: .value("High", maxAlt))
                                .foregroundStyle(shade.opacity(b.opacity))
                        }
                        ForEach(moon, id: \.time) { s in
                            LineMark(x: .value("Time", s.time), y: .value("Altitude", clamp(s.altitudeDeg)),
                                     series: .value("Body", "Moon"))
                                .foregroundStyle(moonColor)
                                .lineStyle(StrokeStyle(lineWidth: 2.5))
                        }
                        ForEach(sun, id: \.time) { s in
                            LineMark(x: .value("Time", s.time), y: .value("Altitude", clamp(s.altitudeDeg)),
                                     series: .value("Body", "Sun"))
                                .foregroundStyle(sunColor)
                                .lineStyle(StrokeStyle(lineWidth: 2.5))
                        }
                        if (first.time...last.time).contains(model.now) {
                            RuleMark(x: .value("Now", model.now))
                                .foregroundStyle(Color.gray.opacity(0.7))
                                .lineStyle(StrokeStyle(lineWidth: 1.5))
                        }
                    }
                    .chartYScale(domain: minAlt...maxAlt)
                    .chartXScale(domain: first.time...last.time)
                    .chartXAxis { hourAxis() }
                    .chartYAxis { altitudeAxis() }
                    .frame(height: 240)
                    legend
                } else {
                    ProgressView().frame(maxWidth: .infinity, minHeight: 240)
                }
                Spacer()
            }
            .foregroundStyle(theme.text)
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.background)
            .navigationTitle("Sun & Moon Tonight")
            .navigationBarTitleDisplayMode(.inline)
            .themedNavigationBar(theme)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Close") { dismiss() } } }
            .task {
                let series = await model.sunMoonSeries()
                sun = series.sun
                moon = series.moon
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func clamp(_ alt: Double) -> Double { min(max(alt, minAlt), maxAlt) }

    private var legend: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 12) {
                swatch(sunColor, "Sun")
                swatch(moonColor, "Moon")
            }
            HStack(spacing: 12) {
                swatch(shade.opacity(0.25), "Twilight")
                swatch(shade.opacity(0.45), "Astro. twilight")
                swatch(shade.opacity(0.65), "Night")
            }
        }
        .font(.caption2)
    }

    private func swatch(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 4) {
            Rectangle().fill(color).frame(width: 10, height: 10)
                .overlay(Rectangle().strokeBorder(Color.gray.opacity(0.4), lineWidth: 0.5))
            Text(label)
        }
    }
}
