import XCTest
@testable import cookya

final class SupabaseErrorDiagnosticsTests: XCTestCase {
    func testInventorySyncErrorMapsSwiftCancellationError() {
        XCTAssertEqual(
            SupabaseErrorDiagnostics.inventorySyncError(from: CancellationError()),
            .cancelled
        )
    }

    func testInventorySyncErrorMapsCancelledURLError() {
        let error = URLError(.cancelled)
        XCTAssertEqual(SupabaseErrorDiagnostics.inventorySyncError(from: error), .cancelled)
    }

    func testInventorySyncErrorMapsOtherURLErrorToNetwork() {
        let error = URLError(.notConnectedToInternet)
        XCTAssertEqual(SupabaseErrorDiagnostics.inventorySyncError(from: error), .networkError)
    }

    func testInventorySyncErrorMapsDecodingError() throws {
        struct Sample: Decodable { let value: Int }
        let error = try XCTUnwrap(capturedDecodingError(for: #"{"value":"wrong"}"#))
        XCTAssertEqual(SupabaseErrorDiagnostics.inventorySyncError(from: error), .decodingFailed)
    }

    func testSnapshotSyncErrorMapsDecodingError() throws {
        struct Sample: Decodable { let value: Int }
        let error = try XCTUnwrap(capturedDecodingError(for: #"{"value":"wrong"}"#))
        XCTAssertEqual(SupabaseErrorDiagnostics.snapshotSyncError(from: error), .decodingFailed)
    }

    func testMetadataIncludesNSErrorDetails() {
        let error = NSError(domain: "TestDomain", code: 42, userInfo: [NSLocalizedDescriptionKey: "Test failure"])
        let metadata = SupabaseErrorDiagnostics.metadata(for: error)

        XCTAssertEqual(metadata["domain"], "TestDomain")
        XCTAssertEqual(metadata["code"], "42")
        XCTAssertEqual(metadata["localizedDescription"], "Test failure")
    }

    private func capturedDecodingError(for json: String) -> Error? {
        struct Sample: Decodable { let value: Int }
        do {
            _ = try JSONDecoder().decode(Sample.self, from: Data(json.utf8))
            return nil
        } catch {
            return error
        }
    }
}
