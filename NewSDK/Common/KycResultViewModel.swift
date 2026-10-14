import UIKit

/// The identity information extracted from a scanned CIN card, handed to the host app when a scan completes.
///
/// Every property is `nil` until `prepareCinInfo()` copies the values collected during the scan out of
/// the shared session (`fKrUHvHJknyK3g7L2vSipDnasRUh8RKV`, the SDK's `UserSession`).
public class KycResultViewModel: NSObject {
    /// Expiry date text read from the card.
    public internal(set) var dateExpire: String?
    /// Address text read from the card (`adress` follows the SDK's French-derived spelling).
    public internal(set) var adress: String?
    /// The card (CIN) number.
    public internal(set) var cin: String?
    /// The holder's last name.
    public internal(set) var lastName: String?
    /// The holder's first name.
    public internal(set) var firstName: String?
    /// The holder's birth date text.
    public internal(set) var birthDate: String?
    /// The holder's gender as read from the card.
    public internal(set) var gender: String?
    /// The name of the holder's mother.
    public internal(set) var motherName: String?
    /// The name of the holder's father.
    public internal(set) var fatherName: String?
    /// The holder's birth city.
    public internal(set) var birthCity: String?
    /// Picture of the front (recto) of the card.
    public internal(set) var rectoImage: UIImage?
    /// Picture of the back (verso) of the card.
    public internal(set) var versoImage: UIImage?

    /// Fills every property from the values currently stored in the shared session.
    ///
    /// The recognised text fields are read from the session's token array (`getTokenAccess`): index 0 is the
    /// first name, 1 the last name, 2 the birth date, the last element the CIN number. Indices 3 and 4 hold the
    /// expiry date and the birth city, swapped depending on the card type (old CIN: expiry at 4, city at 3;
    /// new CIN: expiry at 3, city at 4). Tokens that are missing (a shorter array) leave the matching property `nil`.
    public func prepareCinInfo() {
        let tokens = fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.UxpybnXDN3EZnFfQfQ7quriQgR6Z3iZ3()
        let isOldCin = fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.cinType == .oldCin

        // A token that was never recognised is simply left `nil` instead of trapping on a short array.
        func token(at index: Int) -> String? {
            tokens.indices.contains(index) ? tokens[index] : nil
        }

        dateExpire = token(at: isOldCin ? 4 : 3)
        adress = fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.tzZbByoiDZnS0RIf8lI8Fjir2KSvDlNt
        cin = tokens.last
        lastName = token(at: 1)
        firstName = tokens.first
        birthDate = token(at: 2)
        gender = fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.getSexe()
        motherName = fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.nameMere
        fatherName = fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.namePar
        birthCity = token(at: isOldCin ? 3 : 4)
        rectoImage = fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.hdya2TCPu5RNn85L70JNyfpdQmfl253p()
        versoImage = fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.TV29zYAmpTQqLinjW8mLR5co1wC9USQ8()
    }
}
