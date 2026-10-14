import Foundation

/// Validation helpers for the text recognised on a CIN card, plus string-similarity functions.
public class Utils {

    private init() {}

    /// Converts an integer to its decimal string representation.
    ///
    /// - Parameter value: The integer to convert.
    /// - Returns: `String(value)`.
    public static func intToString(value: Int) -> String {
        String(value)
    }

    /// Checks whether a string is a CIN number: one or two upper-case letters followed by four to six digits.
    ///
    /// - Parameter testStr: The text to test (the whole string must match).
    /// - Returns: `true` if the text has the CIN format.
    public static func isValidCIN(testStr: String) -> Bool {
        let cinRegEx = "[A-Z]{1,2}[0-9]{4,6}"

        let cinTest = NSPredicate(format: "SELF MATCHES %@", cinRegEx)
        return cinTest.evaluate(with: testStr)
    }

    /// Checks whether a string is a date written as `dd.MM.yyyy` or a bare four-digit year.
    ///
    /// - Parameter testStr: The text to test (the whole string must match).
    /// - Returns: `true` if the text has one of those two formats.
    public static func isValidDate(testStr: String) -> Bool {
        let cinRegEx = "([0-9]{2}[.][0-9]{2}[.][0-9]{4})|([0-9]{4})"

        let cinTest = NSPredicate(format: "SELF MATCHES %@", cinRegEx)
        return cinTest.evaluate(with: testStr)
    }

    /// Checks whether a string is a name made of upper-case words (letters and apostrophes) of at least two
    /// letters separated by spaces or dashes, or a single upper-case word of at least three letters.
    ///
    /// Unlike `String.isValidName`, dots are not accepted as separators.
    ///
    /// - Parameter testStr: The text to test (the whole string must match).
    /// - Returns: `true` if the text looks like a name.
    public static func isValidName(testStr: String) -> Bool {
        let cinRegEx = "([A-Z']{2,}[\\s|-]{1,2}+([A-Z']{2,}([\\s|-]{1,2}+[A-Z']{2,})*))|([A-Z']{3,})"

        let cinTest = NSPredicate(format: "SELF MATCHES %@", cinRegEx)
        return cinTest.evaluate(with: testStr)
    }

    /// Checks whether a string has the shape of the birth-date line on the card: seven digits followed by one
    /// upper-case letter.
    ///
    /// - Parameter testStr: The text to test (the whole string must match).
    /// - Returns: `true` if the text has that format.
    public static func isValidDateNaissance(testStr: String) -> Bool {
        let cinRegEx = "([0-9]{7}[A-Z]{1})"

        let cinTest = NSPredicate(format: "SELF MATCHES %@", cinRegEx)
        return cinTest.evaluate(with: testStr)
    }

    /// Checks whether a string contains an expiry-date phrase: a word of at least three letters, a whitespace
    /// character, then a `dd.MM.yyyy` date.
    ///
    /// - Parameter testStr: The text to search.
    /// - Returns: `true` if the text contains such a phrase anywhere.
    public static func isValidDateExpiration(testStr: String) -> Bool {
        let cinRegEx = "([A-Z,a-z]{3,}[\\s][0-9]{2}[.][0-9]{2}[.][0-9]{4})"

        // The text only has to *contain* a match, so search with a regex instead of a literal CONTAINS.
        return testStr.range(of: cinRegEx, options: .regularExpression) != nil
    }

}

// MARK: - Address similarity

/// Result of comparing two address strings: the similarity score (0-100) and the longer of the two strings.
typealias isValidAdress = (percentage: Int, adress: String)

extension Utils {
    /// Computes the Jaro similarity of two strings.
    ///
    /// - Parameters:
    ///   - s1: The first string.
    ///   - s2: The second string.
    /// - Returns: A score from `0.0` (nothing in common, or either string is empty) to `1.0` (identical).
    public static func jaroDistance(_ s1: String, _ s2: String) -> Double {

        // Length of two strings
        let len1 = s1.count,
            len2 = s2.count
        //
        if len1 == 0 || len2 == 0 {
            return 0.0
        }

        // Maximum distance upto which matching
        // is allowed
        let maxDist = max(len1, len2) / 2 - 1

        // Count of matches
        var match = 0

        // Hash for matches
        var hashS1: [Int] = Array(repeating: 0, count: s1.count)
        var hashS2: [Int] = Array(repeating: 0, count: s2.count)

        let s2Array = Array(s2)
        // Traverse through the first string
        for (i, ch1) in s1.enumerated() {

            // Check if there is any matches
            if max(0, i - maxDist) > min(len2 - 1, i + maxDist) {
                continue
            }
            for j in max(0, i - maxDist)...min(len2 - 1, i + maxDist) {

                // If there is a match
                if ch1 == s2Array[j] && hashS2[j] == 0 {
                    hashS1[i] = 1
                    hashS2[j] = 1
                    match += 1
                    break
                }
            }
        }

        // If there is no match
        if match == 0 {
            return 0.0
        }

        // Number of transpositions
        var t: Double = 0

        var point = 0

        // Count number of occurances
        // where two characters match but
        // there is a third matched character
        // in between the indices
        for (i, ch1) in s1.enumerated() {
            if hashS1[i] == 1 {

                // Find the next matched character
                // in second string
                while hashS2[point] == 0 {
                    point += 1
                }

                if ch1 != s2Array[point] {
                    t += 1
                }
                point += 1
            }
        }
        t /= 2

        // Return the Jaro
        return
            (Double(match) / Double(len1)
            + Double(match) / Double(len2)
            + (Double(match) - t) / Double(match))
            / 3.0
    }

    /// Compares two address strings using `jaroDistance(_:_:)`.
    ///
    /// Despite its name, no Winkler prefix boost is applied: the score is the plain Jaro distance.
    ///
    /// - Parameters:
    ///   - s1: The first address.
    ///   - s2: The second address.
    /// - Returns: The similarity as an integer percentage (the Jaro distance times 100, truncated) and the
    ///   longer of the two strings (`s1` when their lengths are equal).
    static func jaroWinkler(_ s1: String, _ s2: String) -> isValidAdress {
        let jaroDist = Utils.jaroDistance(s1, s2)
        return (Int(jaroDist * 100), s1.count >= s2.count ? s1 : s2)
    }
}
