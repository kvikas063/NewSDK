import MLKitTextRecognition
import UIKit

// MARK: - DrawingView

/// Overlay view that parses the ML Kit text recognised on the **front of the old Moroccan CIN**
/// (the video-based scan flow in `MainVideoViewController`).
///
/// Every time `visionText` is set the view redraws, and `draw(_:)` walks over the recognised text
/// blocks and extracts the CIN number, the address, the parents' names and the sex. Nothing is
/// actually painted: the view only clears its context and updates the `resulat*` flags and the
/// `UserSession` fields, which the owning view controller polls.
///
/// Original name: `DrawingView` (obfuscated by SwiftShield).
class lU2YDSwONUtfxobLtCD8q5d8c31YE09r: UIView {

    // MARK: Inputs

    /// The size of the image the text was recognised in. Written by the view controller; not read here.
    public var imageSize: CGSize = .zero

    /// The latest ML Kit recognition result. Setting it triggers a redraw, which re-runs the extraction.
    public var visionText: Text? {
        didSet {
            setNeedsDisplay()
        }
    }

    // MARK: Extraction state

    /// The first block seen that contains the "Adresse" label. Later address blocks are compared with
    /// it (Jaro-Winkler) to confirm a stable read before the address is accepted.
    var adresseChecking = String()

    /// Previous reading of the father's name (the `ben` line); a value must be read twice in a row
    /// to be accepted.
    var joinedArrayDoubleChecking = String()

    /// Previous reading of the mother's name (the `bent` line); a value must be read twice in a row
    /// to be accepted.
    var joinedArrayDoubleChecking2 = String()

    /// Regular expression that identifies the address block (the "Adresse" label).
    let pattern = "(Adresse)"

    /// Regular expression that identifies the sex block (the "Sexe" label).
    let patternSex = "(Sexe)"

    /// The lines of the block currently being analysed as a parents ("Fils de / Fille de") block.
    var linesName = [TextLine]()

    // MARK: Result flags

    /// `true` once a block holding a valid CIN number has been seen.
    public var resulatCin: Bool = false

    /// `true` once the address has been read consistently twice (see `extractedAdress(_:_:)`).
    /// The view controller resets it to `false` after consuming it.
    public var resulat: Bool = false

    /// `true` once the sex ("M" or "F") has been read next to the "Sexe" label.
    public var resulatSex: Bool = false

    /// `true` once the father's name has been read consistently twice.
    public var resulatSonOF: Bool = false

    /// `true` once the mother's name has been read consistently twice.
    public var resulatSonOF2: Bool = false

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

    // MARK: - Drawing

    /// Redraws the view by clearing it and re-running the text extraction.
    ///
    /// - Parameter rect: The area of the view that needs to be redrawn.
    override func draw(_ rect: CGRect) {
        startExtractFrom(rect)
    }

    // MARK: - Text extraction

    /// Clears the context and runs every extractor over each recognised block of `visionText`.
    ///
    /// For each block it: flags `resulatCin` if the block text is a valid CIN number
    /// (`Utils.isValidCIN`), then calls `extractedAdress(_:_:)`, `extractedParentFullName(_:)` and
    /// `extractedGender(_:_:_:_:)`.
    ///
    /// - Parameter rect: The area to clear before extracting.
    func startExtractFrom(_ rect: CGRect) {

        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        ctx.clear(rect)

        guard let visionText = visionText else { return }

        let blocks: [TextBlock] = visionText.blocks

        var i = -1

        for block in blocks {
            i += 1
            if Utils.isValidCIN(testStr: block.text) {
                self.resulatCin = true
            }

            extractedAdress(block, pattern)

            extractedParentFullName(block)

            extractedGender(block, patternSex, blocks, i)
        }
    }

    /// Extracts the sex ("M" or "F") from the text blocks around the "Sexe" label.
    ///
    /// When `block` contains the "Sexe" label, the block right after it and the block right before it
    /// are inspected: if either has the exact text "M" or "F", that value is stored in
    /// `UserSession.sexe` and `resulatSex` is set.
    ///
    /// - Parameters:
    ///   - block: The block currently being analysed.
    ///   - patternSex: The regular expression that identifies the "Sexe" label.
    ///   - blocks: All the blocks of the recognition result, in recognition order.
    ///   - i: The index of `block` in `blocks`.
    func extractedGender(_ block: TextBlock, _ patternSex: String, _ blocks: [TextBlock], _ i: Int) {
        if (block.text.range(of: patternSex, options: .regularExpression)) != nil {
            if blocks.count > i + 1 && (blocks[i + 1].text == "M" || blocks[i + 1].text == "F") {
                fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.sexe = blocks[i + 1].text
                self.resulatSex = true
            }
            if i > 0 && (blocks[i - 1].text == "M" || blocks[i - 1].text == "F") {
                fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.sexe = blocks[i - 1].text
                self.resulatSex = true
            }
        }
    }

    /// Extracts the father's and mother's names from a "Fils de ... ben ... / ... bent ..." block.
    ///
    /// The block is considered when it matches `String.genderOfParent()` (a word starting with "F" and
    /// ending in "e" or "s", i.e. "Fils"/"Fille"). It must have exactly two lines, the first one also
    /// matching that expression. The first line is searched with `String.son("ben")` (father's name,
    /// "<NAME> ben <NAME>") and the second with `String.son("bent")` (mother's name). A name is only
    /// accepted (`UserSession.namePar` / `UserSession.nameMere`, and `resulatSonOF` /
    /// `resulatSonOF2`) when the same non-empty reading is obtained twice in a row; otherwise the
    /// reading is remembered for the next frame. If neither line yields a name, both flags are reset.
    ///
    /// - Parameter block: The block currently being analysed.
    func extractedParentFullName(_ block: TextBlock) {
        if (block.text.range(of: "".genderOfParent(), options: .regularExpression)) != nil {
            linesName = block.lines
            if linesName.count == 2 {
                if (linesName[0].text.range(of: "".genderOfParent(), options: .regularExpression)) != nil {
                    let res = String(linesName[0].text)
                    let res2 = String(linesName[1].text)
                    let extractBen = res.matches(for: "".son("ben"))
                    let extractBent = res2.matches(for: "".son("bent"))
                    let joinedArray = extractBen.joined(separator: " ")
                    let joinedArray2 = extractBent.joined(separator: " ")
                    if joinedArray.isEmpty && joinedArray2.isEmpty {
                        self.resulatSonOF = false
                        self.resulatSonOF2 = false
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
    }

    /// Extracts the address from the block that contains the "Adresse" label.
    ///
    /// The first matching block is only remembered in `adresseChecking`. Every later matching block is
    /// compared with it using `Utils.jaroWinkler`; when the similarity reaches `matchingPourcentage`
    /// the longer of the two texts is stored in `UserSession.adresse` (with the "Adresse" label removed
    /// and whitespace trimmed) and `resulat` is set.
    ///
    /// - Parameters:
    ///   - block: The block currently being analysed.
    ///   - pattern: The regular expression that identifies the address block.
    func extractedAdress(_ block: TextBlock, _ pattern: String) {
        if (block.text.range(of: pattern, options: .regularExpression)) != nil {
            if !adresseChecking.isEmpty {
                let adressDict = Utils.jaroWinkler(block.text, adresseChecking)
                if adressDict.percentage >= self.matchingPourcentage {
                    self.resulat = true
                    fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.tzZbByoiDZnS0RIf8lI8Fjir2KSvDlNt = adressDict.adress
                        .replacingOccurrences(of: pattern, with: "", options: .regularExpression).trim()
                }
            } else {
                adresseChecking = block.text
            }
        }
    }
}
