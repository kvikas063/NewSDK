import MLKitTextRecognition
import UIKit

// MARK: - DrawingViewNewCin

/// Overlay view that parses the ML Kit text recognised on the **front of the new Moroccan CIN**
/// (used by `ViewControllerNewCin`).
///
/// Every time `visionText` is set the view redraws, and `draw(_:)` filters the recognised blocks and
/// extracts the first name, last name, birth date, expiry date, place of birth and CIN number into
/// `myArrayFinal`. Nothing is actually painted: the view only clears its context and updates the
/// `resulat*` flags and `UserSession`, which the owning view controller polls.
class DrawingViewNewCin: UIView {

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

    /// `true` once a CIN number has been found followed by a block holding a dated line
    /// (`<word> dd.mm.yyyy`), i.e. the expiry date has been read.
    public var resulatCin: Bool = false

    /// `true` once a birth date has been found followed by a valid block for the place of birth.
    /// The view controller resets it to `false` after consuming it.
    public var resulat: Bool = false

    /// `true` once a valid last name has been read (two blocks after the card title).
    public var resulatNom: Bool = false

    /// `true` once a valid first name has been read (the block right after the card title).
    public var resulatPrenom: Bool = false

    // MARK: Extraction state

    /// The extracted fields, by index: `0` first name, `1` last name, `2` birth date, `3` expiry date,
    /// `4` place of birth, `5` CIN number. An empty string means "not read yet".
    var myArrayFinal = ["", "", "", "", "", ""]

    // MARK: Card title patterns

    /// Matches the full card title "CARTE NATIONALE D'IDENTITE".
    let pattern = "(CARTE NATIONALE D'IDENTITE)"

    /// Matches the card title fragment "NATIONALE D'IDENTITE".
    let pattern2 = "(NATIONALE D'IDENTITE)"

    /// Matches the card title fragment "NATIONALE".
    let pattern3 = "(NATIONALE)"

    /// Matches the card title fragment "D'IDENTITE".
    let pattern4 = "(D'IDENTITE)"

    // MARK: - Drawing

    /// Redraws the view by clearing it and re-running the text extraction.
    ///
    /// - Parameter rect: The area of the view that needs to be redrawn.
    override func draw(_ rect: CGRect) {
        startExtractingFrom(rect)
    }
}

// MARK: - Extract ID info

extension DrawingViewNewCin {

    /// Clears the context, filters the recognised blocks and runs the extractors over each of them.
    ///
    /// Only blocks that are entirely upper case, or that contain "é", "à" or an apostrophe, are kept.
    /// For each remaining block the full name, the date and the CIN number extractors run in turn;
    /// as soon as all six entries of `myArrayFinal` are filled, the array is published to
    /// `UserSession.tokenAccess`.
    ///
    /// - Parameter rect: The area to clear before extracting.
    func startExtractingFrom(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.clear(rect)
        guard let visionText = visionText else { return }
        var blocks: [TextBlock] = visionText.blocks

        blocks = blocks.filter {
            ($0.text.contains("é")) || ($0.text.contains("à")) || ($0.text.contains("'"))
                || ($0.text.uppercased() == $0.text)

        }

        var i = -1
        for block in blocks {
            i += 1

            extractedFullName(block, blocks, i)

            extractedDate(block, blocks, i)

            extractedID(block, blocks, i)

            if !myArrayFinal.contains("") {
                fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.Gv6iuNfQoFK2P4Pd3tdqXjDS25hJGyRR = myArrayFinal
            }
        }
    }

    /// Extracts the first and last name from the two blocks that follow the card title.
    ///
    /// When `block` matches one of the card title patterns (`pattern`...`pattern4`),
    /// `UserSession.isValidCin` is set. The next block is then taken as the first name
    /// (`myArrayFinal[0]`, `resulatPrenom`) and the one after it as the last name (`myArrayFinal[1]`,
    /// `resulatNom`), provided each is upper case and is a valid name (`String.isValidName`).
    ///
    /// - Parameters:
    ///   - block: The block currently being analysed.
    ///   - blocks: The filtered blocks of the recognition result, in recognition order.
    ///   - i: The index of `block` in `blocks`.
    func extractedFullName(_ block: TextBlock, _ blocks: [TextBlock], _ i: Int) {
        if (block.text.range(of: pattern, options: .regularExpression)) != nil
            || (block.text.range(of: pattern2, options: .regularExpression)) != nil
            || (block.text.range(of: pattern3, options: .regularExpression)) != nil
            || (block.text.range(of: pattern4, options: .regularExpression)) != nil
        {

            fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.isValidCin = true

            if blocks.count > i + 1 && blocks[i + 1].text.uppercased() == blocks[i + 1].text
                && blocks[i + 1].text.isValidName
            {
                self.resulatPrenom = true
                self.myArrayFinal[0] = blocks[i + 1].text
            }

            if blocks.count > i + 2 && blocks[i + 2].text.uppercased() == blocks[i + 2].text
                && blocks[i + 2].text.isValidName
            {
                self.resulatNom = true
                self.myArrayFinal[1] = blocks[i + 2].text
            }
        }
    }

    /// Extracts the birth date and the place of birth.
    ///
    /// When `block` is a valid date (`Utils.isValidDate`: `dd.mm.yyyy` or a four digit year) it is
    /// stored as the birth date (`myArrayFinal[2]`). If the next block is upper case and a valid name
    /// (`Utils.isValidName`) it is stored as the place of birth (`myArrayFinal[4]`) and `resulat` is set.
    ///
    /// - Parameters:
    ///   - block: The block currently being analysed.
    ///   - blocks: The filtered blocks of the recognition result, in recognition order.
    ///   - i: The index of `block` in `blocks`.
    func extractedDate(_ block: TextBlock, _ blocks: [TextBlock], _ i: Int) {
        if Utils.isValidDate(testStr: block.text) {
            self.myArrayFinal[2] = block.text
            if blocks.count > i + 1 && blocks[i + 1].text.uppercased() == blocks[i + 1].text
                && Utils.isValidName(testStr: blocks[i + 1].text)
            {
                self.myArrayFinal[4] = blocks[i + 1].text
                self.resulat = true
            }
        }
    }

    /// Extracts the CIN number and the expiry date.
    ///
    /// When `block` is a valid CIN number (`Utils.isValidCIN`: one or two letters followed by four to
    /// six digits) it is stored in `myArrayFinal[5]`. If the next block looks like
    /// `<word of 3+ letters> dd.mm.yyyy`, the `dd.mm.yyyy` part is stored as the expiry date
    /// (`myArrayFinal[3]`) and `resulatCin` is set.
    ///
    /// - Parameters:
    ///   - block: The block currently being analysed.
    ///   - blocks: The filtered blocks of the recognition result, in recognition order.
    ///   - i: The index of `block` in `blocks`.
    func extractedID(_ block: TextBlock, _ blocks: [TextBlock], _ i: Int) {
        if Utils.isValidCIN(testStr: block.text) {
            self.myArrayFinal[5] = block.text
            if blocks.count > i + 1 {
                if blocks[i + 1].text.range(
                    of: "[A-Z,a-z,ư,',Ư]{3,}[\\s][0-9]{2}[.][0-9]{2}[.][0-9]{4}", options: .regularExpression) != nil
                {
                    let matched = blocks[i + 1].text.matches(for: "[0-9]{2}[.][0-9]{2}[.][0-9]{4}")
                    self.myArrayFinal[3] = matched[0]
                    self.resulatCin = true
                }
            }
        }
    }
}
