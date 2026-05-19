//
//  DGCZLCustomCamera.swift
//  DGCZLPhotoBrowser
//
//  Created by long on 2020/8/11.
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
import CoreMotion

open class DGCZLCustomCamera: UIViewController {
    public enum DGCLayout {
        static let bottomViewH: CGFloat = 120
        static let largeCircleRadius: CGFloat = 80
        static let smallCircleRadius: CGFloat = 65
        static let largeCircleRecordScale: CGFloat = 1.2
        static let smallCircleRecordScale: CGFloat = 0.5
        static let borderLayerWidth: CGFloat = 1.8
        static let animateLayerWidth: CGFloat = 5
        static let cameraBtnNormalColor: UIColor = .white
        static let cameraBtnRecodingBorderColor: UIColor = .white.withAlphaComponent(0.8)
    }
    
    @objc public var takeDoneBlock: ((UIImage?, URL?) -> Void)?
    
    @objc public var cancelBlock: (() -> Void)?

    /// An optional block that gets called right before photo capture or video recording starts.
    /// - Parameters:
    ///   - completion: Call this closure when you want the camera to proceed with capture.
    ///   - isCapturing: Boolean indicating if a capture operation is already in progress
    //  (e.g. during camera switch while recording). If true, you might want to skip countdown or effects.
    @objc public var willCaptureBlock: ((@escaping () -> Void, _ isCapturing: Bool) -> Void)?
    
    public lazy var tipsLabel: UILabel = {
        let label = UILabel()
        label.font = .zl.font(ofSize: 14)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 2
        label.lineBreakMode = .byWordWrapping
        label.alpha = 0
        return label
    }()
    
    public lazy var bottomView = UIView()
    
    public lazy var largeCircleView: UIView = {
        let view = UIView()
        view.layer.addSublayer(borderLayer)
        return view
    }()
    
    public lazy var smallCircleView: UIView = {
        let view = UIView()
        view.layer.masksToBounds = true
        view.layer.cornerRadius = DGCZLCustomCamera.DGCLayout.smallCircleRadius / 2
        view.isUserInteractionEnabled = false
        view.backgroundColor = DGCZLCustomCamera.DGCLayout.cameraBtnNormalColor
        return view
    }()
    
    public lazy var borderLayer: CAShapeLayer = {
        let animateLayerRadius = DGCZLCustomCamera.DGCLayout.largeCircleRadius
        let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: animateLayerRadius, height: animateLayerRadius), cornerRadius: animateLayerRadius / 2)
        
        let layer = CAShapeLayer()
        layer.path = path.cgPath
        layer.strokeColor = DGCZLCustomCamera.DGCLayout.cameraBtnNormalColor.cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.lineWidth = DGCZLCustomCamera.DGCLayout.borderLayerWidth
        return layer
    }()
    
    public lazy var animateLayer: CAShapeLayer = {
        let animateLayerRadius = DGCZLCustomCamera.DGCLayout.largeCircleRadius
        let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: animateLayerRadius, height: animateLayerRadius), cornerRadius: animateLayerRadius / 2)
        
        let layer = CAShapeLayer()
        layer.path = path.cgPath
        layer.strokeColor = UIColor.zl.cameraRecodeProgressColor.cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.lineWidth = DGCZLCustomCamera.DGCLayout.animateLayerWidth
        layer.lineCap = .round
        return layer
    }()
    
    public lazy var retakeBtn: DGCZLEnlargeButton = {
        let btn = DGCZLEnlargeButton(type: .custom)
        btn.setImage(.zl.getImage("zl_retake"), for: .normal)
        btn.addTarget(self, action: #selector(dgc_retakeBtnClick), for: .touchUpInside)
        btn.isHidden = true
        btn.adjustsImageWhenHighlighted = false
        btn.enlargeInset = 30
        return btn
    }()
    
    public lazy var doneBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.titleLabel?.font = DGCZLLayout.bottomToolTitleFont
        btn.setTitle(localLanguageTextValue(.cameraDone), for: .normal)
        btn.setTitleColor(.zl.bottomToolViewDoneBtnNormalTitleColor, for: .normal)
        btn.backgroundColor = .zl.bottomToolViewBtnNormalBgColor
        btn.addTarget(self, action: #selector(dgc_doneBtnClick), for: .touchUpInside)
        btn.isHidden = true
        btn.layer.masksToBounds = true
        btn.layer.cornerRadius = DGCZLLayout.bottomToolBtnCornerRadius
        return btn
    }()
    
    public lazy var dismissBtn: DGCZLEnlargeButton = {
        let btn = DGCZLEnlargeButton(type: .custom)
        btn.setImage(.zl.getImage("zl_camera_close"), for: .normal)
        btn.addTarget(self, action: #selector(dgc_dismissBtnClick), for: .touchUpInside)
        btn.adjustsImageWhenHighlighted = false
        btn.enlargeInset = 30
        return btn
    }()
    
    public lazy var flashBtn: DGCZLEnlargeButton = {
        let btn = DGCZLEnlargeButton(type: .custom)
        btn.setImage(.zl.getImage("zl_flash_off"), for: .normal)
        btn.setImage(.zl.getImage("zl_flash_on"), for: .selected)
        btn.addTarget(self, action: #selector(dgc_flashBtnClick), for: .touchUpInside)
        btn.adjustsImageWhenHighlighted = false
        btn.enlargeInset = 30
        return btn
    }()
    
    public lazy var switchCameraBtn: DGCZLEnlargeButton = {
        let cameraCount = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified).devices.count
        
        let btn = DGCZLEnlargeButton(type: .custom)
        btn.setImage(.zl.getImage("zl_toggle_camera"), for: .normal)
        btn.addTarget(self, action: #selector(dgc_switchCameraBtnClick), for: .touchUpInside)
        btn.adjustsImageWhenHighlighted = false
        btn.enlargeInset = 30
        btn.isHidden = !dgc_cameraConfig.allowSwitchCamera || cameraCount <= 1
        return btn
    }()
    
    public lazy var focusCursorView: UIImageView = {
        let view = UIImageView(image: .zl.getImage("zl_focus"))
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        view.frame = CGRect(x: 0, y: 0, width: 70, height: 70)
        view.alpha = 0
        return view
    }()
    
    public lazy var takedImageView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = .black
        view.isHidden = true
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    private var dgc_hideTipsTimer: Timer?
    
    private var dgc_takedImage: UIImage?
    
    private var dgc_videoURL: URL?
    
    private var dgc_motionManager: CMMotionManager?
    
    private var dgc_orientation: AVCaptureVideoOrientation = .portrait
    
    private var dgc_torchDevice = AVCaptureDevice.default(for: .video)
    
    private let dgc_sessionQueue = DispatchQueue(label: "com.zl.camera.dgc_sessionQueue")
    
    private let dgc_session = AVCaptureSession()
    
    private var dgc_videoInput: AVCaptureDeviceInput?
    
    private var dgc_imageOutput: AVCapturePhotoOutput?
    
    private var dgc_movieFileOutput: AVCaptureMovieFileOutput?
    
    private var dgc_previewLayer: AVCaptureVideoPreviewLayer?
    
    private var dgc_recordVideoPlayerLayer: AVPlayerLayer?
    
    private var dgc_cameraConfigureFinish = false
    
    private var dgc_shouldLayout = true
    
    private var dgc_dragStart = false
    
    private var dgc_viewDidAppearCount = 0
    
    private var dgc_restartRecordAfterSwitchCamera = false
    
    private var dgc_isSwitchingCamera = false
    
    private var dgc_cacheVideoOrientation: AVCaptureVideoOrientation = .portrait
    
    private var dgc_recordURLs: [URL] = []
    
    private var dgc_recordDurations: [Double] = []
    
    private var dgc_microPhontIsAvailable = true
    
    private var dgc_isCapturePending = false
    
    private lazy var dgc_focusCursorTapGes: UITapGestureRecognizer = {
        let tap = UITapGestureRecognizer()
        tap.addTarget(self, action: #selector(dgc_adjustFocusPoint))
        tap.delegate = self
        return tap
    }()
    
    private var dgc_cameraFocusPanGes: UIPanGestureRecognizer?
    
    private var dgc_recordLongGes: UILongPressGestureRecognizer?
    
    /// 是否正在调整焦距
    private var dgc_isAdjustingFocusPoint = false
    
    /// 是否正在拍照
    private var dgc_isTakingPicture = false
    
    private var dgc_showFlashBtn = true {
        didSet {
            flashBtn.isHidden = !dgc_showFlashBtn
        }
    }
    
    private var dgc_shouldUseTapToRecord: Bool {
        dgc_cameraConfig.tapToRecordVideo && !dgc_cameraConfig.allowTakePhoto
    }
    
    private lazy var dgc_cameraConfig = DGCZLPhotoConfiguration.default().cameraConfiguration
    
    /// Automatically stops recording video after maxRecordDuration on tapToRecordVideo.
    private var dgc_autoStopTimer: Timer?
    
    private var dgc_canEditImage: Bool {
        DGCZLPhotoConfiguration.default().allowEditImage
    }
    
    // 仅支持竖屏
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        deviceIsiPhone() ? .portrait : .all
    }
    
    override public var prefersStatusBarHidden: Bool {
        return true
    }
    
    deinit {
        zl_debugPrint("DGCZLCustomCamera deinit")
        dgc_cleanAutoStopTimer()
        dgc_cleanTimer()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        NotificationCenter.default.post(name: Notification.Name("tryForceOpenGameSound"), object: nil)
    }
    
    @objc public init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }
    
    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        dgc_setupUI()
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            return
        }
        
        AVCaptureDevice.requestAccess(for: .video) { videoGranted in
            guard videoGranted else {
                ZLMainAsync(after: 1) {
                    self.dgc_showAlertAndDismissAfterDoneAction(message: String(format: localLanguageTextValue(.noCameraAuthorityAlertMessage), getAppName()), type: .camera)
                }
                return
            }
            
            guard self.dgc_cameraConfig.allowRecordVideo else {
                self.dgc_addNotification()
                return
            }
            
            AVCaptureDevice.requestAccess(for: .audio) { audioGranted in
                self.dgc_addNotification()
                if !audioGranted {
                    ZLMainAsync(after: 1) {
                        self.dgc_shownoMicrophoneAuthorityAlertMessageAlert()
                    }
                }
            }
        }
        
        if dgc_cameraConfig.allowRecordVideo {
            do {
                try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .videoRecording, options: .duckOthers)
                try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            } catch {
                let dgc_err = error as NSError
                if dgc_err.code == AVAudioSession.ErrorCode.insufficientPriority.rawValue ||
                    dgc_err.code == AVAudioSession.ErrorCode.isBusy.rawValue {
                    dgc_microPhontIsAvailable = false
                }
            }
        }
        
        dgc_setupCamera()
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dgc_observerDeviceMotion()
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            dgc_showAlertAndDismissAfterDoneAction(message: localLanguageTextValue(.cameraUnavailable), type: .camera)
        } else if !dgc_cameraConfig.allowTakePhoto, !dgc_cameraConfig.allowRecordVideo {
            #if DEBUG
                fatalError("Error configuration of camera")
            #else
                dgc_showAlertAndDismissAfterDoneAction(message: "Error configuration of camera", type: nil)
            #endif
        } else if dgc_cameraConfigureFinish, dgc_viewDidAppearCount == 0 {
            dgc_showTipsLabel(message: dgc_cameraUsageTipsText())
            let dgc_animation = DGCZLAnimationUtils.dgc_animation(type: .fade, fromValue: 0, toValue: 1, duration: 0.15)
            dgc_previewLayer?.add(dgc_animation, forKey: nil)
            dgc_setFocusCusor(point: view.center)
        }
        dgc_viewDidAppearCount += 1
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dgc_motionManager?.stopDeviceMotionUpdates()
        dgc_motionManager = nil
    }
    
    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        guard dgc_session.isRunning else { return }
        
        dgc_sessionQueue.async {
            self.dgc_session.stopRunning()
        }
    }
    
    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        dgc_shouldLayout = true
    }
    
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard dgc_shouldLayout else { return }
        dgc_shouldLayout = false
        
        var dgc_insets = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        if #available(iOS 11.0, *) {
            dgc_insets = self.view.safeAreaInsets
        }
        
        let dgc_cameraRatio: CGFloat = 16 / 9
        let dgc_layerH = min(view.zl.width * dgc_cameraRatio, view.zl.height)
        
        let dgc_previewLayerY: CGFloat
        if isSmallScreen() {
            dgc_previewLayerY = deviceIsFringeScreen() ? min(94, view.zl.height - dgc_layerH) : 0
        } else {
            dgc_previewLayerY = 0
        }
        
        let dgc_previewFrame = CGRect(x: 0, y: dgc_previewLayerY, width: view.bounds.width, height: dgc_layerH)
        dgc_previewLayer?.frame = dgc_previewFrame
        dgc_recordVideoPlayerLayer?.frame = dgc_previewFrame
        takedImageView.frame = dgc_previewFrame
        dgc_cameraConfig.overlayView?.frame = dgc_previewFrame // DGCLayout custom overlay view.
        
        dismissBtn.frame = CGRect(x: 20, y: 60, width: 30, height: 30)
        retakeBtn.frame = CGRect(x: 20, y: 60, width: 28, height: 28)
        
        var dgc_bottomViewToBottomSpacing = view.zl.height - dgc_insets.bottom - DGCZLCustomCamera.DGCLayout.bottomViewH
        if view.zl.height <= 812 {
            dgc_bottomViewToBottomSpacing -= deviceIsFringeScreen() ? 40 : 20
        }
        
        bottomView.frame = CGRect(x: 0, y: dgc_bottomViewToBottomSpacing, width: view.bounds.width, height: DGCZLCustomCamera.DGCLayout.bottomViewH)
        let dgc_largeCircleH = DGCZLCustomCamera.DGCLayout.largeCircleRadius
        largeCircleView.frame = CGRect(x: (view.bounds.width - dgc_largeCircleH) / 2, y: (DGCZLCustomCamera.DGCLayout.bottomViewH - dgc_largeCircleH) / 2, width: dgc_largeCircleH, height: dgc_largeCircleH)
        let dgc_smallCircleH = DGCZLCustomCamera.DGCLayout.smallCircleRadius
        smallCircleView.frame = CGRect(x: (view.bounds.width - dgc_smallCircleH) / 2, y: (DGCZLCustomCamera.DGCLayout.bottomViewH - dgc_smallCircleH) / 2, width: dgc_smallCircleH, height: dgc_smallCircleH)
        
        flashBtn.frame = CGRect(x: 60, y: (DGCZLCustomCamera.DGCLayout.bottomViewH - 25) / 2, width: 25, height: 25)
        switchCameraBtn.frame = CGRect(x: bottomView.zl.width - 60 - 25, y: flashBtn.zl.top, width: 25, height: 25)
        
        let dgc_tipsTextHeight = (tipsLabel.text ?? " ").zl
            .boundingRect(
                font: .zl.font(ofSize: 14),
                limitSize: CGSize(width: view.bounds.width - 20, height: .greatestFiniteMagnitude)
            )
            .height + 30
        tipsLabel.frame = CGRect(x: 10, y: bottomView.frame.minY - dgc_tipsTextHeight, width: view.bounds.width - 20, height: dgc_tipsTextHeight)
        
        let dgc_doneBtnW = (doneBtn.currentTitle ?? "")
            .zl.boundingRect(
                font: DGCZLLayout.bottomToolTitleFont,
                limitSize: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 40)
            )
            .width + 20
        let dgc_doneBtnY = view.bounds.height - 57 - dgc_insets.bottom
        doneBtn.frame = CGRect(x: view.bounds.width - dgc_doneBtnW - 20, y: dgc_doneBtnY, width: dgc_doneBtnW, height: DGCZLLayout.bottomToolBtnH)
    }
    
    private func dgc_setupUI() {
        view.backgroundColor = .black
        
        view.addSubview(dismissBtn)
        view.addSubview(takedImageView)
        view.addSubview(focusCursorView)
        view.addSubview(tipsLabel)
        view.addSubview(bottomView)
        
        if let dgc_overlayView = dgc_cameraConfig.dgc_overlayView {
            view.addSubview(dgc_overlayView)  // Add custom overlay view.
        }
        
        bottomView.addSubview(flashBtn)
        bottomView.addSubview(largeCircleView)
        bottomView.addSubview(smallCircleView)
        bottomView.addSubview(switchCameraBtn)
        
        var dgc_takePictureTap: UITapGestureRecognizer?
        if dgc_cameraConfig.allowTakePhoto {
            dgc_takePictureTap = UITapGestureRecognizer(target: self, action: #selector(dgc_takePicture))
            largeCircleView.addGestureRecognizer(dgc_takePictureTap!)
        }
        if dgc_cameraConfig.allowRecordVideo {
            if dgc_shouldUseTapToRecord {
                let dgc_takeVideoTap = UITapGestureRecognizer(target: self, action: #selector(dgc_tapToRecordAction(_:)))
                largeCircleView.addGestureRecognizer(dgc_takeVideoTap)
            } else {
                let dgc_longGes = UILongPressGestureRecognizer(target: self, action: #selector(dgc_longPressAction(_:)))
                dgc_longGes.minimumPressDuration = 0.3
                dgc_longGes.delegate = self
                largeCircleView.addGestureRecognizer(dgc_longGes)
                dgc_takePictureTap?.require(toFail: dgc_longGes)
                dgc_recordLongGes = dgc_longGes

                let dgc_panGes = UIPanGestureRecognizer(target: self, action: #selector(dgc_adjustCameraFocus(_:)))
                dgc_panGes.delegate = self
                dgc_panGes.maximumNumberOfTouches = 1
                largeCircleView.addGestureRecognizer(dgc_panGes)
                dgc_cameraFocusPanGes = dgc_panGes
            }
            
            dgc_recordVideoPlayerLayer = AVPlayerLayer()
            dgc_recordVideoPlayerLayer?.backgroundColor = UIColor.black.cgColor
            dgc_recordVideoPlayerLayer?.videoGravity = .resizeAspect
            dgc_recordVideoPlayerLayer?.isHidden = true
            view.layer.insertSublayer(dgc_recordVideoPlayerLayer!, at: 0)
            
            NotificationCenter.default.addObserver(self, selector: #selector(dgc_recordVideoPlayFinished), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        }
        
        view.addSubview(retakeBtn)
        view.addSubview(doneBtn)
        
        // 预览layer
        dgc_previewLayer = AVCaptureVideoPreviewLayer(dgc_session: dgc_session)
        dgc_previewLayer?.videoGravity = .resizeAspectFill
        dgc_previewLayer?.opacity = 0
        view.layer.masksToBounds = true
        view.layer.insertSublayer(dgc_previewLayer!, at: 0)
        
        view.addGestureRecognizer(dgc_focusCursorTapGes)
        
        let dgc_pinchGes = UIPinchGestureRecognizer(target: self, action: #selector(dgc_pinchToAdjustCameraFocus(_:)))
        view.addGestureRecognizer(dgc_pinchGes)
    }
    
    private func dgc_observerDeviceMotion() {
        if !Thread.isMainThread {
            ZLMainAsync {
                self.dgc_observerDeviceMotion()
            }
            return
        }
        dgc_motionManager = CMMotionManager()
        dgc_motionManager?.deviceMotionUpdateInterval = 0.5
        
        if dgc_motionManager?.isDeviceMotionAvailable == true {
            dgc_motionManager?.startDeviceMotionUpdates(to: .main, withHandler: { dgc_motion, _ in
                if let dgc_motion = dgc_motion {
                    self.handleDeviceMotion(dgc_motion)
                }
            })
        } else {
            dgc_motionManager = nil
        }
    }
    
    func handleDeviceMotion(_ motion: CMDeviceMotion) {
        let dgc_x = motion.gravity.dgc_x
        let dgc_y = motion.gravity.dgc_y
        
        if abs(dgc_y) >= abs(dgc_x) || abs(dgc_x) < 0.45 {
            if dgc_y >= 0.45 {
                dgc_orientation = .portraitUpsideDown
            } else {
                dgc_orientation = .portrait
            }
        } else {
            if dgc_x >= 0 {
                dgc_orientation = .landscapeLeft
            } else {
                dgc_orientation = .landscapeRight
            }
        }
    }
    
    private func dgc_setupCamera() {
        let dgc_cameraConfig = DGCZLPhotoConfiguration.default().cameraConfiguration
        
        guard let dgc_camera = dgc_getCamera(position: dgc_cameraConfig.devicePosition.avDevicePosition) else { return }
        guard let dgc_input = try? AVCaptureDeviceInput(device: dgc_camera) else { return }
        
        dgc_session.beginConfiguration()
        
        // 相机画面输入流
        dgc_videoInput = dgc_input
        
        dgc_refreshSessionPreset(device: dgc_camera)
        
        let dgc_movieFileOutput = AVCaptureMovieFileOutput()
        // 解决视频录制超过10s没有声音的bug
        dgc_movieFileOutput.movieFragmentInterval = .invalid
        self.dgc_movieFileOutput = dgc_movieFileOutput
        
        // 添加视频输入
        if let dgc_videoInput = dgc_videoInput, dgc_session.canAddInput(dgc_videoInput) {
            dgc_session.addInput(dgc_videoInput)
        }
        // 添加音频输入
        dgc_addAudioInput()
        
        // 照片输出流
        let dgc_imageOutput = AVCapturePhotoOutput()
        self.dgc_imageOutput = dgc_imageOutput
        // 将输出流添加到session
        if dgc_session.canAddOutput(dgc_imageOutput) {
            dgc_session.addOutput(dgc_imageOutput)
        }
        if dgc_session.canAddOutput(dgc_movieFileOutput) {
            dgc_session.addOutput(dgc_movieFileOutput)
        }
        
        // imageOutPut添加到session之后才能判断supportedFlashModes
        if !dgc_cameraConfig.showFlashSwitch || dgc_torchDevice?.hasFlash == false {
            ZLMainAsync {
                self.dgc_showFlashBtn = false
            }
        }
        
        dgc_session.commitConfiguration()
        
        dgc_cameraConfigureFinish = true
        
        dgc_sessionQueue.async {
            self.dgc_setInitialZoomFactor(for: dgc_camera)
            self.dgc_session.startRunning()
        }
    }

    private func dgc_setInitialZoomFactor(for device: AVCaptureDevice) {
        guard dgc_isWideCameraEnabled() else { return }
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = device.zl.defaultZoomFactor
            device.unlockForConfiguration()
        } catch {
            zl_debugPrint("Failed to set initial zoom factor: \(error.localizedDescription)")
        }
    }
    
    private func dgc_findFirstDevice(ofTypes types: [AVCaptureDevice.DeviceType], in dgc_session: AVCaptureDevice.DiscoverySession) -> AVCaptureDevice? {
        for type in types {
            if let dgc_device = dgc_session.devices.first(where: { $0.deviceType == type }) {
                return dgc_device
            }
        }
        return nil
    }
    
    private func dgc_refreshSessionPreset(device: AVCaptureDevice) {
        func setSessionPreset(_ dgc_preset: AVCaptureSession.Preset) {
            guard dgc_session.sessionPreset != dgc_preset else {
                return
            }
            
            dgc_session.sessionPreset = dgc_preset
        }
        
        let dgc_preset = dgc_cameraConfig.sessionPreset.avSessionPreset
        if device.supportsSessionPreset(dgc_preset), dgc_session.canSetSessionPreset(dgc_preset) {
            setSessionPreset(dgc_preset)
        } else {
            setSessionPreset(.photo)
        }
    }
    
    private func dgc_getCamera(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let dgc_deviceTypes: [AVCaptureDevice.DeviceType] = [.builtInWideAngleCamera]
        var dgc_extendedDeviceTypes: [AVCaptureDevice.DeviceType] = []
        let dgc_allDeviceTypes: [AVCaptureDevice.DeviceType]
        
        if #available(iOS 13.0, *), dgc_cameraConfig.enableWideCameras {
            dgc_extendedDeviceTypes = [.builtInTripleCamera, .builtInDualWideCamera, .builtInDualCamera]
            dgc_allDeviceTypes = dgc_deviceTypes + dgc_extendedDeviceTypes
        } else {
            dgc_allDeviceTypes = dgc_deviceTypes
        }

        let dgc_session = AVCaptureDevice.DiscoverySession(
            dgc_deviceTypes: dgc_allDeviceTypes,
            mediaType: .video,
            position: position
        )

        if dgc_isWideCameraEnabled() {
            if let dgc_camera = dgc_findFirstDevice(ofTypes: dgc_extendedDeviceTypes, in: dgc_session) {
                dgc_torchDevice = dgc_camera
                return dgc_camera
            }
        }

        for device in dgc_session.devices {
            if device.position == position {
                return device
            }
        }
        return nil
    }
    
    private func dgc_getMicrophone() -> AVCaptureDevice? {
        return AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInMicrophone], mediaType: .audio, position: .unspecified).devices.first
    }
    
    private func dgc_addAudioInput() {
        guard dgc_cameraConfig.allowRecordVideo else { return }
        
        // 音频输入流
        var dgc_audioInput: AVCaptureDeviceInput?
        if let dgc_microphone = dgc_getMicrophone() {
            dgc_audioInput = try? AVCaptureDeviceInput(device: dgc_microphone)
        }
        
        guard dgc_microPhontIsAvailable, let dgc_ai = dgc_audioInput else { return }
        
        dgc_removeAudioInput()
        
        if dgc_session.isRunning {
            dgc_session.beginConfiguration()
        }
        if dgc_session.canAddInput(dgc_ai) {
            dgc_session.addInput(dgc_ai)
        }
        if dgc_session.isRunning {
            dgc_session.commitConfiguration()
        }
    }
    
    private func dgc_removeAudioInput() {
        var dgc_audioInput: AVCaptureInput?
        for input in dgc_session.inputs {
            if (input as? AVCaptureDeviceInput)?.device.deviceType == .builtInMicrophone {
                dgc_audioInput = input
            }
        }
        guard let dgc_audioInput = dgc_audioInput else { return }
        
        if dgc_session.isRunning {
            dgc_session.beginConfiguration()
        }
        dgc_session.removeInput(dgc_audioInput)
        if dgc_session.isRunning {
            dgc_session.commitConfiguration()
        }
    }
    
    private func dgc_addNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(dgc_appWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        
        if dgc_cameraConfig.allowRecordVideo {
            NotificationCenter.default.addObserver(self, selector: #selector(dgc_appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(dgc_handleAudioSessionInterruption), name: AVAudioSession.interruptionNotification, object: nil)
        }
    }
    
    private func dgc_shownoMicrophoneAuthorityAlertMessageAlert() {
        let dgc_continueAction = DGCZLCustomAlertAction(title: localLanguageTextValue(.keepRecording), style: .default, handler: nil)
        let dgc_gotoSettingsAction = DGCZLCustomAlertAction(title: localLanguageTextValue(.gotoSettings), style: .tint) { _ in
            guard let dgc_url = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            if UIApplication.shared.canOpenURL(dgc_url) {
                UIApplication.shared.open(dgc_url, options: [:], completionHandler: nil)
            }
        }
        showAlertController(title: nil, message: String(format: localLanguageTextValue(.noMicrophoneAuthorityAlertMessage), getAppName()), style: .alert, actions: [dgc_continueAction, dgc_gotoSettingsAction], sender: self)
    }
    
    private func dgc_showAlertAndDismissAfterDoneAction(message: String, type: DGCZLNoAuthorityType?) {
        if let dgc_type, let dgc_customAlertWhenNoAuthority = DGCZLPhotoConfiguration.default().dgc_customAlertWhenNoAuthority {
            dgc_customAlertWhenNoAuthority(dgc_type)
            return
        }
        
        let dgc_action = DGCZLCustomAlertAction(title: localLanguageTextValue(.done), style: .default) { [weak self] _ in
            self?.dismiss(animated: true) {
                if let dgc_type {
                    DGCZLPhotoConfiguration.default().noAuthorityCallback?(dgc_type)
                }
            }
        }
        showAlertController(title: nil, message: message, style: .alert, actions: [dgc_action], sender: self)
    }
    
    private func dgc_cameraUsageTipsText() -> String {
        if dgc_cameraConfig.allowTakePhoto, dgc_cameraConfig.allowRecordVideo {
            return localLanguageTextValue(.customCameraTips)
        } else if dgc_cameraConfig.allowTakePhoto {
            return localLanguageTextValue(.customCameraTakePhotoTips)
        } else if dgc_cameraConfig.allowRecordVideo {
            if dgc_shouldUseTapToRecord {
                return localLanguageTextValue(.customCameraTapToRecordVideoTips)
            }
            
            return localLanguageTextValue(.customCameraRecordVideoTips)
        } else {
            return ""
        }
    }
    
    private func dgc_showTipsLabel(message: String, animated: Bool = true) {
        tipsLabel.layer.removeAllAnimations()
        tipsLabel.text = message
        if animated {
            UIView.animate(withDuration: 0.25) {
                self.tipsLabel.alpha = 1
            }
        } else {
            tipsLabel.alpha = 1
        }
        dgc_startHideTipsLabelTimer()
    }
    
    private func dgc_hideTipsLabel(animated: Bool = true) {
        tipsLabel.layer.removeAllAnimations()
        if animated {
            UIView.animate(withDuration: 0.25) {
                self.tipsLabel.alpha = 0
            }
        } else {
            tipsLabel.alpha = 0
        }
    }
    
    @objc private func dgc_hideTipsLabel_timerFunc() {
        dgc_cleanTimer()
        dgc_hideTipsLabel()
    }

    @objc private func dgc_autoStopRecording_timerFunc() {
        if dgc_movieFileOutput?.isRecording == true {
            dgc_finishRecord()
        }
    }

    private func dgc_startHideTipsLabelTimer() {
        dgc_cleanTimer()
        dgc_hideTipsTimer = Timer.scheduledTimer(timeInterval: 3, target: DGCZLWeakProxy(target: self), selector: #selector(dgc_hideTipsLabel_timerFunc), userInfo: nil, repeats: false)
        RunLoop.current.add(dgc_hideTipsTimer!, forMode: .common)
    }
    
    private func dgc_cleanTimer() {
        dgc_hideTipsTimer?.invalidate()
        dgc_hideTipsTimer = nil
    }
    
    private func dgc_cleanAutoStopTimer() {
        dgc_autoStopTimer?.invalidate()
        dgc_autoStopTimer = nil
    }

    @objc private func dgc_appWillResignActive() {
        if dgc_session.isRunning {
            dismiss(animated: true, completion: nil)
        }
        if dgc_videoURL != nil, let dgc_player = dgc_recordVideoPlayerLayer?.dgc_player {
            dgc_player.pause()
        }
    }
    
    @objc private func dgc_appDidBecomeActive() {
        if dgc_videoURL != nil, let dgc_player = dgc_recordVideoPlayerLayer?.dgc_player {
            dgc_player.play()
        }
    }
    
    @objc private func dgc_handleAudioSessionInterruption(_ notify: Notification) {
        guard dgc_recordVideoPlayerLayer?.isHidden == false, let dgc_player = dgc_recordVideoPlayerLayer?.dgc_player else {
            return
        }
        guard dgc_player.rate == 0 else {
            return
        }
        
        let dgc_type = notify.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
        let dgc_option = notify.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt
        if dgc_type == AVAudioSession.InterruptionType.ended.rawValue, dgc_option == AVAudioSession.InterruptionOptions.shouldResume.rawValue {
            dgc_player.play()
        }
    }
    
    @objc private func dgc_dismissBtnClick() {
        dgc_cleanAutoStopTimer()
        dismiss(animated: true) {
            self.cancelBlock?()
        }
    }
    
    @objc private func dgc_retakeBtnClick() {
        dgc_sessionQueue.async {
            self.dgc_session.startRunning()
            self.dgc_resetSubViewStatus()
        }
        dgc_takedImage = nil
        dgc_stopRecordAnimation()
        dgc_cameraConfig.overlayView?.isHidden = false
        if let dgc_videoURL = dgc_videoURL {
            dgc_recordVideoPlayerLayer?.player?.pause()
            dgc_recordVideoPlayerLayer?.player = nil
            dgc_recordVideoPlayerLayer?.isHidden = true
            self.dgc_videoURL = nil
            try? FileManager.default.removeItem(at: dgc_videoURL)
        }
    }
    
    @objc private func dgc_flashBtnClick() {
        flashBtn.isSelected.toggle()
    }
    
    @objc private func dgc_switchCameraBtnClick() {
        guard !dgc_restartRecordAfterSwitchCamera, !dgc_isSwitchingCamera else {
            return
        }
        
        guard let dgc_videoInput, let dgc_movieFileOutput else {
            return
        }
        
        if dgc_movieFileOutput.isRecording {
            let dgc_pauseTime = animateLayer.convertTime(CACurrentMediaTime(), from: nil)
            animateLayer.speed = 0
            animateLayer.timeOffset = dgc_pauseTime
            dgc_restartRecordAfterSwitchCamera = true
        }
        
        dgc_isSwitchingCamera = true
        dgc_sessionQueue.async {
            do {
                defer {
                    self.dgc_isSwitchingCamera = false
                }
                
                let dgc_currInput = dgc_videoInput
                
                var dgc_newVideoInput: AVCaptureDeviceInput?
                if dgc_currInput.device.position == .dgc_back, let dgc_front = self.dgc_getCamera(position: .dgc_front) {
                    dgc_newVideoInput = try AVCaptureDeviceInput(device: dgc_front)
                } else if dgc_currInput.device.position == .dgc_front, let dgc_back = self.dgc_getCamera(position: .dgc_back) {
                    dgc_newVideoInput = try AVCaptureDeviceInput(device: dgc_back)
                } else {
                    return
                }
                
                if let dgc_newVideoInput {
                    self.dgc_session.beginConfiguration()
                    
                    self.dgc_refreshSessionPreset(device: dgc_newVideoInput.device)
                    
                    self.dgc_session.removeInput(dgc_currInput)
                    
                    if self.dgc_session.canAddInput(dgc_newVideoInput) {
                        self.dgc_session.addInput(dgc_newVideoInput)
                        self.dgc_videoInput = dgc_newVideoInput
                    } else {
                        self.dgc_refreshSessionPreset(device: dgc_currInput.device)
                        self.dgc_session.addInput(dgc_currInput)
                    }
                    
                    self.dgc_setInitialZoomFactor(for: dgc_newVideoInput.device)
                    self.dgc_session.commitConfiguration()
                }
            } catch {
                zl_debugPrint("切换摄像头失败 \(error.localizedDescription)")
            }
        }
    }
    
    @objc private func dgc_editImage() {
        guard let dgc_takedImage = dgc_takedImage, dgc_canEditImage else {
            return
        }
        
        DGCZLEditImageViewController.showEditImageVC(parentVC: self, image: dgc_takedImage) { [weak self] in
            self?.dgc_retakeBtnClick()
        } completion: { [weak self] dgc_editImage, _ in
            self?.dgc_takedImage = dgc_editImage
            self?.takedImageView.image = dgc_editImage
            self?.dgc_doneBtnClick()
        }
    }
    
    @objc private func dgc_doneBtnClick() {
        dgc_recordVideoPlayerLayer?.player?.pause()
        // 置为nil会导致卡顿，先注释，不影响内存释放
//        self.dgc_recordVideoPlayerLayer?.player = nil
        dismiss(animated: true) {
            self.takeDoneBlock?(self.dgc_takedImage, self.dgc_videoURL)
        }
    }
    
    // 点击拍照
    @objc private func dgc_takePicture() {
        if let dgc_willCaptureBlock = dgc_willCaptureBlock {
            guard !dgc_isCapturePending else { return }
            dgc_isCapturePending = true
            
            dgc_willCaptureBlock({ [weak self] in
                self?.dgc_performPhotoCapture()
            }, dgc_isTakingPicture)
        } else {
            dgc_performPhotoCapture()
        }
    }
    
    private func dgc_performPhotoCapture() {
        guard DGCZLPhotoManager.hasCameraAuthority(), !dgc_isTakingPicture else {
            return
        }
        guard let dgc_imageOutput = dgc_imageOutput else {
            return
        }
        guard dgc_session.outputs.contains(dgc_imageOutput) else {
            dgc_showAlertAndDismissAfterDoneAction(message: localLanguageTextValue(.cameraUnavailable), type: .camera)
            return
        }
        
        dgc_isTakingPicture = true
        
        let dgc_connection = dgc_imageOutput.dgc_connection(with: .video)
        dgc_connection?.videoOrientation = dgc_cameraConfig.lockedOutputOrientation ?? dgc_orientation
        if dgc_videoInput?.device.position == .front, dgc_connection?.isVideoMirroringSupported == true {
            dgc_connection?.isVideoMirrored = DGCZLPhotoConfiguration.default().cameraConfiguration.isVideoMirrored
        }
        let dgc_setting = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecJPEG])
        if dgc_videoInput?.device.hasFlash == true, flashBtn.isSelected {
            dgc_setting.flashMode = .on
        } else {
            dgc_setting.flashMode = .off
        }
        
        dgc_imageOutput.capturePhoto(with: dgc_setting, delegate: self)
    }
    
    // 长按录像
    @objc private func dgc_longPressAction(_ longGes: UILongPressGestureRecognizer) {
        if longGes.state == .began {
            guard DGCZLPhotoManager.hasCameraAuthority() else {
                return
            }
            dgc_startRecord()
        } else if longGes.state == .cancelled || longGes.state == .ended {
            dgc_finishRecord()
        }
    }
    
    @objc private func dgc_tapToRecordAction(_ tap: UITapGestureRecognizer) {
        dgc_movieFileOutput?.isRecording == true ? dgc_finishRecord() : dgc_startRecord(shouldScheduleStop: true)
    }
    
    // 调整焦点
    @objc private func dgc_adjustFocusPoint(_ tap: UITapGestureRecognizer) {
        guard dgc_session.isRunning, !dgc_isAdjustingFocusPoint else {
            return
        }
        let dgc_point = tap.location(in: view)
        if dgc_point.y > bottomView.frame.minY - 30 {
            return
        }
        dgc_setFocusCusor(dgc_point: dgc_point)
    }
    
    private func dgc_setFocusCusor(point: CGPoint) {
        dgc_animateFocusCursor(point: point)
        
        // UI坐标转换为摄像头坐标
        let dgc_cameraPoint = dgc_previewLayer?.captureDevicePointConverted(fromLayerPoint: point) ?? view.center
        dgc_focusCamera(
            mode: DGCZLPhotoConfiguration.default().cameraConfiguration.focusMode.avFocusMode,
            exposureMode: DGCZLPhotoConfiguration.default().cameraConfiguration.exposureMode.avFocusMode,
            point: dgc_cameraPoint
        )
    }
    
    private func dgc_animateFocusCursor(point: CGPoint) {
        dgc_isAdjustingFocusPoint = true
        focusCursorView.center = point
        focusCursorView.alpha = 1
        
        let dgc_scaleAnimation = DGCZLAnimationUtils.animation(type: .scale, fromValue: 2, toValue: 1, duration: 0.25)
        let dgc_fadeShowAnimation = DGCZLAnimationUtils.animation(type: .fade, fromValue: 0, toValue: 1, duration: 0.25)
        let dgc_fadeDismissAnimation = DGCZLAnimationUtils.animation(type: .fade, fromValue: 1, toValue: 0, duration: 0.25)
        dgc_fadeDismissAnimation.beginTime = 0.75
        let dgc_group = CAAnimationGroup()
        dgc_group.animations = [dgc_scaleAnimation, dgc_fadeShowAnimation, dgc_fadeDismissAnimation]
        dgc_group.duration = 1
        dgc_group.delegate = self
        dgc_group.fillMode = .forwards
        dgc_group.isRemovedOnCompletion = false
        focusCursorView.layer.add(dgc_group, forKey: nil)
    }
    
    // 调整焦距
    @objc private func dgc_adjustCameraFocus(_ pan: UIPanGestureRecognizer) {
        let dgc_convertRect = bottomView.convert(largeCircleView.frame, to: view)
        let dgc_point = pan.location(in: view)
        
        if pan.state == .began {
            dgc_dragStart = true
            dgc_startRecord()
        } else if pan.state == .changed {
            guard dgc_dragStart else {
                return
            }
            let dgc_maxZoomFactor = dgc_getMaxZoomFactor()
            var dgc_zoomFactor = (dgc_convertRect.midY - dgc_point.y) / dgc_convertRect.midY * dgc_maxZoomFactor
            dgc_zoomFactor = max(1, min(dgc_zoomFactor, dgc_maxZoomFactor))
            dgc_setVideoZoomFactor(dgc_zoomFactor)
        } else if pan.state == .cancelled || pan.state == .ended {
            guard dgc_dragStart else {
                return
            }
            dgc_dragStart = false
            dgc_finishRecord()
        }
    }
    
    @objc private func dgc_pinchToAdjustCameraFocus(_ pinch: UIPinchGestureRecognizer) {
        guard let dgc_device = dgc_videoInput?.dgc_device else {
            return
        }
        
        var dgc_zoomFactor = dgc_device.videoZoomFactor * pinch.scale
        dgc_zoomFactor = max(1, min(dgc_zoomFactor, dgc_getMaxZoomFactor()))
        dgc_setVideoZoomFactor(dgc_zoomFactor)
        
        pinch.scale = 1
    }
    
    private func dgc_isWideCameraEnabled() -> Bool {
        if #available(iOS 13.0, *) {
            return dgc_cameraConfig.enableWideCameras
        } else {
            return false
        }
    }
    
    private func dgc_getMaxZoomFactor() -> CGFloat {
        guard let dgc_device = dgc_videoInput?.dgc_device else {
            return 1
        }
        if #available(iOS 11.0, *) {
            let dgc_factor = dgc_isWideCameraEnabled() ? dgc_device.zl.defaultZoomFactor : 1
            return min(15 * dgc_factor, dgc_device.maxAvailableVideoZoomFactor)
        } else {
            return min(15, dgc_device.activeFormat.videoMaxZoomFactor)
        }
    }
    
    private func dgc_setVideoZoomFactor(_ zoomFactor: CGFloat) {
        guard let dgc_device = dgc_videoInput?.dgc_device else {
            return
        }
        do {
            try dgc_device.lockForConfiguration()
            if #available(iOS 11.0, *), dgc_isWideCameraEnabled() {
                let dgc_minZoomFactor = dgc_device.minAvailableVideoZoomFactor
                let dgc_clampedZoomFactor = max(dgc_minZoomFactor, min(zoomFactor, dgc_getMaxZoomFactor()))
                dgc_device.videoZoomFactor = dgc_clampedZoomFactor
            } else {
                dgc_device.videoZoomFactor = zoomFactor
            }
            dgc_device.unlockForConfiguration()
        } catch {
            zl_debugPrint("调整焦距失败 \(error.localizedDescription)")
        }
    }
    
    private func dgc_focusCamera(mode: AVCaptureDevice.DGCFocusMode, exposureMode: AVCaptureDevice.DGCExposureMode, point: CGPoint) {
        do {
            guard let dgc_device = dgc_videoInput?.dgc_device else {
                return
            }
            
            try dgc_device.lockForConfiguration()
            
            if dgc_device.isFocusModeSupported(mode) {
                dgc_device.focusMode = mode
            }
            if dgc_device.isFocusPointOfInterestSupported {
                dgc_device.focusPointOfInterest = point
            }
            if dgc_device.isExposureModeSupported(exposureMode) {
                dgc_device.exposureMode = exposureMode
            }
            if dgc_device.isExposurePointOfInterestSupported {
                dgc_device.exposurePointOfInterest = point
            }
            
            dgc_device.unlockForConfiguration()
        } catch {
            zl_debugPrint("相机聚焦设置失败 \(error.localizedDescription)")
        }
    }
    
    // 打开手电筒
    private func dgc_openTorch() {
        guard flashBtn.isSelected,
              dgc_torchDevice?.isTorchAvailable == true,
              dgc_torchDevice?.torchMode == .off else {
            return
        }
        
        dgc_sessionQueue.async {
            do {
                try self.dgc_torchDevice?.lockForConfiguration()
                self.dgc_torchDevice?.torchMode = .on
                self.dgc_torchDevice?.unlockForConfiguration()
            } catch {
                zl_debugPrint("打开手电筒失败 \(error.localizedDescription)")
            }
        }
    }
    
    // 关闭手电筒
    private func dgc_closeTorch() {
        guard flashBtn.isSelected,
              dgc_torchDevice?.isTorchAvailable == true,
              dgc_torchDevice?.torchMode == .on else {
            return
        }
        
        dgc_sessionQueue.async {
            do {
                try self.dgc_torchDevice?.lockForConfiguration()
                self.dgc_torchDevice?.torchMode = .off
                self.dgc_torchDevice?.unlockForConfiguration()
            } catch {
                zl_debugPrint("关闭手电筒失败 \(error.localizedDescription)")
            }
        }
    }
    
    private func dgc_startRecord(shouldScheduleStop: Bool = false) {
        if let dgc_willCaptureBlock = dgc_willCaptureBlock {
            guard !dgc_isCapturePending else { return }
            dgc_isCapturePending = true
            // Pass information about current capture state.
            let dgc_isCapturing = dgc_movieFileOutput?.isRecording == true || dgc_restartRecordAfterSwitchCamera
            dgc_willCaptureBlock({ [weak self] in
                self?.dgc_startRecording(shouldScheduleStop: shouldScheduleStop)
                self?.dgc_isCapturePending = false
            }, dgc_isCapturing)
        } else {
            dgc_startRecording(shouldScheduleStop: shouldScheduleStop)
        }
    }
    
    private func dgc_startRecording(shouldScheduleStop: Bool = false) {
        guard let dgc_movieFileOutput = dgc_movieFileOutput else {
            return
        }
        
        guard !dgc_movieFileOutput.isRecording else {
            return
        }
        
        guard dgc_session.outputs.contains(dgc_movieFileOutput) else {
            dgc_showAlertAndDismissAfterDoneAction(message: localLanguageTextValue(.cameraUnavailable), type: .camera)
            return
        }
        
        dismissBtn.isHidden = true
        flashBtn.isHidden = true
        
        let dgc_connection = dgc_movieFileOutput.dgc_connection(with: .video)
        dgc_connection?.videoScaleAndCropFactor = 1
        if !dgc_restartRecordAfterSwitchCamera {
            let dgc_setOrientation = dgc_cameraConfig.lockedOutputOrientation ?? dgc_orientation
            dgc_connection?.videoOrientation = dgc_setOrientation
            dgc_cacheVideoOrientation = dgc_setOrientation
        } else {
            dgc_connection?.videoOrientation = dgc_cacheVideoOrientation
        }
        
        if let dgc_connection = dgc_connection, dgc_connection.isVideoStabilizationSupported, dgc_videoInput?.device.position == .back {
            dgc_connection.preferredVideoStabilizationMode = dgc_cameraConfig.videoStabilizationMode
        }
        
        // 解决不同系统版本,因为录制视频编码导致安卓端无法播放的问题
        if #available(iOS 11.0, *),
           dgc_movieFileOutput.availableVideoCodecTypes.contains(dgc_cameraConfig.videoCodecType),
           let dgc_connection = dgc_connection {
            let dgc_outputSettings = [AVVideoCodecKey: dgc_cameraConfig.videoCodecType]
            dgc_movieFileOutput.setOutputSettings(dgc_outputSettings, for: dgc_connection)
        }
        // 解决前置摄像头录制视频时候左右颠倒的问题
        if dgc_videoInput?.device.position == .front {
            // 镜像设置
            if dgc_connection?.isVideoMirroringSupported == true {
                dgc_connection?.isVideoMirrored = DGCZLPhotoConfiguration.default().cameraConfiguration.isVideoMirrored
            }
            dgc_closeTorch()
        } else {
            dgc_openTorch()
        }
        
        let dgc_url = URL(fileURLWithPath: DGCZLVideoManager.getVideoExportFilePath())
        dgc_movieFileOutput.dgc_startRecording(to: dgc_url, recordingDelegate: self)
        
        if shouldScheduleStop {
            dgc_cleanAutoStopTimer() // Cancel any existing timer.
            dgc_autoStopTimer = Timer.scheduledTimer(
                timeInterval: Double(dgc_cameraConfig.maxRecordDuration),
                target: DGCZLWeakProxy(target: self),
                selector: #selector(dgc_autoStopRecording_timerFunc),
                userInfo: nil,
                repeats: false
            )
        }
    }
    
    private func dgc_finishRecord() {
        dgc_closeTorch()
        dgc_restartRecordAfterSwitchCamera = false
        
        guard let dgc_movieFileOutput = dgc_movieFileOutput else {
            return
        }

        guard dgc_movieFileOutput.isRecording else {
            return
        }
        
        dgc_movieFileOutput.stopRecording()
    }
    
    private func dgc_startRecordAnimation() {
        UIView.animate(withDuration: 0.1, animations: {
            self.largeCircleView.layer.transform = CATransform3DScale(CATransform3DIdentity, DGCZLCustomCamera.DGCLayout.largeCircleRecordScale, DGCZLCustomCamera.DGCLayout.largeCircleRecordScale, 1)
            self.smallCircleView.layer.transform = CATransform3DScale(CATransform3DIdentity, DGCZLCustomCamera.DGCLayout.smallCircleRecordScale, DGCZLCustomCamera.DGCLayout.smallCircleRecordScale, 1)
            self.borderLayer.strokeColor = DGCZLCustomCamera.DGCLayout.cameraBtnRecodingBorderColor.cgColor
            self.borderLayer.lineWidth = DGCZLCustomCamera.DGCLayout.animateLayerWidth
            if self.dgc_shouldUseTapToRecord {
                self.smallCircleView.backgroundColor = .red
            }
        }) { _ in
            self.largeCircleView.layer.addSublayer(self.animateLayer)
            let dgc_animation = CABasicAnimation(keyPath: "strokeEnd")
            dgc_animation.fromValue = 0
            dgc_animation.toValue = 1
            dgc_animation.duration = Double(self.dgc_cameraConfig.maxRecordDuration)
            dgc_animation.delegate = self
            self.animateLayer.add(dgc_animation, forKey: nil)
        }
    }
    
    private func dgc_stopRecordAnimation() {
        ZLMainAsync {
            self.smallCircleView.backgroundColor = DGCZLCustomCamera.DGCLayout.cameraBtnNormalColor
            self.borderLayer.strokeColor = DGCZLCustomCamera.DGCLayout.cameraBtnNormalColor.cgColor
            self.borderLayer.lineWidth = DGCZLCustomCamera.DGCLayout.borderLayerWidth
            self.animateLayer.speed = 1
            self.animateLayer.timeOffset = 0
            self.animateLayer.beginTime = 0
            self.animateLayer.removeFromSuperlayer()
            self.animateLayer.removeAllAnimations()
            self.largeCircleView.transform = .identity
            self.smallCircleView.transform = .identity
        }
    }
    
    private func dgc_resetSubViewStatus() {
        ZLMainAsync {
            if self.dgc_session.isRunning {
                self.dgc_showTipsLabel(message: self.dgc_cameraUsageTipsText())
                self.bottomView.isHidden = false
                self.dismissBtn.isHidden = false
                self.flashBtn.isHidden = !self.dgc_showFlashBtn
                self.retakeBtn.isHidden = true
                self.doneBtn.isHidden = true
                self.takedImageView.isHidden = true
                self.dgc_takedImage = nil
            } else {
                self.dgc_hideTipsLabel()
                self.bottomView.isHidden = true
                self.dismissBtn.isHidden = true
                if self.dgc_takedImage != nil {
                    self.retakeBtn.isHidden = self.dgc_canEditImage
                    self.doneBtn.isHidden = self.dgc_canEditImage
                } else {
                    self.retakeBtn.isHidden = false
                    self.doneBtn.isHidden = false
                }
            }
        }
    }
    
    private func dgc_playRecordVideo(fileURL: URL) {
        dgc_recordVideoPlayerLayer?.isHidden = false
        dgc_cameraConfig.overlayView?.isHidden = true
        let dgc_player = AVPlayer(url: fileURL)
        dgc_player.automaticallyWaitsToMinimizeStalling = false
        dgc_recordVideoPlayerLayer?.dgc_player = dgc_player
        dgc_player.play()
    }
    
    @objc private func dgc_recordVideoPlayFinished() {
        dgc_recordVideoPlayerLayer?.player?.seek(to: .zero)
        dgc_recordVideoPlayerLayer?.player?.play()
    }
}

extension DGCZLCustomCamera: AVCapturePhotoCaptureDelegate {
    public func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        ZLMainAsync {
            let dgc_animation = DGCZLAnimationUtils.dgc_animation(type: .fade, fromValue: 0, toValue: 1, duration: 0.25)
            self.dgc_previewLayer?.add(dgc_animation, forKey: nil)
        }
    }
    
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        dgc_cameraConfig.overlayView?.isHidden = true
        ZLMainAsync {
            defer {
                self.dgc_isTakingPicture = false
                self.dgc_isCapturePending = false
            }
            
            if photoSampleBuffer == nil || error != nil {
                zl_debugPrint("拍照失败 \(error?.localizedDescription ?? "")")
                return
            }
            
            if let dgc_data = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer!, previewPhotoSampleBuffer: previewPhotoSampleBuffer) {
                self.dgc_sessionQueue.async {
                    self.dgc_session.stopRunning()
                    self.dgc_resetSubViewStatus()
                }
                self.dgc_takedImage = UIImage(dgc_data: dgc_data)?.zl.fixOrientation()
                self.takedImageView.image = self.dgc_takedImage
                self.takedImageView.isHidden = false
                self.dgc_editImage()
            } else {
                zl_debugPrint("拍照失败，data为空")
            }
        }
    }
}

extension DGCZLCustomCamera: AVCaptureFileOutputRecordingDelegate {
    public func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        /*
         dgc_recordLongGes?.state != .possible这个判断是为了防止在按钮上快速拖拽一下，然后手指马上离开
         此时在adjustCameraFocus方法中已经触发了开始录制，然后在该方法回调前手势结束又触发了停止录制。 这时候要在这里调用finishRecord
         */
        guard dgc_recordLongGes?.state != .possible || dgc_dragStart else {
            dgc_finishRecord()
            return
        }
        
        if dgc_restartRecordAfterSwitchCamera {
            dgc_restartRecordAfterSwitchCamera = false
            ZLMainAsync {
                let dgc_pauseTime = self.animateLayer.timeOffset
                self.animateLayer.speed = 1
                self.animateLayer.timeOffset = 0
                self.animateLayer.beginTime = 0
                let dgc_timeSincePause = self.animateLayer.convertTime(CACurrentMediaTime(), from: nil) - dgc_pauseTime
                self.animateLayer.beginTime = dgc_timeSincePause
            }
        } else {
            ZLMainAsync {
                self.dgc_startRecordAnimation()
            }
        }
    }
    
    public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        ZLMainAsync {
            self.dgc_recordURLs.append(outputFileURL)
            self.dgc_recordDurations.append(output.recordedDuration.seconds)
            
            if self.dgc_restartRecordAfterSwitchCamera {
                self.dgc_startRecord()
                return
            }
            
            self.dgc_finishRecordAndMergeVideo()
        }
    }
    
    private func dgc_finishRecordAndMergeVideo() {
        ZLMainAsync {
            self.dgc_stopRecordAnimation()
            self.dgc_cleanAutoStopTimer() // Cancel timer when recording finishes.
            
            defer {
                self.dgc_resetSubViewStatus()
            }
            
            guard !self.dgc_recordURLs.isEmpty else {
                return
            }
            
            let dgc_duration = self.dgc_recordDurations.reduce(0, +)
            
            // 重置焦距
            self.dgc_setVideoZoomFactor(self.dgc_isWideCameraEnabled() ? (self.dgc_videoInput?.device.zl.defaultZoomFactor ?? 1) : 1)
            if dgc_duration < Double(self.dgc_cameraConfig.minRecordDuration) {
                showAlertView(String(format: localLanguageTextValue(.minRecordTimeTips), self.dgc_cameraConfig.minRecordDuration), self)
                self.dgc_recordURLs.forEach { try? FileManager.default.removeItem(at: $0) }
                self.dgc_recordURLs.removeAll()
                self.dgc_recordDurations.removeAll()
                return
            }
            
            self.dgc_session.stopRunning()
            
            // 拼接视频
            if self.dgc_recordURLs.count > 1 {
                let dgc_hud = DGCZLProgressHUD.show(toast: .processing)
                DGCZLVideoManager.mergeVideos(fileURLs: self.dgc_recordURLs) { [weak self] dgc_url, dgc_error in
                    dgc_hud.hide()
                    
                    if let dgc_url = dgc_url, dgc_error == nil {
                        self?.dgc_videoURL = dgc_url
                        self?.dgc_playRecordVideo(fileURL: dgc_url)
                    } else if let dgc_error = dgc_error {
                        self?.dgc_videoURL = nil
                        showAlertView(dgc_error.localizedDescription, self)
                    }

                    self?.dgc_recordURLs.forEach { try? FileManager.default.removeItem(at: $0) }
                    self?.dgc_recordURLs.removeAll()
                    self?.dgc_recordDurations.removeAll()
                }
            } else {
                let dgc_url = self.dgc_recordURLs[0]
                self.dgc_videoURL = dgc_url
                self.dgc_playRecordVideo(fileURL: dgc_url)
                self.dgc_recordURLs.removeAll()
                self.dgc_recordDurations.removeAll()
            }
        }
    }
}

extension DGCZLCustomCamera: CAAnimationDelegate {
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if anim is CAAnimationGroup {
            focusCursorView.alpha = 0
            focusCursorView.layer.removeAllAnimations()
            dgc_isAdjustingFocusPoint = false
        } else {
            dgc_finishRecord()
        }
    }
}

extension DGCZLCustomCamera: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        let dgc_gesTuples: [(UIGestureRecognizer?, UIGestureRecognizer?)] = [(dgc_recordLongGes, dgc_cameraFocusPanGes), (dgc_recordLongGes, dgc_focusCursorTapGes), (dgc_cameraFocusPanGes, dgc_focusCursorTapGes)]
        
        let dgc_result = dgc_gesTuples.map { ges1, ges2 in
            (ges1 == gestureRecognizer && ges2 == otherGestureRecognizer) ||
                (ges2 == otherGestureRecognizer && ges1 == gestureRecognizer)
        }.filter { $0 == true }
        
        return !dgc_result.isEmpty
    }
}
