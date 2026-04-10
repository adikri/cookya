import XCTest
@testable import cookya

final class GeneratedRecipeCachePolicyTests: XCTestCase {
    func testEvictsOldestFingerprintsBeyondLimit() {
        let baseDate = Date(timeIntervalSince1970: 1_000)
        let keys: Set<String> = ["first", "second", "third"]
        let timestamps = [
            "first": baseDate,
            "second": baseDate.addingTimeInterval(10),
            "third": baseDate.addingTimeInterval(20)
        ]

        let evicted = GeneratedRecipeCachePolicy.fingerprintsToEvict(
            cacheKeys: keys,
            timestamps: timestamps,
            limit: 2
        )

        XCTAssertEqual(evicted, ["first"])
    }

    func testEvictsAllFingerprintsWhenLimitIsZero() {
        let keys: Set<String> = ["first", "second"]

        let evicted = GeneratedRecipeCachePolicy.fingerprintsToEvict(
            cacheKeys: keys,
            timestamps: [:],
            limit: 0
        )

        XCTAssertEqual(evicted, keys)
    }

    func testTreatsMissingTimestampsAsOldest() {
        let baseDate = Date(timeIntervalSince1970: 1_000)
        let keys: Set<String> = ["missingTimestamp", "withTimestamp"]
        let timestamps = ["withTimestamp": baseDate]

        let evicted = GeneratedRecipeCachePolicy.fingerprintsToEvict(
            cacheKeys: keys,
            timestamps: timestamps,
            limit: 1
        )

        XCTAssertEqual(evicted, ["missingTimestamp"])
    }

    func testUsesFingerprintTieBreakerForEqualTimestamps() {
        let baseDate = Date(timeIntervalSince1970: 1_000)
        let keys: Set<String> = ["b", "a", "c"]
        let timestamps = [
            "a": baseDate,
            "b": baseDate,
            "c": baseDate
        ]

        let evicted = GeneratedRecipeCachePolicy.fingerprintsToEvict(
            cacheKeys: keys,
            timestamps: timestamps,
            limit: 2
        )

        XCTAssertEqual(evicted, ["a"])
    }
}
