import UIKit

/// Shared, static store for everything collected during a scan session (original name: `UserSession`).
///
/// The scan screens write into it as they recognise the card and record the face video, and
/// `KycResultViewModel.prepareCinInfo()` reads it back to build the result handed to the host app. Host apps
/// can also read the public getters (for example `getIsCancel()` / `getTimeOut()` after a scanner is
/// dismissed). The state is global and not thread-safe; some values are reset by the scan screens when they start.
///
/// The `private` initializer prevents instantiation; use the static members only.
public class fKrUHvHJknyK3g7L2vSipDnasRUh8RKV {

    // MARK: - Stored session state

    /// Recognised card text fields, in the order consumed by `KycResultViewModel` (original name: `tokenAccess`).
    static var Gv6iuNfQoFK2P4Pd3tdqXjDS25hJGyRR = [String]()

    /// Picture of the front (recto) of the card (original name: `imageCIN`).
    static var ky1ePKYSfStWWtkoyn7UgCesivPB3BvT = UIImage()

    /// Picture of the back (verso) of the card (original name: `imageCINVer`).
    static var yy3ZfLPAkInlRLrv0BbNDQ4fhrwgciEd = UIImage()

    /// Address text recognised on the card (original name: `adresse`).
    static var tzZbByoiDZnS0RIf8lI8Fjir2KSvDlNt = String()

    /// File URL of the zipped face-video frames, once generated (original name: `video`).
    static var Y2tKeK7Qj0fKVKJxcmXe2591quNLlCTF = URL(string: "")

    /// Whether the user cancelled the scan (reset to `false` when a scan screen starts).
    static var isCancel: Bool = false

    /// Whether the user cancelled during the recto step.
    static var isCancelRecto: Bool = false

    /// Whether the face check succeeded (the name keeps its original double "s").
    static var issValidFace: Bool = false

    /// Whether the scan timed out.
    static var isTimeOut: Bool = false

    /// Gender text read from the card.
    static var sexe = String()

    /// The "son of" connecting word read from the card; only reachable through `getSonOf()` / `setSonOf(sonOf:)`.
    static var sonOf = String()

    /// The CIN number.
    static var CIN = String()

    /// Which card generation is currently being scanned.
    static var cinType: CinType = .oldCin

    /// Father's name read from the card (`namePar`).
    static var namePar = String()

    /// Mother's name read from the card (`nameMere`).
    static var nameMere = String()

    /// Whether a valid CIN number has already been recognised during the current scan.
    static var isValidCin: Bool = false

    /// First captured face-video frame.
    static var fram0 = CIImage()

    /// Second captured face-video frame.
    static var fram1 = CIImage()

    /// Third captured face-video frame.
    static var fram2 = CIImage()

    /// Whether the zip archive used for face matching has been generated.
    static var isZipFileFaceMatchingGenerated: Bool = false

    private init() {}

    // MARK: - Public getters

    /// - Returns: `true` if the scan timed out.
    public static func getTimeOut() -> Bool {
        isTimeOut
    }

    /// - Returns: `true` if the user cancelled the scan.
    public static func getIsCancel() -> Bool {
        isCancel
    }

    /// - Returns: `true` if the user cancelled during the recto step.
    public static func getIsCancelRecto() -> Bool {
        isCancelRecto
    }

    /// - Returns: `true` if the face check succeeded.
    public static func getIsValidFace() -> Bool {
        issValidFace
    }

    /// - Returns: The CIN number (empty if not scanned yet).
    public static func getCIN() -> String {
        CIN
    }

    /// - Returns: The father's name (empty if not scanned yet).
    public static func getPar() -> String {
        namePar
    }

    /// - Returns: The mother's name (empty if not scanned yet).
    public static func getMer() -> String {
        nameMere
    }

    /// - Returns: The gender text read from the card (empty if not scanned yet).
    public static func getSexe() -> String {
        sexe
    }

    /// - Returns: The "son of" connecting word (empty if not set).
    public static func getSonOf() -> String {
        sonOf
    }

    // MARK: - Internal setters

    /// - Parameter timeOut: The new time-out state.
    static func setIsTimeOut(timeOut: Bool) {
        isTimeOut = timeOut
    }

    /// - Parameter timeOut: The new "cancelled during recto" state (the label name is historical).
    static func setIsCancelRecto(timeOut: Bool) {
        isCancelRecto = timeOut
    }

    /// - Parameter timeOut: The new "face is valid" state (the label name is historical).
    static func setIssValidFace(timeOut: Bool) {
        issValidFace = timeOut
    }

    /// Sets `isCancel`, despite the "OK" in its name.
    ///
    /// - Parameter isOK: The value stored into `isCancel`.
    static func setIsOK(isOK: Bool) {
        isCancel = isOK
    }

    /// - Parameter CIN: The CIN number to store.
    static func setCIN(CIN: String) {
        self.CIN = CIN
    }

    /// - Parameter sexe: The gender text to store.
    static func setSexe(sexe: String) {
        self.sexe = sexe
    }

    /// - Parameter sonOf: The "son of" connecting word to store.
    static func setSonOf(sonOf: String) {
        self.sonOf = sonOf
    }

    /// - Parameter par: The father's name to store.
    static func setPar(par: String) {
        namePar = par
    }

    /// - Parameter mere: The mother's name to store.
    static func setMere(mere: String) {
        nameMere = mere
    }

    /// - Parameter image: The first captured face-video frame.
    static func setFrame0(image: CIImage) {
        fram0 = image
    }

    /// - Parameter image: The second captured face-video frame.
    static func setFrame1(image: CIImage) {
        fram1 = image
    }

    /// - Parameter image: The third captured face-video frame.
    static func setFrame2(image: CIImage) {
        fram2 = image
    }

    // MARK: - Frames

    /// - Returns: The first captured face-video frame.
    public static func getFrame0() -> CIImage {
        fram0
    }

    /// - Returns: The second captured face-video frame.
    public static func getFrame1() -> CIImage {
        fram1
    }

    /// - Returns: The third captured face-video frame.
    public static func getFrame2() -> CIImage {
        fram2
    }

    // MARK: - Obfuscated accessors

    /// Stores the recognised card text fields (original name: `setTokenAccess(token:)`).
    ///
    /// - Parameter token: The recognised text fields, in the order described by `KycResultViewModel.prepareCinInfo()`.
    static func aNxA3MCpcgFDa4FDA86KX9NrCTfenTa8(token: [String]) {
        Gv6iuNfQoFK2P4Pd3tdqXjDS25hJGyRR = token
    }

    /// - Returns: The recognised card text fields (original name: `getTokenAccess()`).
    public static func UxpybnXDN3EZnFfQfQ7quriQgR6Z3iZ3() -> [String] {
        Gv6iuNfQoFK2P4Pd3tdqXjDS25hJGyRR
    }

    /// Stores the address text (original name: `setAdressAccess(adresse:)`).
    ///
    /// - Parameter adresse: The address read from the card.
    public static func wCkaQlFAjOaL6RErxjj4feMkYGw4vyof(adresse: String) {
        tzZbByoiDZnS0RIf8lI8Fjir2KSvDlNt = adresse
    }

    /// - Returns: The address text (original name: `getAdresseAccess()`).
    public static func siJc2rfh5ymgtKjVzy6dn4tgiz24rOXb() -> String {
        tzZbByoiDZnS0RIf8lI8Fjir2KSvDlNt
    }

    /// Stores the picture of the front of the card (original name: `setImageAccess(image:)`).
    ///
    /// - Parameter image: The recto picture.
    public static func vj7Kb8bCwAxxRd1Kiduq1eSQz9rLNAOV(image: UIImage) {
        ky1ePKYSfStWWtkoyn7UgCesivPB3BvT = image
    }

    /// Stores the picture of the back of the card (original name: `setImageVerAccess(image:)`).
    ///
    /// - Parameter image: The verso picture.
    public static func N7scpKD22a00a5V3JRCZEU5ooETWBJrb(image: UIImage) {
        yy3ZfLPAkInlRLrv0BbNDQ4fhrwgciEd = image
    }

    /// - Returns: The picture of the front of the card (original name: `getImageAccess()`).
    public static func hdya2TCPu5RNn85L70JNyfpdQmfl253p() -> UIImage {
        ky1ePKYSfStWWtkoyn7UgCesivPB3BvT
    }

    /// - Returns: The picture of the back of the card (original name: `getImageVerAccess()`).
    public static func TV29zYAmpTQqLinjW8mLR5co1wC9USQ8() -> UIImage {
        yy3ZfLPAkInlRLrv0BbNDQ4fhrwgciEd
    }

    /// Stores the URL of the zipped face-video frames (original name: `setVideoAccess(video:)`).
    ///
    /// - Parameter video: The archive's file URL.
    public static func CBtdift8be5uCJ5CpWbd6yBp4ZayVxUx(video: URL) {
        Y2tKeK7Qj0fKVKJxcmXe2591quNLlCTF = video
    }

    /// - Returns: The URL of the zipped face-video frames (original name: `getVideoAccess()`), or `nil` before the
    ///   archive has been generated (see `isZipFaceMatchingGenerated()`).
    public static func RPIGTk10Z6Va7IDsKZCG5N34EDa2yEKA() -> URL? {
        Y2tKeK7Qj0fKVKJxcmXe2591quNLlCTF
    }

    /// - Returns: `true` if the face-matching zip archive has been generated.
    public static func isZipFaceMatchingGenerated() -> Bool {
        isZipFileFaceMatchingGenerated
    }

}
