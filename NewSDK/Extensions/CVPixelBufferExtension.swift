// Copyright 2019 The TensorFlow Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// =============================================================================

import Accelerate
import Foundation

extension CVPixelBuffer {
    /// Scales the pixel buffer to the given size (original name: `resized(to:)`).
    ///
    /// The buffer must be in the 32-bit BGRA pixel format; any other format returns `nil`. The whole image is
    /// scaled with vImage; despite the TensorFlow sample's wording, no square crop is applied. The returned
    /// buffer owns the memory allocated for the scaled pixels and frees it when it is released.
    ///
    /// - Parameter size: The width and height, in pixels, of the output buffer.
    /// - Returns: The scaled pixel buffer, or `nil` if memory allocation, scaling or buffer creation fails.
    func GQ6vhImkYfaK9QUjzGk8mIxddotjfFaR(to size: CGSize) -> CVPixelBuffer? {

        let imageWidth = CVPixelBufferGetWidth(self)
        let imageHeight = CVPixelBufferGetHeight(self)

        let pixelBufferType = CVPixelBufferGetPixelFormatType(self)

        guard pixelBufferType == kCVPixelFormatType_32BGRA else { return nil }

        let inputImageRowBytes = CVPixelBufferGetBytesPerRow(self)
        let imageChannels = 4

        CVPixelBufferLockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
        // The base address stays locked until scaling is done, whichever way the function returns.
        defer { CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0)) }

        guard let inputBaseAddress = CVPixelBufferGetBaseAddress(self) else {
            return nil
        }

        // Wraps the input pixels in a vImage buffer.
        var inputVImageBuffer = vImage_Buffer(
            data: inputBaseAddress, height: UInt(imageHeight), width: UInt(imageWidth), rowBytes: inputImageRowBytes)

        let scaledImageRowBytes = Int(size.width) * imageChannels
        guard let scaledImageBytes = malloc(Int(size.height) * scaledImageRowBytes) else {
            return nil
        }

        // Allocates a vImage buffer for scaled image.
        var scaledVImageBuffer = vImage_Buffer(
            data: scaledImageBytes, height: UInt(size.height), width: UInt(size.width), rowBytes: scaledImageRowBytes)

        // Performs the scale operation on input image buffer and stores it in scaled image buffer.
        let scaleError = vImageScale_ARGB8888(&inputVImageBuffer, &scaledVImageBuffer, nil, vImage_Flags(0))

        guard scaleError == kvImageNoError else {
            free(scaledImageBytes)
            return nil
        }

        // Frees the malloc'ed pixel bytes when the new pixel buffer is deallocated.
        let releaseCallBack: CVPixelBufferReleaseBytesCallback = { mutablePointer, pointer in

            if let pointer = pointer {
                free(UnsafeMutableRawPointer(mutating: pointer))
            }
        }

        var scaledPixelBuffer: CVPixelBuffer?

        // Converts the scaled vImage buffer to CVPixelBuffer
        let conversionStatus = CVPixelBufferCreateWithBytes(
            nil, Int(size.width), Int(size.height), pixelBufferType, scaledImageBytes, scaledImageRowBytes,
            releaseCallBack, nil, nil, &scaledPixelBuffer)

        guard conversionStatus == kCVReturnSuccess else {

            free(scaledImageBytes)
            return nil
        }

        return scaledPixelBuffer
    }

}
