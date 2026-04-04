import XCTest
@testable import cookya

final class PersistencePayloadValidatorTests: XCTestCase {
    func testArrayShapeAcceptsJSONArray() {
        XCTAssertTrue(
            PersistencePayloadValidator.matchesExpectedTopLevel(
                Data("[]".utf8),
                shape: .array
            )
        )
    }

    func testArrayShapeRejectsJSONObject() {
        XCTAssertFalse(
            PersistencePayloadValidator.matchesExpectedTopLevel(
                Data("{}".utf8),
                shape: .array
            )
        )
    }

    func testObjectShapeAcceptsJSONObject() {
        XCTAssertTrue(
            PersistencePayloadValidator.matchesExpectedTopLevel(
                Data("{}".utf8),
                shape: .object
            )
        )
    }

    func testObjectShapeRejectsJSONArray() {
        XCTAssertFalse(
            PersistencePayloadValidator.matchesExpectedTopLevel(
                Data("[]".utf8),
                shape: .object
            )
        )
    }

    func testMalformedJSONIsRejected() {
        XCTAssertFalse(
            PersistencePayloadValidator.matchesExpectedTopLevel(
                Data("not-json".utf8),
                shape: .array
            )
        )
    }
}
