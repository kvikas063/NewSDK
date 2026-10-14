import UIKit
import XCTest

@testable import NewSDK

/// Tests for the static scan-session state holder (flags, text fields, images and frames).
final class UserSessionTests: XCTestCase {

    private typealias Session = fKrUHvHJknyK3g7L2vSipDnasRUh8RKV

    override func setUp() {
        super.setUp()
        resetSession()
    }

    override func tearDown() {
        resetSession()
        super.tearDown()
    }

    private func resetSession() {
        Session.isCancel = false
        Session.isCancelRecto = false
        Session.isTimeOut = false
        Session.issValidFace = false
        Session.isValidCin = false
        Session.isZipFileFaceMatchingGenerated = false
        Session.cinType = .oldCin
        Session.CIN = ""
        Session.sexe = ""
        Session.sonOf = ""
        Session.namePar = ""
        Session.nameMere = ""
        Session.tzZbByoiDZnS0RIf8lI8Fjir2KSvDlNt = ""
        Session.Gv6iuNfQoFK2P4Pd3tdqXjDS25hJGyRR = []
        Session.ky1ePKYSfStWWtkoyn7UgCesivPB3BvT = UIImage()
        Session.yy3ZfLPAkInlRLrv0BbNDQ4fhrwgciEd = UIImage()
        Session.Y2tKeK7Qj0fKVKJxcmXe2591quNLlCTF = nil
    }

    func testFlagsDefaultToFalse() {
        XCTAssertFalse(Session.getTimeOut())
        XCTAssertFalse(Session.getIsCancel())
        XCTAssertFalse(Session.getIsCancelRecto())
        XCTAssertFalse(Session.getIsValidFace())
        XCTAssertFalse(Session.isZipFaceMatchingGenerated())
    }

    func testFlagSettersAreReflectedByGetters() {
        Session.setIsTimeOut(timeOut: true)
        Session.setIsOK(isOK: true)
        Session.setIsCancelRecto(timeOut: true)
        Session.setIssValidFace(timeOut: true)
        XCTAssertTrue(Session.getTimeOut())
        XCTAssertTrue(Session.getIsCancel())
        XCTAssertTrue(Session.getIsCancelRecto())
        XCTAssertTrue(Session.getIsValidFace())

        Session.setIsTimeOut(timeOut: false)
        XCTAssertFalse(Session.getTimeOut())
    }

    func testTextFieldsRoundTrip() {
        Session.setCIN(CIN: "AB123456")
        Session.setSexe(sexe: "M")
        Session.setSonOf(sonOf: "BEN")
        Session.setPar(par: "ALAMI")
        Session.setMere(mere: "FATIMA")
        Session.wCkaQlFAjOaL6RErxjj4feMkYGw4vyof(adresse: "12 Rue X, Rabat")

        XCTAssertEqual(Session.getCIN(), "AB123456")
        XCTAssertEqual(Session.getSexe(), "M")
        XCTAssertEqual(Session.getSonOf(), "BEN")
        XCTAssertEqual(Session.getPar(), "ALAMI")
        XCTAssertEqual(Session.getMer(), "FATIMA")
        XCTAssertEqual(Session.siJc2rfh5ymgtKjVzy6dn4tgiz24rOXb(), "12 Rue X, Rabat")
    }

    func testTokensRoundTrip() {
        Session.aNxA3MCpcgFDa4FDA86KX9NrCTfenTa8(token: ["a", "b", "c"])
        XCTAssertEqual(Session.UxpybnXDN3EZnFfQfQ7quriQgR6Z3iZ3(), ["a", "b", "c"])
    }

    func testImagesAndFramesRoundTrip() {
        let recto = UIImage(systemName: "star")!
        let verso = UIImage(systemName: "heart")!
        Session.vj7Kb8bCwAxxRd1Kiduq1eSQz9rLNAOV(image: recto)
        Session.N7scpKD22a00a5V3JRCZEU5ooETWBJrb(image: verso)
        XCTAssertTrue(Session.hdya2TCPu5RNn85L70JNyfpdQmfl253p() === recto)
        XCTAssertTrue(Session.TV29zYAmpTQqLinjW8mLR5co1wC9USQ8() === verso)

        let frame = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 4, height: 4))
        Session.setFrame0(image: frame)
        Session.setFrame1(image: frame)
        Session.setFrame2(image: frame)
        XCTAssertEqual(Session.getFrame0().extent, frame.extent)
        XCTAssertEqual(Session.getFrame1().extent, frame.extent)
        XCTAssertEqual(Session.getFrame2().extent, frame.extent)
    }

    func testVideoURLRoundTrip() {
        let url = URL(fileURLWithPath: "/tmp/selfie.mov")
        Session.CBtdift8be5uCJ5CpWbd6yBp4ZayVxUx(video: url)
        XCTAssertEqual(Session.RPIGTk10Z6Va7IDsKZCG5N34EDa2yEKA(), url)
    }

    func testVideoURLBeforeTheArchiveExistsIsNilInsteadOfTrapping() {
        XCTAssertNil(Session.RPIGTk10Z6Va7IDsKZCG5N34EDa2yEKA())
    }
}
