import XCTest

@testable import NewSDK

/// Verifies the fr/en `NewSDKLocalizable.strings` tables and that every `"…".sdkLocalized`
/// message used in the SDK sources has a translation.
final class LocalizationTests: XCTestCase {

    /// Keys whose text is legitimately identical in English and French.
    private static let sameInBothLanguages: Set<String> = ["common.ok"]

    private func table(_ lang: String) throws -> [String: String] {
        let path = try XCTUnwrap(
            Bundle.sdk.path(
                forResource: "NewSDKLocalizable",
                ofType: "strings",
                inDirectory: nil,
                forLocalization: lang),
            "missing \(lang).lproj/NewSDKLocalizable.strings in the SDK resource bundle")
        let dict = try XCTUnwrap(
            NSDictionary(contentsOfFile: path) as? [String: String],
            "\(lang) strings file is not a valid .strings plist")
        return dict
    }

    /// Keys of every `"literal".sdkLocalized` found in the SDK sources.
    private func keysUsedInSources() throws -> Set<String> {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("NewSDK")
        let files = try XCTUnwrap(FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil))
        let regex = try NSRegularExpression(pattern: #""((?:[^"\\]|\\.)*)"\s*\.sdkLocalized"#)
        var keys = Set<String>()
        for case let url as URL in files where url.pathExtension == "swift" {
            let source = try String(contentsOf: url, encoding: .utf8)
            for m in regex.matches(in: source, range: NSRange(source.startIndex..., in: source)) {
                let raw = String(source[Range(m.range(at: 1), in: source)!])
                keys.insert(
                    raw.replacingOccurrences(of: "\\n", with: "\n")
                        .replacingOccurrences(of: "\\\"", with: "\"")
                        .replacingOccurrences(of: "\\\\", with: "\\"))
            }
        }
        return keys
    }

    func testBothTablesHaveTheSameKeys() throws {
        let en = try table("en"), fr = try table("fr")
        XCTAssertFalse(en.isEmpty)
        XCTAssertEqual(Set(en.keys), Set(fr.keys))
    }

    func testEveryKeyUsedInCodeIsTranslated() throws {
        let used = try keysUsedInSources()
        XCTAssertGreaterThanOrEqual(used.count, 15, "source scan found suspiciously few messages")
        let en = try table("en"), fr = try table("fr")
        for key in used {
            XCTAssertNotNil(en[key], "missing English translation for: \(key)")
            XCTAssertNotNil(fr[key], "missing French translation for: \(key)")
        }
    }

    func testNoUnusedTranslations() throws {
        let used = try keysUsedInSources()
        let unused = Set(try table("en").keys).subtracting(used)
        XCTAssertTrue(unused.isEmpty, "translations not referenced from code: \(unused)")
    }

    func testKeysAreShortIdentifiers() throws {
        let pattern = try NSRegularExpression(pattern: "^[a-z]+\\.[a-zA-Z]+$")
        for key in try table("en").keys {
            let range = NSRange(key.startIndex..., in: key)
            XCTAssertNotNil(pattern.firstMatch(in: key, range: range), "key is not <group>.<name>: \(key)")
            XCTAssertLessThanOrEqual(key.count, 30, "key is too long: \(key)")
        }
    }

    func testEveryKeyHasANonEmptyDistinctEnglishAndFrenchText() throws {
        let en = try table("en"), fr = try table("fr")
        for (key, french) in fr {
            let english = try XCTUnwrap(en[key])
            XCTAssertFalse(french.isEmpty, "empty French text for: \(key)")
            XCTAssertFalse(english.isEmpty, "empty English text for: \(key)")
            if !Self.sameInBothLanguages.contains(key) {
                XCTAssertNotEqual(english, french, "English text not translated for: \(key)")
            }
            XCTAssertNotEqual(french, key, "French text is just the key for: \(key)")
        }
    }

    func testEnglishTranslationOfOriginalCinAlert() throws {
        XCTAssertEqual(try table("en")["alert.useOriginalCin"], "Please use an original CIN card")
        XCTAssertEqual(try table("fr")["alert.useOriginalCin"], "Veuillez utiliser une carte CIN originale")
    }

    func testPlaceholdersAndNewlinesArePreserved() throws {
        let en = try table("en"), fr = try table("fr")
        for (key, english) in en {
            let french = try XCTUnwrap(fr[key])
            XCTAssertEqual(
                french.components(separatedBy: "\n").count,
                english.components(separatedBy: "\n").count,
                "line breaks differ for: \(key)")
        }
    }

    func testSdkLocalizedFallsBackToKeyWhenMissing() {
        XCTAssertEqual("unknown.key".sdkLocalized, "unknown.key")
    }
}
