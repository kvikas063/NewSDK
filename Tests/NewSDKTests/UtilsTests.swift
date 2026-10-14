import XCTest

@testable import NewSDK

/// Tests for `Utils`: CIN, date and name validation and the Jaro similarity used for address matching.
final class UtilsTests: XCTestCase {

    func testIntToString() {
        XCTAssertEqual(Utils.intToString(value: 0), "0")
        XCTAssertEqual(Utils.intToString(value: 42), "42")
        XCTAssertEqual(Utils.intToString(value: -7), "-7")
    }

    // MARK: CIN number

    func testValidCIN() {
        XCTAssertTrue(Utils.isValidCIN(testStr: "AB123456"))
        XCTAssertTrue(Utils.isValidCIN(testStr: "A1234"))
        XCTAssertTrue(Utils.isValidCIN(testStr: "Z999999"))
    }

    func testInvalidCIN() {
        XCTAssertFalse(Utils.isValidCIN(testStr: ""))
        XCTAssertFalse(Utils.isValidCIN(testStr: "AB123"))  // too few digits
        XCTAssertFalse(Utils.isValidCIN(testStr: "AB1234567"))  // too many digits
        XCTAssertFalse(Utils.isValidCIN(testStr: "ABC12345"))  // too many letters
        XCTAssertFalse(Utils.isValidCIN(testStr: "ab123456"))  // lowercase
        XCTAssertFalse(Utils.isValidCIN(testStr: "123456"))  // no letters
        XCTAssertFalse(Utils.isValidCIN(testStr: " AB123456"))  // must match whole string
    }

    // MARK: dates

    func testValidDate() {
        XCTAssertTrue(Utils.isValidDate(testStr: "01.02.2030"))
        XCTAssertTrue(Utils.isValidDate(testStr: "2030"))
    }

    func testInvalidDate() {
        XCTAssertFalse(Utils.isValidDate(testStr: "1.2.2030"))
        XCTAssertFalse(Utils.isValidDate(testStr: "01/02/2030"))
        XCTAssertFalse(Utils.isValidDate(testStr: "203"))
        XCTAssertFalse(Utils.isValidDate(testStr: ""))
    }

    func testValidDateNaissance() {
        XCTAssertTrue(Utils.isValidDateNaissance(testStr: "1234567A"))
        XCTAssertFalse(Utils.isValidDateNaissance(testStr: "123456A"))
        XCTAssertFalse(Utils.isValidDateNaissance(testStr: "1234567a"))
        XCTAssertFalse(Utils.isValidDateNaissance(testStr: "12345678"))
    }

    func testValidDateExpiration() {
        XCTAssertTrue(Utils.isValidDateExpiration(testStr: "Valable 01.02.2030"))
        XCTAssertTrue(Utils.isValidDateExpiration(testStr: "Date d'expiration Valable 31.12.2035 ."))
        XCTAssertTrue(Utils.isValidDateExpiration(testStr: "Expire 01.02.2030"))
    }

    func testInvalidDateExpiration() {
        XCTAssertFalse(Utils.isValidDateExpiration(testStr: ""))
        XCTAssertFalse(Utils.isValidDateExpiration(testStr: "no date here"))
        XCTAssertFalse(Utils.isValidDateExpiration(testStr: "01.02.2030"))  // needs the leading word
        XCTAssertFalse(Utils.isValidDateExpiration(testStr: "Valable 1.2.2030"))  // malformed date
        XCTAssertFalse(Utils.isValidDateExpiration(testStr: "Va 01.02.2030"))  // word shorter than 3 letters
    }

    // MARK: names

    func testValidName() {
        XCTAssertTrue(Utils.isValidName(testStr: "ALAMI"))
        XCTAssertTrue(Utils.isValidName(testStr: "EL ALAMI"))
        XCTAssertTrue(Utils.isValidName(testStr: "BEN-ALI IDRISSI"))
        XCTAssertTrue(Utils.isValidName(testStr: "M'BAREK"))
    }

    func testInvalidName() {
        XCTAssertFalse(Utils.isValidName(testStr: ""))
        XCTAssertFalse(Utils.isValidName(testStr: "AL"))
        XCTAssertFalse(Utils.isValidName(testStr: "alami"))
        XCTAssertFalse(Utils.isValidName(testStr: "ALAMI 123"))
    }

    // MARK: similarity (address matching)

    func testJaroDistanceIdenticalStrings() {
        XCTAssertEqual(Utils.jaroDistance("RABAT", "RABAT"), 1.0, accuracy: 1e-9)
    }

    func testJaroDistanceEmptyStrings() {
        XCTAssertEqual(Utils.jaroDistance("", "RABAT"), 0.0)
        XCTAssertEqual(Utils.jaroDistance("RABAT", ""), 0.0)
        XCTAssertEqual(Utils.jaroDistance("", ""), 0.0)
    }

    func testJaroDistanceNoCommonCharacters() {
        XCTAssertEqual(Utils.jaroDistance("ABC", "XYZ"), 0.0)
    }

    func testJaroDistanceKnownReferenceValues() {
        // Classic reference values for the Jaro similarity.
        XCTAssertEqual(Utils.jaroDistance("MARTHA", "MARHTA"), 0.9444, accuracy: 0.0001)
        XCTAssertEqual(Utils.jaroDistance("DWAYNE", "DUANE"), 0.8222, accuracy: 0.0001)
    }

    func testJaroDistanceIsSymmetricAndBounded() {
        let pairs = [("CASABLANCA", "CASABLANKA"), ("RUE 12 AVENUE", "AVENUE 12 RUE"), ("A", "B")]
        for (a, b) in pairs {
            let d1 = Utils.jaroDistance(a, b)
            let d2 = Utils.jaroDistance(b, a)
            XCTAssertEqual(d1, d2, accuracy: 1e-9, "\(a)/\(b)")
            XCTAssertTrue((0.0...1.0).contains(d1), "\(a)/\(b)")
        }
    }

    func testJaroWinklerReturnsPercentageAndLongerString() {
        let same = Utils.jaroWinkler("RABAT", "RABAT")
        XCTAssertEqual(same.percentage, 100)
        XCTAssertEqual(same.adress, "RABAT")

        let different = Utils.jaroWinkler("CASA", "CASABLANCA")
        XCTAssertEqual(different.adress, "CASABLANCA")
        XCTAssertTrue((1...99).contains(different.percentage))

        XCTAssertEqual(Utils.jaroWinkler("ABC", "XYZ").percentage, 0)
    }
}
