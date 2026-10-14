import UIKit
import XCTest

@testable import NewSDK

/// Tests for how `KycResultViewModel.prepareCinInfo()` maps the scan session onto result fields for old and new CIN cards.
final class KycResultViewModelTests: XCTestCase {

    private typealias Session = fKrUHvHJknyK3g7L2vSipDnasRUh8RKV

    // [firstName, lastName, birthDate, <old: birthCity | new: expiry>, <old: expiry | new: birthCity>, cin]
    private let tokens = ["Ahmed", "ALAMI", "01.01.1990", "Rabat", "02.02.2030", "AB123456"]

    override func setUp() {
        super.setUp()
        Session.Gv6iuNfQoFK2P4Pd3tdqXjDS25hJGyRR = tokens
        Session.tzZbByoiDZnS0RIf8lI8Fjir2KSvDlNt = "12 Rue X, Rabat"
        Session.sexe = "M"
        Session.nameMere = "FATIMA"
        Session.namePar = "OMAR"
        Session.ky1ePKYSfStWWtkoyn7UgCesivPB3BvT = UIImage(systemName: "star")!
        Session.yy3ZfLPAkInlRLrv0BbNDQ4fhrwgciEd = UIImage(systemName: "heart")!
    }

    func testPrepareCinInfoForOldCin() {
        Session.cinType = .oldCin
        let result = KycResultViewModel()
        result.prepareCinInfo()

        XCTAssertEqual(result.firstName, "Ahmed")
        XCTAssertEqual(result.lastName, "ALAMI")
        XCTAssertEqual(result.birthDate, "01.01.1990")
        XCTAssertEqual(result.birthCity, "Rabat")
        XCTAssertEqual(result.dateExpire, "02.02.2030")
        XCTAssertEqual(result.cin, "AB123456")
        XCTAssertEqual(result.adress, "12 Rue X, Rabat")
        XCTAssertEqual(result.gender, "M")
        XCTAssertEqual(result.motherName, "FATIMA")
        XCTAssertEqual(result.fatherName, "OMAR")
        XCTAssertNotNil(result.rectoImage)
        XCTAssertNotNil(result.versoImage)
    }

    func testPrepareCinInfoForNewCinSwapsExpiryAndBirthCity() {
        Session.cinType = .newCin
        let result = KycResultViewModel()
        result.prepareCinInfo()

        XCTAssertEqual(result.dateExpire, "Rabat")  // index 3 on new CIN
        XCTAssertEqual(result.birthCity, "02.02.2030")  // index 4 on new CIN
        XCTAssertEqual(result.cin, "AB123456")
    }

    func testResultIsEmptyBeforePrepare() {
        let result = KycResultViewModel()
        XCTAssertNil(result.cin)
        XCTAssertNil(result.firstName)
        XCTAssertNil(result.rectoImage)
    }

    func testPrepareCinInfoWithEmptyInitialTokens() {
        // The scan screens seed the tokens with six empty strings; this must not crash.
        Session.Gv6iuNfQoFK2P4Pd3tdqXjDS25hJGyRR = ["", "", "", "", "", ""]
        let result = KycResultViewModel()
        result.prepareCinInfo()
        XCTAssertEqual(result.cin, "")
        XCTAssertEqual(result.firstName, "")
    }

    func testPrepareCinInfoWithShortTokenArrayLeavesMissingFieldsNil() {
        // Only two tokens were recognised: the missing ones must not trap, they stay nil.
        Session.Gv6iuNfQoFK2P4Pd3tdqXjDS25hJGyRR = ["Ahmed", "ALAMI"]
        Session.cinType = .oldCin
        let result = KycResultViewModel()
        result.prepareCinInfo()

        XCTAssertEqual(result.firstName, "Ahmed")
        XCTAssertEqual(result.lastName, "ALAMI")
        XCTAssertEqual(result.cin, "ALAMI")  // the last token
        XCTAssertNil(result.birthDate)
        XCTAssertNil(result.birthCity)
        XCTAssertNil(result.dateExpire)
    }

    func testPrepareCinInfoWithNoTokensDoesNotCrash() {
        Session.Gv6iuNfQoFK2P4Pd3tdqXjDS25hJGyRR = []
        let result = KycResultViewModel()
        result.prepareCinInfo()
        XCTAssertNil(result.firstName)
        XCTAssertNil(result.cin)
        XCTAssertNil(result.lastName)
    }
}
