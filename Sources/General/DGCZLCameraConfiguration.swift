//
//  DGCZLCameraConfiguration.swift
//  DGCZLPhotoBrowser
//
//  Created by long on 2021/11/10.
//
//  Copyright (c) 2020 Long Zhang <495181165@qq.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import UIKit
import AVFoundation

@objcMembers
public class DGCZLCameraConfiguration: NSObject {
    private var dgc_pri_allowTakePhoto = true
    /// Allow taking photos in the camera (Need allowSelectImage to be true). Defaults to true.
    public var allowTakePhoto: Bool {
        get {
            dgc_pri_allowTakePhoto && DGCZLPhotoConfiguration.default().allowSelectImage
        }
        set {
            dgc_pri_allowTakePhoto = newValue
        }
    }
    
    private var dgc_pri_allowRecordVideo = true
    /// Allow recording in the camera (Need allowSelectVideo to be true). Defaults to true.
    public var allowRecordVideo: Bool {
        get {
            dgc_pri_allowRecordVideo && DGCZLPhotoConfiguration.default().allowSelectVideo
        }
        set {
            dgc_pri_allowRecordVideo = newValue
        }
    }
    
    private var dgc_pri_minRecordDuration: DGCZLPhotoConfiguration.Second = 0
    /// Minimum recording duration. Defaults to 0.
    public var minRecordDuration: DGCZLPhotoConfiguration.Second {
        get {
            dgc_pri_minRecordDuration
        }
        set {
            dgc_pri_minRecordDuration = max(0, newValue)
        }
    }
    
    private var dgc_pri_maxRecordDuration: DGCZLPhotoConfiguration.Second = 20
    /// Maximum recording duration. Defaults to 20, minimum is 1.
    public var maxRecordDuration: DGCZLPhotoConfiguration.Second {
        get {
            dgc_pri_maxRecordDuration
        }
        set {
            dgc_pri_maxRecordDuration = max(1, newValue)
        }
    }
    
    /// Indicates whether the video flowing through the connection should be mirrored about its vertical axis.
    public var isVideoMirrored = true
    
    /// Video resolution. Defaults to hd1920x1080.
    public var sessionPreset: DGCZLCameraConfiguration.DGCCaptureSessionPreset = .hd1920x1080
    
    /// Camera focus mode. Defaults to continuousAutoFocus
    public var focusMode: DGCZLCameraConfiguration.DGCFocusMode = .continuousAutoFocus
    
    /// Camera exposure mode. Defaults to continuousAutoExposure
    public var exposureMode: DGCZLCameraConfiguration.DGCExposureMode = .continuousAutoExposure
    
    /// Camera flahs switch. Defaults to true.
    public var showFlashSwitch = true
    
    /// Whether to support switch camera. Defaults to true.
    public var allowSwitchCamera = true
    
    /// Flag to enable tap-to-record functionality. Default is false.
    /// Note: This property is prioritized lower than `allowTakePhoto`.
    /// If `allowTakePhoto` is true, `tapToRecordVideo` will be ignored.
    public var tapToRecordVideo: Bool = false
    
    private var dgc__enableWideCameras: Bool = false
    
    /// Enable the use of wide cameras (e.g., .builtInTripleCamera, .builtInDualWideCamera, .builtInDualCamera).
    /// Only available on iOS 13.0 and higher, defaults to false.
    @available(iOS 13.0, *)
    public var enableWideCameras: Bool {
        get {
            return dgc__enableWideCameras
        }
        set {
            dgc__enableWideCameras = newValue
        }
    }
    
    /// Overlay view to be displayed on top of the camera view.
    /// User interaction is disabled for this view.
    public var overlayView: UIView? {
        didSet {
            overlayView?.isUserInteractionEnabled = false
        }
    }
    
    /// Video stabilization mode. Defaults to .off.
    public var videoStabilizationMode: AVCaptureVideoStabilizationMode = .off
    
    /// Video export format for recording video and editing video. Defaults to mov.
    public var videoExportType: DGCZLCameraConfiguration.DGCVideoExportType = .mov
    
    /// The default camera position after entering the camera. Defaults to back.
    public var devicePosition: DGCZLCameraConfiguration.DGCDevicePosition = .back
    
    private var dgc_pri_videoCodecType: Any?
    /// The codecs for video capture. Defaults to .h264
    @available(iOS 11.0, *)
    public var videoCodecType: AVVideoCodecType {
        get {
            (dgc_pri_videoCodecType as? AVVideoCodecType) ?? .h264
        }
        set {
            dgc_pri_videoCodecType = newValue
        }
    }
    
    /// Optional lock for output orientation. If set, any video/photo output will use this orientation.
    public var lockedOutputOrientation: AVCaptureVideoOrientation? = nil
}

public extension DGCZLCameraConfiguration {
    @objc enum DGCCaptureSessionPreset: Int {
        var avSessionPreset: AVCaptureSession.Preset {
            switch self {
            case .cif352x288:
                return .cif352x288
            case .vga640x480:
                return .vga640x480
            case .hd1280x720:
                return .hd1280x720
            case .hd1920x1080:
                return .hd1920x1080
            case .hd4K3840x2160:
                return .hd4K3840x2160
            case .photo:
                return .photo
            }
        }
        
        case cif352x288
        case vga640x480
        case hd1280x720
        case hd1920x1080
        case hd4K3840x2160
        case photo
    }
    
    @objc enum DGCFocusMode: Int {
        var avFocusMode: AVCaptureDevice.DGCFocusMode {
            switch self {
            case .autoFocus:
                return .autoFocus
            case .continuousAutoFocus:
                return .continuousAutoFocus
            }
        }
        
        case autoFocus
        case continuousAutoFocus
    }
    
    @objc enum DGCExposureMode: Int {
        var avFocusMode: AVCaptureDevice.DGCExposureMode {
            switch self {
            case .autoExpose:
                return .autoExpose
            case .continuousAutoExposure:
                return .continuousAutoExposure
            }
        }
        
        case autoExpose
        case continuousAutoExposure
    }
    
    @objc enum DGCVideoExportType: Int {
        var format: String {
            switch self {
            case .mov:
                return "mov"
            case .mp4:
                return "mp4"
            }
        }
        
        var avFileType: AVFileType {
            switch self {
            case .mov:
                return .mov
            case .mp4:
                return .mp4
            }
        }
        
        case mov
        case mp4
    }
    
    @objc enum DGCDevicePosition: Int {
        case back
        case front
        
        /// For custom camera
        var avDevicePosition: AVCaptureDevice.Position {
            switch self {
            case .back:
                return .back
            case .front:
                return .front
            }
        }
        
        /// For system camera
        var cameraDevice: UIImagePickerController.CameraDevice {
            switch self {
            case .back:
                return .rear
            case .front:
                return .front
            }
        }
    }
}

// MARK: chaining

public extension DGCZLCameraConfiguration {
    @discardableResult
    func allowTakePhoto(_ value: Bool) -> DGCZLCameraConfiguration {
        allowTakePhoto = value
        return self
    }
    
    @discardableResult
    func allowRecordVideo(_ value: Bool) -> DGCZLCameraConfiguration {
        allowRecordVideo = value
        return self
    }
    
    @discardableResult
    func minRecordDuration(_ duration: DGCZLPhotoConfiguration.Second) -> DGCZLCameraConfiguration {
        minRecordDuration = duration
        return self
    }
    
    @discardableResult
    func maxRecordDuration(_ duration: DGCZLPhotoConfiguration.Second) -> DGCZLCameraConfiguration {
        maxRecordDuration = duration
        return self
    }
    
    @discardableResult
    func sessionPreset(_ sessionPreset: DGCZLCameraConfiguration.DGCCaptureSessionPreset) -> DGCZLCameraConfiguration {
        self.sessionPreset = sessionPreset
        return self
    }
    
    @discardableResult
    func focusMode(_ mode: DGCZLCameraConfiguration.DGCFocusMode) -> DGCZLCameraConfiguration {
        focusMode = mode
        return self
    }
    
    @discardableResult
    func exposureMode(_ mode: DGCZLCameraConfiguration.DGCExposureMode) -> DGCZLCameraConfiguration {
        exposureMode = mode
        return self
    }
    
    @discardableResult
    func showFlashSwitch(_ value: Bool) -> DGCZLCameraConfiguration {
        showFlashSwitch = value
        return self
    }
    
    @discardableResult
    func allowSwitchCamera(_ value: Bool) -> DGCZLCameraConfiguration {
        allowSwitchCamera = value
        return self
    }
    
    @discardableResult
    func videoExportType(_ type: DGCZLCameraConfiguration.DGCVideoExportType) -> DGCZLCameraConfiguration {
        videoExportType = type
        return self
    }
    
    @discardableResult
    func devicePosition(_ position: DGCZLCameraConfiguration.DGCDevicePosition) -> DGCZLCameraConfiguration {
        devicePosition = position
        return self
    }
    
    @available(iOS 11.0, *)
    @discardableResult
    func videoCodecType(_ type: AVVideoCodecType) -> DGCZLCameraConfiguration {
        videoCodecType = type
        return self
    }
    
    @discardableResult
    func tapToRecordVideo(_ value: Bool) -> DGCZLCameraConfiguration {
        tapToRecordVideo = value
        return self
    }
    
    @available(iOS 13.0, *)
    @discardableResult
    func enableWideCameras(_ value: Bool) -> DGCZLCameraConfiguration {
        enableWideCameras = value
        return self
    }
    
    @discardableResult
    func overlayView(_ value: UIView) -> DGCZLCameraConfiguration {
        overlayView = value
        return self
    }
    
    @discardableResult
    func videoStabilizationMode(_ value: AVCaptureVideoStabilizationMode) -> DGCZLCameraConfiguration {
        videoStabilizationMode = value
        return self
    }
    
    @discardableResult
    func lockedOutputOrientation(_ orientation: AVCaptureVideoOrientation?) -> DGCZLCameraConfiguration {
        self.lockedOutputOrientation = orientation
        return self
    }
}
