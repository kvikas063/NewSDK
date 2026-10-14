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

import AVFoundation
import UIKit

/// A view whose backing layer is an `AVCaptureVideoPreviewLayer`, so the camera frames are displayed on it
/// (original name: `PreviewView`).
class bIvpRBRowRuX8QU2s0Lvnt0kuYdNTI9A: UIView {

    /// The view's layer, typed as an `AVCaptureVideoPreviewLayer`.
    ///
    /// Traps if the layer is of a different type, which cannot happen because of `layerClass`.
    var previewLayer: AVCaptureVideoPreviewLayer {

        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Layer expected is of type VideoPreviewLayer")

        }
        return layer
    }

    /// The capture session whose output is displayed; forwarded to the preview layer.
    var session: AVCaptureSession? {
        get {
            previewLayer.session
        }
        set {
            previewLayer.session = newValue
        }
    }

    /// Makes the view's backing layer an `AVCaptureVideoPreviewLayer`.
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
}
