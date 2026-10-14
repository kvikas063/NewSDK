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

import Accelerate
import CoreImage
import MLKitTextRecognition
import MLKitVision
import TensorFlowLite
import UIKit

// MARK: - Types

/// The outcome of running one camera frame through ``ModelDataHandler/runModel(onFrame:)``.
struct Result {

    /// The six recognised text fields of the identity card, in detection order (top to bottom).
    ///
    /// An entry is an empty string until its text has been recognised and validated.
    let myArray2: [String]
}

/// A single detection returned by the object detector, already scaled to the source image.
struct Inference {
    /// The detection confidence score reported by the model, in the range `0...1`.
    let confidence: Float

    /// The label of the detected class, looked up in the labels file.
    let className: String

    /// The bounding box of the detection in the coordinate space of the source pixel buffer.
    let rect: CGRect
}

/// Information about a model file or labels file: its resource name and file extension.
typealias FileInfo = (name: String, extension: String)

/// Information about the MobileNet SSD model bundled with the SDK.
enum MobileNetSSD {
    /// The TensorFlow Lite model file (`detect.tflite`).
    static let modelInfo: FileInfo = (name: "detect", extension: "tflite")

    /// The labels file (`labelmap.txt`) listing the classes the model can detect.
    static let labelsInfo: FileInfo = (name: "labelmap", extension: "txt")
}

// MARK: - ModelDataHandler

/// Runs a TensorFlow Lite SSD detector on camera frames and reads the detected regions of an
/// identity card with ML Kit text recognition.
///
/// The handler preprocesses a frame, invokes the `Interpreter`, converts the output tensors into
/// `Inference` values, and, when exactly six regions are found, recognises the text of each one.
/// Recognised values are validated and stored in ``myArrayFinal``.
class ModelDataHandler: NSObject {

    // MARK: Model parameters

    /// The minimum confidence score a detection needs in order to be kept.
    private let threshold: Float = 0.5

    /// The number of images the model processes per invocation.
    private let batchSize = 1

    /// The number of channels per pixel of the model input buffer (BGRA/ARGB/RGBA source data).
    private let inputChannels = 4

    /// The width, in pixels, of the model input.
    private let inputWidth = 300

    /// The height, in pixels, of the model input.
    private let inputHeight = 300

    // MARK: Private properties

    /// The class names read from the labels file, one per line.
    private var labels: [String] = []

    /// The text most recently recognised for each of the six card regions.
    ///
    /// A value is promoted to ``myArrayFinal`` once it is recognised twice in a row (where the
    /// field requires it) and passes validation.
    private var myArray = ["", "", "", "", "", ""]

    /// Protects `myArray` and `myArrayFinal`: ML Kit completion handlers write them while `runModel`
    /// reads them from the camera queue.
    private let stateLock = NSLock()

    /// The validated text for each of the six card regions; empty until the field is accepted.
    private var myArrayFinal = ["", "", "", "", "", ""]

    /// TensorFlow Lite `Interpreter` object for performing inference on a given model.
    private var interpreter: Interpreter

    // MARK: - Initialization

    /// Creates a handler if the model and labels files can be loaded from the SDK bundle.
    ///
    /// The model is loaded into an `Interpreter` whose tensors are allocated immediately, then the
    /// labels file is read. The initializer fails if the model file is missing or the interpreter
    /// cannot be created; a missing or unreadable labels file is a fatal error.
    ///
    /// - Parameters:
    ///   - modelFileInfo: The name and extension of the TensorFlow Lite model file.
    ///   - labelsFileInfo: The name and extension of the labels file.
    ///   - threadCount: The number of threads the `Interpreter` may use. Defaults to 1.
    init?(modelFileInfo: FileInfo, labelsFileInfo: FileInfo, threadCount: Int = 1) {
        let modelFilename = modelFileInfo.name

        // Construct the path to the model file.
        guard
            let modelPath = Bundle.sdk.path(
                forResource: modelFilename,
                ofType: modelFileInfo.extension
            )
        else {
            print("Failed to load the model file with name: \(modelFilename).")
            return nil
        }

        // Specify the options for the `Interpreter`.
        var options = Interpreter.Options()
        options.threadCount = threadCount
        do {
            // Create the `Interpreter`.
            interpreter = try Interpreter(modelPath: modelPath, options: options)
            // Allocate memory for the model's input `Tensor`s.
            try interpreter.allocateTensors()
        } catch let error {
            print("Failed to create the interpreter with error: \(error.localizedDescription)")
            return nil
        }

        super.init()

        // Load the classes listed in the labels file.
        loadLabels(fileInfo: labelsFileInfo)
    }

    // MARK: - Inference

    /// Runs the detector on a camera frame and updates the recognised card fields.
    ///
    /// The frame is scaled to the model input size and converted to RGB data before inference. If
    /// the detector finds exactly six regions, each one is cropped from the full-resolution frame
    /// and sent to text recognition (which completes asynchronously), and the frame is stored in
    /// `UserSession.imageCIN`.
    ///
    /// - Parameter pixelBuffer: The camera frame, in 32ARGB or 32BGRA format.
    /// - Returns: A `Result` holding the fields validated so far, or `nil` if the frame could not
    ///   be scaled, converted or run through the `Interpreter`.
    func runModel(onFrame pixelBuffer: CVPixelBuffer) -> Result? {

        let imageWidth = CVPixelBufferGetWidth(pixelBuffer)
        let imageHeight = CVPixelBufferGetHeight(pixelBuffer)
        let sourcePixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)
        guard sourcePixelFormat == kCVPixelFormatType_32ARGB || sourcePixelFormat == kCVPixelFormatType_32BGRA else {
            print("Unsupported pixel format: only 32ARGB and 32BGRA frames can be processed.")
            return nil
        }

        let imageChannels = 4
        assert(imageChannels >= inputChannels)

        // Crops the image to the biggest square in the center and scales it down to model dimensions.
        let scaledSize = CGSize(width: inputWidth, height: inputHeight)
        guard let scaledPixelBuffer = pixelBuffer.GQ6vhImkYfaK9QUjzGk8mIxddotjfFaR(to: scaledSize) else {
            return nil
        }

        let outputBoundingBox: Tensor
        let outputClasses: Tensor
        let outputScores: Tensor
        let outputCount: Tensor
        do {
            let inputTensor = try interpreter.input(at: 0)

            // Remove the alpha component from the image buffer to get the RGB data.
            guard
                let rgbData = rgbDataFromBuffer(
                    scaledPixelBuffer,
                    byteCount: batchSize * inputWidth * inputHeight * inputChannels,
                    isModelQuantized: inputTensor.dataType == .uInt8
                )
            else {
                print("Failed to convert the image buffer to RGB data.")
                return nil
            }

            // Copy the RGB data to the input `Tensor`.
            try interpreter.copy(rgbData, toInputAt: 0)

            // Run inference by invoking the `Interpreter`.
            try interpreter.invoke()

            outputBoundingBox = try interpreter.output(at: 0)
            outputClasses = try interpreter.output(at: 1)
            outputScores = try interpreter.output(at: 2)
            outputCount = try interpreter.output(at: 3)
        } catch let error {
            print("Failed to invoke the interpreter with error: \(error.localizedDescription)")
            return nil
        }

        // Formats the results
        let resultArray = formatResults(
            boundingBox: [Float](unsafeData: outputBoundingBox.data) ?? [],
            outputClasses: [Float](unsafeData: outputClasses.data) ?? [],
            outputScores: [Float](unsafeData: outputScores.data) ?? [],
            outputCount: Int(([Float](unsafeData: outputCount.data) ?? [0])[0]),
            width: CGFloat(imageWidth),
            height: CGFloat(imageHeight)
        )

        // The card is only read when all six expected regions have been detected.
        if resultArray.count == 6 {
            let imageInit = convert(cmage: CIImage(cvImageBuffer: pixelBuffer))

            for (index, res) in resultArray.enumerated() {
                let imageCroped = cropToBounds(image: imageInit, rect: res.rect, scale: 1)
                detectText(image: imageCroped, index: index)
            }

            // Keep the full frame of the card in the user session.
            fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.ky1ePKYSfStWWtkoyn7UgCesivPB3BvT = imageInit
        }

        stateLock.lock()
        defer { stateLock.unlock() }
        return Result(myArray2: myArrayFinal)
    }

    /// Converts the raw detector output into `Inference` values scaled to the source image.
    ///
    /// Detections scoring below ``threshold`` are dropped. The remaining ones are sorted by the
    /// vertical position of their bounding box, top to bottom.
    ///
    /// - Parameters:
    ///   - boundingBox: The flattened `[top, left, bottom, right]` boxes, normalised to `0...1`.
    ///   - outputClasses: The class index of each detection.
    ///   - outputScores: The confidence score of each detection.
    ///   - outputCount: The number of valid detections in the other arrays.
    ///   - width: The width of the source image, used to scale the boxes.
    ///   - height: The height of the source image, used to scale the boxes.
    /// - Returns: The kept detections, ordered by ascending `rect.origin.y`.
    private func formatResults(
        boundingBox: [Float], outputClasses: [Float], outputScores: [Float], outputCount: Int, width: CGFloat,
        height: CGFloat
    ) -> [Inference] {
        var resultsArray: [Inference] = []
        // Never read past what the model actually returned.
        let detectionCount = min(outputCount, outputScores.count, outputClasses.count, boundingBox.count / 4)
        guard detectionCount > 0 else {
            return resultsArray
        }
        for i in 0..<detectionCount {

            let score = outputScores[i]

            // Filters results with confidence < threshold.
            guard score >= threshold else {
                continue
            }

            // Gets the output class names for detected classes from labels list.
            let outputClassIndex = Int(outputClasses[i])
            let labelIndex = outputClassIndex + 1
            let outputClass = labels.indices.contains(labelIndex) ? labels[labelIndex] : ""

            var rect: CGRect = CGRect.zero

            // Translates the detected bounding box to CGRect.
            rect.origin.y = CGFloat(boundingBox[4 * i])
            rect.origin.x = CGFloat(boundingBox[4 * i + 1])
            rect.size.height = CGFloat(boundingBox[4 * i + 2]) - rect.origin.y
            rect.size.width = CGFloat(boundingBox[4 * i + 3]) - rect.origin.x

            // The detected corners are for model dimensions. So we scale the rect with respect to the
            // actual image dimensions.
            let newRect = rect.applying(CGAffineTransform(scaleX: width, y: height))

            let inference = Inference(
                confidence: score,
                className: outputClass,
                rect: newRect)
            resultsArray.append(inference)
        }

        // Sort results from the top of the image to the bottom.
        resultsArray.sort { (first, second) -> Bool in
            return first.rect.origin.y < second.rect.origin.y

        }

        return resultsArray
    }

    // MARK: - Image helpers

    /// Crops an image to a rectangle by drawing it into a smaller opaque image context.
    ///
    /// - Parameters:
    ///   - image: The image to crop.
    ///   - rect: The region to keep, in the coordinate space of `image`.
    ///   - scale: The divisor applied to the output size and to the offset of the crop.
    /// - Returns: The cropped image.
    private func cropToBounds(image: UIImage, rect: CGRect, scale: CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(
            CGSize(width: rect.size.width / scale, height: rect.size.height / scale), true, 0.0)
        image.draw(at: CGPoint(x: -rect.origin.x / scale, y: -rect.origin.y / scale))
        let croppedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return croppedImage ?? image

    }

    /// Renders a `CIImage` into a bitmap-backed `UIImage`.
    ///
    /// - Parameter cmage: The Core Image image to render.
    /// - Returns: A `UIImage` backed by a `CGImage` covering the full extent of `cmage`.
    private func convert(cmage: CIImage) -> UIImage {
        let context: CIContext = CIContext.init(options: nil)

        guard let cgImage = context.createCGImage(cmage, from: cmage.extent) else {
            return UIImage(ciImage: cmage)
        }

        return UIImage(cgImage: cgImage)

    }

    // MARK: - Text recognition

    /// Recognises the text of one cropped card region and updates the stored field values.
    ///
    /// Nothing happens if the field at `index` has already been accepted, or if recognition fails.
    /// Otherwise, once recognition completes, the text is validated with `Utils` according to the
    /// field index:
    /// - 0 and 1: accepted if it equals the previous reading and is a valid name.
    /// - 2: ignored unless it is a valid date; accepted if it equals the previous reading.
    /// - 3: accepted immediately if it is a valid name.
    /// - 4: accepted immediately if it is a valid date.
    /// - 5: ignored unless it is a valid CIN number; accepted if it equals the previous reading.
    ///
    /// A reading that is not accepted is stored in ``myArray`` for the next comparison. The
    /// completion handler is invoked by ML Kit and writes to ``myArray`` and ``myArrayFinal``.
    ///
    /// - Parameters:
    ///   - image: The cropped image of the card region.
    ///   - index: The position of the region, from 0 to 5, matching the order of `myArrayFinal`.
    private func detectText(image: UIImage, index: Int) {

        stateLock.lock()
        let alreadyAccepted = myArrayFinal.count > index && !myArrayFinal[index].isEmpty
        stateLock.unlock()
        if alreadyAccepted {
            return
        }

        let textRecognizer = TextRecognizer.textRecognizer(options: TextRecognizerOptions())

        let visionImage = VisionImage(image: image)

        textRecognizer.process(visionImage) { result, error in

            guard error == nil, let result = result else {
                return
            }
            let text = result.text

            self.stateLock.lock()
            defer { self.stateLock.unlock() }

            switch index {
            case 0, 1:
                if self.myArray[index] == text {
                    if Utils.isValidName(testStr: text) {
                        self.myArrayFinal[index] = text
                    }
                } else {
                    self.myArray[index] = text
                }

            case 2:
                if !Utils.isValidDate(testStr: text) {
                    break
                }

                if self.myArray[index] == text {
                    self.myArrayFinal[index] = text
                } else {
                    self.myArray[index] = text
                }

            case 3:
                if Utils.isValidName(testStr: text) {
                    self.myArrayFinal[index] = text
                }

            case 4:
                if Utils.isValidDate(testStr: text) {
                    self.myArrayFinal[index] = text
                }

            case 5:
                if !Utils.isValidCIN(testStr: text) {
                    break
                }
                if self.myArray[index] == text {
                    self.myArrayFinal[index] = text
                } else {
                    self.myArray[index] = text
                }

            default:
                break
            }
        }

    }

    // MARK: - Private helpers

    /// Loads the labels from the labels file and stores them in the `labels` property.
    ///
    /// The file is read as UTF-8 and split into lines. A missing or unreadable file is a fatal
    /// error.
    ///
    /// - Parameter fileInfo: The name and extension of the labels file in the SDK bundle.
    private func loadLabels(fileInfo: FileInfo) {
        let filename = fileInfo.name
        let fileExtension = fileInfo.extension
        guard let fileURL = Bundle.sdk.url(forResource: filename, withExtension: fileExtension) else {
            fatalError(
                "Labels file not found in bundle. Please add a labels file with name "
                    + "\(filename).\(fileExtension) and try again.")
        }
        do {
            let contents = try String(contentsOf: fileURL, encoding: .utf8)
            labels = contents.components(separatedBy: .newlines)
        } catch {
            fatalError(
                "Labels file named \(filename).\(fileExtension) cannot be read. Please add a "
                    + "valid labels file and try again.")
        }
    }

    /// Returns the RGB data representation of the given image buffer with the specified `byteCount`.
    ///
    /// - Parameters:
    ///   - buffer: The BGRA or ARGB pixel buffer to convert to RGB data.
    ///   - byteCount: The expected byte count for the RGB data calculated using the values that the
    ///       model was trained on: `batchSize * imageWidth * imageHeight * componentsCount`. It is
    ///       not used by the conversion itself.
    ///   - isModelQuantized: Whether the model is quantized (i.e. fixed point values rather than
    ///       floating point values).
    /// - Returns: The RGB data representation of the image buffer or `nil` if the buffer could not be
    ///     converted.
    private func rgbDataFromBuffer(
        _ buffer: CVPixelBuffer,
        byteCount: Int,
        isModelQuantized: Bool
    ) -> Data? {
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer {
            CVPixelBufferUnlockBaseAddress(buffer, .readOnly)
        }
        guard let sourceData = CVPixelBufferGetBaseAddress(buffer) else {
            return nil
        }

        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        let sourceBytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        let destinationChannelCount = 3
        let destinationBytesPerRow = destinationChannelCount * width

        var sourceBuffer = vImage_Buffer(
            data: sourceData,
            height: vImagePixelCount(height),
            width: vImagePixelCount(width),
            rowBytes: sourceBytesPerRow)

        guard let destinationData = malloc(height * destinationBytesPerRow) else {
            print("Error: out of memory")
            return nil
        }

        defer {
            free(destinationData)
        }

        var destinationBuffer = vImage_Buffer(
            data: destinationData,
            height: vImagePixelCount(height),
            width: vImagePixelCount(width),
            rowBytes: destinationBytesPerRow)

        if CVPixelBufferGetPixelFormatType(buffer) == kCVPixelFormatType_32BGRA {
            vImageConvert_BGRA8888toRGB888(&sourceBuffer, &destinationBuffer, UInt32(kvImageNoFlags))
        } else if CVPixelBufferGetPixelFormatType(buffer) == kCVPixelFormatType_32ARGB {
            vImageConvert_ARGB8888toRGB888(&sourceBuffer, &destinationBuffer, UInt32(kvImageNoFlags))
        } else {
            // Any other layout would leave `destinationData` uninitialised.
            return nil
        }

        let byteData = Data(bytes: destinationBuffer.data, count: destinationBuffer.rowBytes * height)
        if isModelQuantized {
            return byteData
        }

        // Not quantized, convert to floats
        let bytes = Array<UInt8>(unsafeData: byteData)!
        var floats = [Float]()
        for i in 0..<bytes.count {
            floats.append(Float(bytes[i]) / 255.0)
        }
        return Data(copyingBufferOf: floats)
    }
}

// MARK: - Extensions

extension Data {
    /// Creates a new buffer by copying the buffer pointer of the given array.
    ///
    /// - Warning: The given array's element type `T` must be trivial in that it can be copied bit
    ///     for bit with no indirection or reference-counting operations; otherwise, reinterpreting
    ///     data from the resulting buffer has undefined behavior.
    /// - Parameter array: An array with elements of type `T`.
    init<T>(copyingBufferOf array: [T]) {
        self = array.withUnsafeBufferPointer(Data.init)
    }
}

extension Array {
    /// Creates a new array from the bytes of the given unsafe data.
    ///
    /// - Warning: The array's `Element` type must be trivial in that it can be copied bit for bit
    ///     with no indirection or reference-counting operations; otherwise, copying the raw bytes in
    ///     the `unsafeData`'s buffer to a new array returns an unsafe copy.
    /// - Note: Returns `nil` if `unsafeData.count` is not a multiple of
    ///     `MemoryLayout<Element>.stride`.
    /// - Parameter unsafeData: The data containing the bytes to turn into an array.
    init?(unsafeData: Data) {
        guard unsafeData.count % MemoryLayout<Element>.stride == 0 else { return nil }
        self = unsafeData.withUnsafeBytes { .init($0.bindMemory(to: Element.self)) }
    }
}
