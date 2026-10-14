import XCTest

@testable import NewSDK

/// Tests for the `String` helpers (trim, regex matching, name validation, parent-name patterns).
final class StringExtensionTests: XCTestCase {

    func testTrimRemovesOuterSpacesOnly() {
        XCTAssertEqual("  hello world  ".trim(), "hello world")
        XCTAssertEqual("".trim(), "")
        XCTAssertEqual("   ".trim(), "")
    }

    func testMatchesReturnsAllOccurrences() {
        XCTAssertEqual("AB123456 and CD654321".matches(for: "[A-Z]{2}[0-9]{6}"), ["AB123456", "CD654321"])
        XCTAssertEqual("nothing".matches(for: "[0-9]+"), [])
    }

    func testMatchesWithInvalidRegexReturnsEmpty() {
        XCTAssertEqual("abc".matches(for: "[unclosed"), [])
    }

    func testIsValidName() {
        XCTAssertTrue("ALAMI".isValidName)
        XCTAssertTrue("BEN ALI".isValidName)
        XCTAssertFalse("Alami".isValidName)
        XCTAssertFalse("AB".isValidName)
        XCTAssertFalse("".isValidName)
    }

    func testIsValidNameAcceptsHyphenAndDotSeparators() {
        XCTAssertTrue("EL-IDRISSI".isValidName)
        XCTAssertTrue("BEN-ALI IDRISSI".isValidName)
        XCTAssertTrue("MOHAMED.ALI".isValidName)
        XCTAssertTrue("EL-IDRISSI".isValidName == Utils.isValidName(testStr: "EL-IDRISSI"))
        XCTAssertFalse("EL_IDRISSI".isValidName)
        XCTAssertFalse("EL-".isValidName)
    }

    func testGenderOfParentRegexMatchesFrenchFiliation() {
        let pattern = "".genderOfParent()
        XCTAssertEqual("fille de".matches(for: pattern), ["fille"])
        XCTAssertEqual("Fils de".matches(for: pattern), ["Fils"])
        XCTAssertEqual("Fille de".matches(for: pattern), ["Fille"])
        XCTAssertEqual("garçon".matches(for: pattern), [])
    }

    func testSonRegexExtractsParentNameAroundSeparator() {
        let pattern = "".son("BEN")
        let found = "ALAMI BEN IDRISSI".matches(for: pattern)
        XCTAssertEqual(found.first, "ALAMI BEN IDRISSI")
    }

    func testSizeCalculationGrowsWithTextAndFont() {
        let small = "Hello".bAi0mr4qmad0BtC0hjiYpW0uphIxqS7n(usingFont: .systemFont(ofSize: 10))
        let large = "Hello".bAi0mr4qmad0BtC0hjiYpW0uphIxqS7n(usingFont: .systemFont(ofSize: 30))
        let longer = "Hello world".bAi0mr4qmad0BtC0hjiYpW0uphIxqS7n(usingFont: .systemFont(ofSize: 10))
        XCTAssertGreaterThan(large.width, small.width)
        XCTAssertGreaterThan(longer.width, small.width)
    }
}
