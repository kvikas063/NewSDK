import Foundation
import Zip

extension Zip {

    /// Zips files into the app's Documents directory using the best compression and no password.
    ///
    /// - Parameters:
    ///   - paths: The file URLs to add to the archive.
    ///   - fileName: The archive name, without the `.zip` extension.
    /// - Returns: The URL of the created `<fileName>.zip` archive.
    /// - Throws: Any error raised by `Zip.zipFiles` while creating the archive.
    class func compressFiles(_ paths: [URL], fileName: String) throws -> URL {
        try quickZipFiles(paths, fileName: fileName, compression: .BestCompression, progress: nil)
    }

    /// Zips files into `<Documents>/<fileName>.zip` without a password.
    ///
    /// - Parameters:
    ///   - paths: The file URLs to add to the archive.
    ///   - fileName: The archive name, without the `.zip` extension.
    ///   - compression: The compression level to use.
    ///   - progress: Optional closure called with the completion fraction while zipping.
    /// - Returns: The URL of the created archive in the user's Documents directory.
    /// - Throws: Any error raised by `Zip.zipFiles` while creating the archive.
    class func quickZipFiles(
        _ paths: [URL], fileName: String, compression: ZipCompression, progress: ((_ progress: Double) -> ())?
    ) throws -> URL {
        let fileManager = FileManager.default
        let documentsUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationUrl = documentsUrl.appendingPathComponent("\(fileName).zip")
        try zipFiles(
            paths: paths, zipFilePath: destinationUrl, password: nil, compression: compression, progress: progress)
        return destinationUrl
    }

}
