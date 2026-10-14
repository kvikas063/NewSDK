// Copyright 2019 The TensorFlow Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit

// MARK: - Text helpers and CIN regular expressions

extension String {

    /// Measures the size the string occupies when drawn with a font (original name: `size(usingFont:)`).
    ///
    /// - Parameter font: The font used to render the string.
    /// - Returns: The size of the string drawn on a single line with `font`.
    func bAi0mr4qmad0BtC0hjiYpW0uphIxqS7n(usingFont font: UIFont) -> CGSize {
        let attributedString = NSAttributedString(string: self, attributes: [NSAttributedString.Key.font: font])
        return attributedString.size()
    }

    /// The string with leading and trailing spaces and tabs removed (newlines are kept).
    func trim() -> String {
        trimmingCharacters(in: .whitespaces)
    }

    /// Finds every substring that matches a regular expression.
    ///
    /// An invalid pattern is reported with a `print` and yields an empty result.
    ///
    /// - Parameter regex: The regular expression pattern to search for.
    /// - Returns: The matching substrings in order of appearance, or an empty array if there is no match or the
    ///   pattern is invalid.
    func matches(for regex: String) -> [String] {

        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(
                in: self,
                range: NSRange(startIndex..., in: self))
            return results.map {
                String(self[Range($0.range, in: self)!])
            }
        } catch {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }

    /// Whether the whole string looks like a person's name: upper-case words (letters and apostrophes)
    /// of at least two letters separated by spaces, dots or dashes, or a single upper-case word of at
    /// least three letters.
    var isValidName: Bool {

        let nameRegEx =
            "(([A-Z']{2,}[\\s|.-]{1,2}([A-Z']{2,}([\\s|.-]{1,2}[A-Z']{2,})*([\\s|.-]{1,2}[A-Z']{2,})*([\\s|.-]{1,2}[A-Z']{2,})*))|([A-Z']{3,}))"

        let nameTest = NSPredicate(format: "SELF MATCHES %@", nameRegEx)

        return nameTest.evaluate(with: self)

    }

    /// Regular expression matching the French word for the parent line on the card ("Fils", "Fille",
    /// "Filles"... i.e. words starting with `F` or `f` and ending in `e` or `s`).
    ///
    /// The receiver is ignored; call it on an empty string (`"".genderOfParent()`).
    ///
    /// - Returns: The regular expression pattern.
    func genderOfParent() -> String {
        "(\\bF[A-Za-z]+[es]\\b)|(\\bf[A-Za-z]+[es]\\b)"
    }

    /// Regular expression matching "`<NAME> <of> <NAME>`" (a person's name, a connecting word, then a parent's
    /// name) or, as a fallback alternative, a bare upper-case name.
    ///
    /// The receiver is ignored; call it on an empty string (`"".son("ben")`).
    ///
    /// - Parameter of: The connecting word between the two names (for example `"ben"` or `"bent"`).
    /// - Returns: The regular expression pattern.
    func son(_ of: String) -> String {
        "(([A-Z]{2,}[\\s|-]{1,2})*[A-Z]{3,})[\\s|-]{1,2}\(of)[\\s|-]{1,2}(([A-Z]{2,}[\\s|-]{1,2})*[A-Z]{3,})|(([A-Z]{2,}[\\s|-]{1,2})*[A-Z]{3,})"
    }
}

// MARK: - Localization

extension String {
    /// Localized version of an SDK message.
    ///
    /// The receiver is a short key such as `"common.cancel"` (`<group>.<name>`); the translations live in
    /// `NewSDKLocalizable.strings` (fr / en) in the SDK's resource bundle. Falls back to the key itself when the
    /// key is missing from the table.
    var sdkLocalized: String {
        NSLocalizedString(self, tableName: "NewSDKLocalizable", bundle: .sdk, value: self, comment: "")
    }
}
