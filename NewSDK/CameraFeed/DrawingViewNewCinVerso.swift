import MLKitTextRecognition
import UIKit

// MARK: - DrawingViewNewCinVerso

/// Overlay view that parses the ML Kit text recognised on the **back (verso) of the new Moroccan CIN**
/// (used by `ViewControllerNewCinVerso`).
///
/// Every time `visionText` is set the view redraws, and `draw(_:)` walks over the recognised text
/// blocks and extracts the address, the father's and mother's names and the sex. Nothing is actually
/// painted: the view only clears its context and updates the `resulat*` flags and the `UserSession`
/// fields, which the owning view controller polls.
class DrawingViewNewCinVerso: UIView {

    // MARK: Inputs

    /// The size of the image the text was recognised in. Written by the view controller; not read here.
    public var imageSize: CGSize = .zero

    /// The latest ML Kit recognition result. Setting it triggers a redraw, which re-runs the extraction.
    public var visionText: Text? {
        didSet {
            setNeedsDisplay()
        }
    }

    // MARK: Result flags

    /// `true` once the address has been read consistently twice (see `draw(_:)`).
    /// The view controller resets it to `false` after consuming it.
    public var resulat: Bool = false

    /// `true` once the father's name has been read consistently twice.
    public var resulatSonOF: Bool = false

    /// `true` once the mother's name has been read consistently twice.
    public var resulatSonOF2: Bool = false

    // MARK: Extraction state

    /// The lines of the block currently being analysed as a parents ("Fils de / Fille de") block.
    var linesName = [TextLine]()

    /// Previous reading of the father's name (the `ben` line); a value must be read twice in a row
    /// to be accepted.
    var joinedArrayDoubleChecking = String()

    /// Previous reading of the mother's name (the `bent` line); a value must be read twice in a row
    /// to be accepted.
    var joinedArrayDoubleChecking2 = String()

    /// The first address line seen. Later address lines are compared with it (Jaro-Winkler) to confirm
    /// a stable read before the address is accepted.
    var joinedArrayDoubleChecking3 = ""

    // MARK: Matching threshold

    /// The minimum Jaro-Winkler similarity (in percent) between two address readings for the address
    /// to be accepted: 75 on the iPhone 6 and 7, 95 on every other device.
    var matchingPourcentage: Int {
        var pourcentage: Int
        switch UIDevice.modelName {
        case .iphone6, .iphone7:
            pourcentage = 75
        default:
            pourcentage = 95
        }
        return pourcentage
    }

    // MARK: - Drawing and text extraction

    /// Clears the view and extracts the address, parents' names and sex from `visionText`.
    ///
    /// Nothing is painted. For every recognised block:
    ///
    /// - **Address**: the block must contain "Adresse" but not the "IDMAR" marker (`I\s*DMAR`, the
    ///   machine-readable zone) and no "<". The line containing "Adresse" is remembered the first
    ///   time; on later frames it is compared with the remembered line (`Utils.jaroWinkler`) and, when
    ///   the similarity reaches `matchingPourcentage`, the longer text is stored in
    ///   `UserSession.adresse` (everything after "Adresse" and the following character, trimmed) and
    ///   `resulat` is set.
    /// - **Parents (`Fils de ...`)**: the block must contain a word `F...s` (e.g. "Fils") and have
    ///   exactly two lines, the first one matching too. Names are read with an upper-case-name regex
    ///   with a `ben` (son of) separator on the first line and `bent` (daughter of) on the second.
    ///   A name is only accepted (`UserSession.namePar` / `UserSession.nameMere`, `resulatSonOF` /
    ///   `resulatSonOF2`) when the same reading is obtained twice in a row. In this variant an empty
    ///   reading is not excluded from the comparison, and only `resulatSonOF2` is reset when both
    ///   readings are empty.
    /// - **Parents (`Fille de ...`)**: same as above for a word `F...e`, with the additional rule that
    ///   an empty reading is never accepted and both flags are reset when both readings are empty.
    /// - **Sex**: a block containing "Sexe" followed by a whitespace and "M" or "F" sets
    ///   `UserSession.sexe` to that letter.
    ///
    /// - Parameter rect: The area to clear before extracting.
    override func draw(_ rect: CGRect) {

        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.clear(rect)
        guard let visionText = visionText else { return }
        let blocks: [TextBlock] = visionText.blocks

        for block in blocks {

            let pattern = "(Adresse)"
            let pattern2 = "(I\\s*DMAR)"
            let patternSex = "(Sexe)"

            if ((block.text.range(of: pattern, options: .regularExpression)) != nil)
                && ((block.text.range(of: pattern2, options: .regularExpression)) == nil) && !block.text.contains("<")
            {

                let addressLine = block.lines.filter {
                    (($0.text.range(of: pattern, options: .regularExpression)) != nil)
                }.first

                if let address = addressLine?.text {

                    if !joinedArrayDoubleChecking3.isEmpty {
                        let adressDict = Utils.jaroWinkler(address, joinedArrayDoubleChecking3)

                        if adressDict.percentage >= self.matchingPourcentage {
                            self.resulat = true
                            if let adresseRange = adressDict.adress.range(of: "Adresse"),
                                adresseRange.upperBound < adressDict.adress.endIndex,
                                adressDict.adress.index(after: adresseRange.upperBound) != adressDict.adress.endIndex
                            {
                                let adresse = String(
                                    adressDict.adress[
                                        adressDict.adress.index(
                                            after: adresseRange.upperBound)..<adressDict.adress.endIndex])
                                fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.tzZbByoiDZnS0RIf8lI8Fjir2KSvDlNt = adresse.trim()
                            } else {
                                fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.tzZbByoiDZnS0RIf8lI8Fjir2KSvDlNt = adressDict.adress
                                    .trim()
                            }

                        }
                    } else {
                        joinedArrayDoubleChecking3 = address
                    }
                }

            }

            if ((block.text.range(of: "(\\bF[A-Za-z]+s\\b)|(\\bf[A-Za-z]+s\\b)", options: .regularExpression)) != nil) {
                linesName = block.lines
                if linesName.count == 2 {
                    if (linesName[0].text.range(
                        of: "(\\bF[A-Za-z]+s\\b)|(\\bf[A-Za-z]+s\\b)", options: .regularExpression)) != nil
                    {
                        let res = String(linesName[0].text)
                        let res2 = String(linesName[1].text)
                        let extractBent = res2.matches(
                            for:
                                "(([A-Z]{2,}[\\s|-]{1,2})*[A-Z]{3,})[\\s|-]{1,2}bent[\\s|-]{1,2}(([A-Z]{2,}[\\s|-]{1,2})*[A-Z]{3,})|(([A-Z]{2,}[\\s|-]{1,2})*[A-Z]{3,})"
                        )
                        let extractBen = res.matches(
                            for:
                                "(([A-Z]{2,}[\\s|-]{1,2})*[A-Z]{3,})[\\s|-]{1,2}ben[\\s|-]{1,2}(([A-Z]{2,}[\\s|-]{1,2})*[A-Z]{3,})|(([A-Z]{2,}[\\s|-]{1,2})*[A-Z]{3,})"
                        )
                        let joinedArray = extractBen.joined(separator: " ")
                        let joinedArray2 = extractBent.joined(separator: " ")
                        if joinedArray.isEmpty && joinedArray2.isEmpty {
                            self.resulatSonOF2 = false
                        } else {

                            if self.joinedArrayDoubleChecking == joinedArray {
                                fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.namePar = joinedArray
                                self.resulatSonOF = true
                            } else {
                                self.joinedArrayDoubleChecking = joinedArray
                            }

                            if self.joinedArrayDoubleChecking2 == joinedArray2 {
                                fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.nameMere = joinedArray2
                                self.resulatSonOF2 = true
                            } else {
                                self.joinedArrayDoubleChecking2 = joinedArray2
                            }
                        }
                    }
                }
            }

            if ((block.text.range(of: "(\\bF[A-Za-z]+e\\b)|(\\bf[A-Za-z]+e\\b)", options: .regularExpression)) != nil) {
                linesName = block.lines
                if linesName.count == 2 {
                    if (linesName[0].text.range(
                        of: "(\\bF[A-Za-z]+e\\b)|(\\bf[A-Za-z]+e\\b)", options: .regularExpression)) != nil
                    {
                        let res = String(linesName[0].text)
                        let res2 = String(linesName[1].text)
                        let extractBent = res2.matches(
                            for:
                                "(([A-Z]{2,}[\\s|-]{1,2})*[A-Z]{3,})[\\s|-]{1,2}bent[\\s|-]{1,2}(([A-Z]{2,}[\\s|-]{1,2})*[A-Z]{3,})|(([A-Z]{2,}[\\s|-]{1,2})*[A-Z]{3,})"
                        )
                        let extractBen = res.matches(
                            for:
                                "(([A-Z]{2,}[\\s|-]{1,2})*[A-Z]{3,})[\\s|-]{1,2}ben[\\s|-]{1,2}(([A-Z]{2,}[\\s|-]{1,2})*[A-Z]{3,})|(([A-Z]{2,}[\\s|-]{1,2})*[A-Z]{3,})"
                        )
                        let joinedArray = extractBen.joined(separator: " ")
                        let joinedArray2 = extractBent.joined(separator: " ")

                        if joinedArray.isEmpty && joinedArray2.isEmpty {
                            self.resulatSonOF2 = false
                            self.resulatSonOF = false
                        } else {
                            if !joinedArray.isEmpty && self.joinedArrayDoubleChecking == joinedArray {
                                fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.namePar = joinedArray
                                self.resulatSonOF = true
                            } else {
                                self.joinedArrayDoubleChecking = joinedArray
                            }

                            if !joinedArray2.isEmpty && self.joinedArrayDoubleChecking2 == joinedArray2 {
                                fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.nameMere = joinedArray2
                                self.resulatSonOF2 = true
                            } else {
                                self.joinedArrayDoubleChecking2 = joinedArray2
                            }
                        }
                    }
                }
            }

            if (block.text.range(of: patternSex, options: .regularExpression)) != nil {

                if block.text.range(of: "(Sexe\\sM)", options: .regularExpression) != nil {
                    fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.sexe = "M"
                }

                if block.text.range(of: "(Sexe\\sF)", options: .regularExpression) != nil {
                    fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.sexe = "F"
                }

            }

        }
    }
}
