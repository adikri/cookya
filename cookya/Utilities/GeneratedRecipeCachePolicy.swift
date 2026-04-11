import Foundation

nonisolated
enum GeneratedRecipeCachePolicy {
    static func fingerprintsToEvict(
        cacheKeys: Set<String>,
        timestamps: [String: Date],
        limit: Int
    ) -> Set<String> {
        guard limit > 0 else {
            return cacheKeys
        }

        let overflowCount = cacheKeys.count - limit
        guard overflowCount > 0 else {
            return []
        }

        let orderedKeys = cacheKeys.sorted { lhs, rhs in
            let lhsDate = timestamps[lhs] ?? .distantPast
            let rhsDate = timestamps[rhs] ?? .distantPast

            if lhsDate != rhsDate {
                return lhsDate < rhsDate
            }

            return lhs < rhs
        }

        return Set(orderedKeys.prefix(overflowCount))
    }
}
