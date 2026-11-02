import Foundation

/// Looks up ground elevation for a lat/lon via the free Open Topo Data API.
/// Port of data/ElevationRepository.kt. Returns nil on any failure (offline, timeout, bad data).
nonisolated enum ElevationService {

    private struct Response: Decodable {
        struct Result: Decodable { let elevation: Double? }
        let results: [Result]
    }

    static func lookupMeters(latitudeDeg: Double, longitudeDeg: Double) async -> Double? {
        guard let url = URL(string: "https://api.opentopodata.org/v1/aster30m?locations=\(latitudeDeg),\(longitudeDeg)")
        else { return nil }
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            return try JSONDecoder().decode(Response.self, from: data).results.first?.elevation
        } catch {
            return nil
        }
    }
}
