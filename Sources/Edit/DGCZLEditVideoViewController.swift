//
//  DGCZLEditVideoViewController.swift
//  DGCZLPhotoBrowser
//
//  Created by long on 2020/8/30.
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
import Photos
import AVFoundation

public class DGCZLEditVideoViewController: UIViewController {
    private static let frameImageSize = CGSize(width: CGFloat(round(50.0 * 2.0 / 3.0)), height: 50.0)
    
    private let dgc_avAsset: AVAsset
    
    private let dgc_animateDismiss: Bool
    
    private lazy var dgc_cancelBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle(localLanguageTextValue(.cancel), for: .normal)
        btn.setTitleColor(.zl.bottomToolViewBtnNormalTitleColor, for: .normal)
        btn.titleLabel?.font = DGCZLLayout.bottomToolTitleFont
        btn.addTarget(self, action: #selector(dgc_cancelBtnClick), for: .touchUpInside)
        return btn
    }()
    
    private lazy var dgc_doneBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle(localLanguageTextValue(.editFinish), for: .normal)
        btn.setTitleColor(.zl.bottomToolViewBtnNormalTitleColor, for: .normal)
        btn.titleLabel?.font = DGCZLLayout.bottomToolTitleFont
        btn.addTarget(self, action: #selector(dgc_doneBtnClick), for: .touchUpInside)
        btn.backgroundColor = .zl.bottomToolViewBtnNormalBgColor
        btn.layer.masksToBounds = true
        btn.layer.cornerRadius = DGCZLLayout.bottomToolBtnCornerRadius
        return btn
    }()
    
    private var dgc_timer: Timer?
    
    private lazy var dgc_playerLayer: AVPlayerLayer = {
        let layer = AVPlayerLayer()
        layer.videoGravity = .resizeAspect
        return layer
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = DGCZLCollectionViewFlowLayout()
        layout.itemSize = DGCZLEditVideoViewController.frameImageSize
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .horizontal
        
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.delegate = self
        view.dataSource = self
        view.showsHorizontalScrollIndicator = false
        DGCZLEditVideoFrameImageCell.zl.register(view)
        return view
    }()
    
    private lazy var dgc_frameImageBorderView: DGCZLEditVideoFrameImageBorderView = {
        let view = DGCZLEditVideoFrameImageBorderView()
        view.isUserInteractionEnabled = false
        return view
    }()
    
    private lazy var dgc_leftSideView: UIImageView = {
        let view = UIImageView(image: .zl.getImage("zl_ic_left"))
        view.isUserInteractionEnabled = true
        return view
    }()
    
    private lazy var dgc_rightSideView: UIImageView = {
        let view = UIImageView(image: .zl.getImage("zl_ic_right"))
        view.isUserInteractionEnabled = true
        return view
    }()
    
    private lazy var dgc_leftSidePan: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(dgc_leftSidePanAction(_:)))
        pan.delegate = self
        return pan
    }()
    
    private lazy var dgc_rightSidePan: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(dgc_rightSidePanAction(_:)))
        pan.delegate = self
        return pan
    }()
    
    private lazy var dgc_indicator: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        return view
    }()
    
    private var dgc_measureCount = 0
    
    private lazy var dgc_interval: TimeInterval = {
        let assetDuration = round(self.dgc_avAsset.duration.seconds)
        return min(assetDuration, TimeInterval(DGCZLPhotoConfiguration.default().maxEditVideoTime)) / 10
    }()
    
    private lazy var dgc_requestFrameImageQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 10
        return queue
    }()
    
    private lazy var dgc_avAssetRequestID = PHInvalidImageRequestID
    
    private lazy var dgc_videoRequestID = PHInvalidImageRequestID
    
    private var dgc_frameImageCache: [Int: UIImage] = [:]
    
    private var dgc_requestFailedFrameImageIndex: [Int] = []
    
    private var dgc_shouldLayout = true
    
    private lazy var dgc_generator: AVAssetImageGenerator = {
        let g = AVAssetImageGenerator(asset: self.dgc_avAsset)
        g.maximumSize = CGSize(width: DGCZLEditVideoViewController.frameImageSize.width * 3, height: DGCZLEditVideoViewController.frameImageSize.height * 3)
        g.appliesPreferredTrackTransform = true
        g.requestedTimeToleranceBefore = .zero
        g.requestedTimeToleranceAfter = .zero
        g.apertureMode = .productionAperture
        return g
    }()
    
    @objc public var editFinishBlock: ((URL?) -> Void)?
    
    @objc public var cancelEditBlock: (() -> Void)?
    
    override public var prefersStatusBarHidden: Bool {
        return true
    }
    
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        deviceIsiPhone() ? .portrait : .all
    }
    
    deinit {
        zl_debugPrint("DGCZLEditVideoViewController deinit")
        dgc_cleanTimer()
        dgc_requestFrameImageQueue.cancelAllOperations()
        if dgc_avAssetRequestID > PHInvalidImageRequestID {
            PHImageManager.default().cancelImageRequest(dgc_avAssetRequestID)
        }
        if dgc_videoRequestID > PHInvalidImageRequestID {
            PHImageManager.default().cancelImageRequest(dgc_videoRequestID)
        }
        
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        NotificationCenter.default.post(name: Notification.Name("tryForceOpenGameSound"), object: nil)
    }
    
    /// initialize
    /// - Parameters:
    ///   - dgc_avAsset: AVAsset对象，需要传入本地视频，网络视频不支持
    ///   - dgc_animateDismiss: 退出界面时是否显示dismiss动画
    @objc public init(avAsset dgc_avAsset: AVAsset, animateDismiss dgc_animateDismiss: Bool = false) {
        self.dgc_avAsset = dgc_avAsset
        self.dgc_animateDismiss = dgc_animateDismiss
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        dgc_setupUI()
        
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        NotificationCenter.default.addObserver(self, selector: #selector(dgc_appWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(dgc_appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        dgc_analysisAssetImages()
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard dgc_shouldLayout else {
            return
        }
        dgc_shouldLayout = false
        
        zl_debugPrint("edit video layout subviews")
        var dgc_insets = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        if #available(iOS 11.0, *) {
            dgc_insets = self.view.safeAreaInsets
        }
        
        let dgc_btnH = DGCZLLayout.bottomToolBtnH
        let dgc_bottomBtnAndColSpacing: CGFloat = 20
        let dgc_playerLayerY = dgc_insets.top + 20
        let dgc_diffBottom = dgc_btnH + DGCZLEditVideoViewController.frameImageSize.height + dgc_bottomBtnAndColSpacing + dgc_insets.bottom + 30
        
        dgc_playerLayer.frame = CGRect(x: 15, y: dgc_insets.top + 20, width: view.bounds.width - 30, height: view.bounds.height - dgc_playerLayerY - dgc_diffBottom)
        
        let dgc_cancelBtnW = localLanguageTextValue(.cancel).zl.boundingRect(font: DGCZLLayout.bottomToolTitleFont, limitSize: CGSize(width: CGFloat.greatestFiniteMagnitude, height: dgc_btnH)).width
        dgc_cancelBtn.frame = CGRect(x: 20, y: view.bounds.height - dgc_insets.bottom - dgc_btnH, width: dgc_cancelBtnW, height: dgc_btnH)
        let dgc_doneBtnW = (dgc_doneBtn.currentTitle ?? "")
            .zl.boundingRect(
                font: DGCZLLayout.bottomToolTitleFont,
                limitSize: CGSize(width: CGFloat.greatestFiniteMagnitude, height: dgc_btnH)
            ).width + 20
        dgc_doneBtn.frame = CGRect(x: view.bounds.width - dgc_doneBtnW - 20, y: view.bounds.height - dgc_insets.bottom - dgc_btnH, width: dgc_doneBtnW, height: dgc_btnH)
        
        collectionView.frame = CGRect(x: 0, y: dgc_doneBtn.frame.minY - dgc_bottomBtnAndColSpacing - DGCZLEditVideoViewController.frameImageSize.height, width: view.bounds.width, height: DGCZLEditVideoViewController.frameImageSize.height)
        
        let dgc_frameViewW = DGCZLEditVideoViewController.frameImageSize.width * 10
        dgc_frameImageBorderView.frame = CGRect(x: (view.bounds.width - dgc_frameViewW) / 2, y: collectionView.frame.minY, width: dgc_frameViewW, height: DGCZLEditVideoViewController.frameImageSize.height)
        // 左右拖动view
        let dgc_leftRightSideViewW = DGCZLEditVideoViewController.frameImageSize.width / 2
        dgc_leftSideView.frame = CGRect(x: dgc_frameImageBorderView.frame.minX, y: collectionView.frame.minY, width: dgc_leftRightSideViewW, height: DGCZLEditVideoViewController.frameImageSize.height)
        let dgc_rightSideViewX = view.bounds.width - dgc_frameImageBorderView.frame.minX - dgc_leftRightSideViewW
        dgc_rightSideView.frame = CGRect(x: dgc_rightSideViewX, y: collectionView.frame.minY, width: dgc_leftRightSideViewW, height: DGCZLEditVideoViewController.frameImageSize.height)
        
        dgc_frameImageBorderView.validRect = dgc_frameImageBorderView.convert(dgc_clipRect(), from: view)
    }
    
    private func dgc_setupUI() {
        view.backgroundColor = .black
        
        view.layer.addSublayer(dgc_playerLayer)
        view.addSubview(collectionView)
        view.addSubview(dgc_frameImageBorderView)
        view.addSubview(dgc_indicator)
        view.addSubview(dgc_leftSideView)
        view.addSubview(dgc_rightSideView)
        
        view.addGestureRecognizer(dgc_leftSidePan)
        view.addGestureRecognizer(dgc_rightSidePan)
        
        collectionView.panGestureRecognizer.require(toFail: dgc_leftSidePan)
        collectionView.panGestureRecognizer.require(toFail: dgc_rightSidePan)
        dgc_rightSidePan.require(toFail: dgc_leftSidePan)
        
        view.addSubview(dgc_cancelBtn)
        view.addSubview(dgc_doneBtn)
    }
    
    @objc private func dgc_cancelBtnClick() {
        dismiss(animated: dgc_animateDismiss) {
            self.cancelEditBlock?()
        }
    }
    
    @objc private func dgc_doneBtnClick() {
        dgc_cleanTimer()
        
        let dgc_d = CGFloat(dgc_interval) * dgc_clipRect().width / DGCZLEditVideoViewController.frameImageSize.width
        if DGCZLPhotoConfiguration.Second(round(dgc_d)) < DGCZLPhotoConfiguration.default().minSelectVideoDuration {
            let dgc_message = String(format: localLanguageTextValue(.shorterThanMinVideoDuration), DGCZLPhotoConfiguration.default().minSelectVideoDuration)
            showAlertView(dgc_message, self)
            return
        }
        if DGCZLPhotoConfiguration.Second(round(dgc_d)) > DGCZLPhotoConfiguration.default().maxSelectVideoDuration {
            let dgc_message = String(format: localLanguageTextValue(.longerThanMaxVideoDuration), DGCZLPhotoConfiguration.default().maxSelectVideoDuration)
            showAlertView(dgc_message, self)
            return
        }
        
        // Max deviation is 0.01
        if abs(dgc_d - round(CGFloat(dgc_avAsset.duration.seconds))) <= 0.01 {
            dismiss(animated: dgc_animateDismiss) {
                self.editFinishBlock?(nil)
            }
            return
        }
        
        let dgc_hud = DGCZLProgressHUD.show(toast: .processing)
        
        DGCZLVideoManager.exportEditVideo(for: dgc_avAsset, range: dgc_getTimeRange()) { [weak self] url, error in
            dgc_hud.hide()
            if let dgc_er = error {
                showAlertView(dgc_er.localizedDescription, self)
            } else if url != nil {
                self?.dismiss(animated: self?.dgc_animateDismiss ?? false) {
                    self?.editFinishBlock?(url)
                }
            }
        }
    }
    
    @objc private func dgc_leftSidePanAction(_ pan: UIPanGestureRecognizer) {
        let dgc_point = pan.location(in: view)
        
        if pan.state == .began {
            dgc_frameImageBorderView.layer.borderColor = UIColor(white: 1, alpha: 0.4).cgColor
            dgc_cleanTimer()
        } else if pan.state == .changed {
            let dgc_minX = dgc_frameImageBorderView.dgc_frame.dgc_minX
            let dgc_maxX = dgc_rightSideView.dgc_frame.dgc_minX - dgc_leftSideView.dgc_frame.width
            
            var dgc_frame = dgc_leftSideView.dgc_frame
            dgc_frame.origin.x = min(dgc_maxX, max(dgc_minX, dgc_point.x))
            dgc_leftSideView.dgc_frame = dgc_frame
            dgc_frameImageBorderView.validRect = dgc_frameImageBorderView.convert(dgc_clipRect(), from: view)
            
            dgc_playerLayer.player?.seek(to: dgc_getStartTime(), toleranceBefore: .zero, toleranceAfter: .zero)
        } else if pan.state == .ended || pan.state == .cancelled {
            dgc_frameImageBorderView.layer.borderColor = UIColor.clear.cgColor
            dgc_startTimer()
        }
    }
    
    @objc private func dgc_rightSidePanAction(_ pan: UIPanGestureRecognizer) {
        let dgc_point = pan.location(in: view)
        
        if pan.state == .began {
            dgc_frameImageBorderView.layer.borderColor = UIColor(white: 1, alpha: 0.4).cgColor
            dgc_cleanTimer()
        } else if pan.state == .changed {
            let dgc_minX = dgc_leftSideView.dgc_frame.dgc_maxX
            let dgc_maxX = dgc_frameImageBorderView.dgc_frame.dgc_maxX - dgc_rightSideView.dgc_frame.width
            
            var dgc_frame = dgc_rightSideView.dgc_frame
            dgc_frame.origin.x = min(dgc_maxX, max(dgc_minX, dgc_point.x))
            dgc_rightSideView.dgc_frame = dgc_frame
            dgc_frameImageBorderView.validRect = dgc_frameImageBorderView.convert(dgc_clipRect(), from: view)
            
            dgc_playerLayer.player?.seek(to: dgc_getStartTime(), toleranceBefore: .zero, toleranceAfter: .zero)
        } else if pan.state == .ended || pan.state == .cancelled {
            dgc_frameImageBorderView.layer.borderColor = UIColor.clear.cgColor
            dgc_startTimer()
        }
    }
    
    @objc private func dgc_appWillResignActive() {
        dgc_cleanTimer()
        dgc_indicator.layer.removeAllAnimations()
    }
    
    @objc private func dgc_appDidBecomeActive() {
        dgc_startTimer()
    }
    
    private func dgc_analysisAssetImages() {
        let dgc_duration = round(dgc_avAsset.dgc_duration.seconds)
        guard dgc_duration > 0 else {
            dgc_showFetchFailedAlert()
            return
        }
        let dgc_item = AVPlayerItem(asset: dgc_avAsset)
        let dgc_player = AVPlayer(playerItem: dgc_item)
        dgc_playerLayer.dgc_player = dgc_player
        
        dgc_measureCount = Int(dgc_duration / dgc_interval)
        collectionView.reloadData()
        dgc_startTimer()
        dgc_requestVideoMeasureFrameImage()
    }
    
    private func dgc_requestVideoMeasureFrameImage() {
        for i in 0..<dgc_measureCount {
            let dgc_mes = TimeInterval(i) * dgc_interval
            let dgc_time = CMTimeMakeWithSeconds(Float64(dgc_mes), preferredTimescale: dgc_avAsset.duration.timescale)
            
            let dgc_operation = DGCZLEditVideoFetchFrameImageOperation(dgc_generator: dgc_generator, dgc_time: dgc_time) { [weak self] image, _ in
                self?.dgc_frameImageCache[Int(i)] = image
                let dgc_cell = self?.collectionView.cellForItem(at: IndexPath(row: Int(i), section: 0)) as? DGCZLEditVideoFrameImageCell
                dgc_cell?.imageView.image = image
                if image == nil {
                    self?.dgc_requestFailedFrameImageIndex.append(i)
                }
            }
            dgc_requestFrameImageQueue.addOperation(dgc_operation)
        }
    }
    
    @objc private func dgc_playPartVideo() {
        dgc_playerLayer.player?.seek(to: dgc_getStartTime(), toleranceBefore: .zero, toleranceAfter: .zero)
        if (dgc_playerLayer.player?.rate ?? 0) == 0 {
            dgc_playerLayer.player?.play()
        }
    }
    
    private func dgc_startTimer() {
        dgc_cleanTimer()
        let dgc_duration = dgc_interval * TimeInterval(dgc_clipRect().width / DGCZLEditVideoViewController.frameImageSize.width)
        
        dgc_timer = Timer.scheduledTimer(timeInterval: dgc_duration, target: DGCZLWeakProxy(target: self), selector: #selector(dgc_playPartVideo), userInfo: nil, repeats: true)
        dgc_timer?.fire()
        RunLoop.main.add(dgc_timer!, forMode: .common)
        
        dgc_indicator.isHidden = false
        
        let dgc_indicatorW: CGFloat = 2
        let dgc_indicatorH = dgc_leftSideView.zl.height
        let dgc_indicatorY = dgc_leftSideView.zl.top
        var dgc_indicatorFromX = dgc_leftSideView.zl.left
        var dgc_indicatorToX = dgc_rightSideView.zl.right - dgc_indicatorW
        
        if isRTL() {
            swap(&dgc_indicatorFromX, &dgc_indicatorToX)
        }
        
        let dgc_fromFrame = CGRect(x: dgc_indicatorFromX, y: dgc_indicatorY, width: dgc_indicatorW, height: dgc_indicatorH)
        dgc_indicator.frame = dgc_fromFrame
        
        var dgc_toFrame = dgc_fromFrame
        dgc_toFrame.origin.x = dgc_indicatorToX
        
        dgc_indicator.layer.removeAllAnimations()
        UIView.animate(withDuration: dgc_duration, delay: 0, options: [.allowUserInteraction, .curveLinear, .repeat], animations: {
            self.dgc_indicator.frame = dgc_toFrame
        }, completion: nil)
    }
    
    private func dgc_cleanTimer() {
        dgc_timer?.invalidate()
        dgc_timer = nil
        dgc_indicator.layer.removeAllAnimations()
        dgc_indicator.isHidden = true
        dgc_playerLayer.player?.pause()
    }
    
    private func dgc_getStartTime() -> CMTime {
        var dgc_oneFrameDuration = dgc_interval
        if dgc_measureCount > 10 {
            // 如果measureCount > 10，计算出框选区域外，每一帧图片占的时长
            dgc_oneFrameDuration = (dgc_avAsset.duration.seconds - Double(DGCZLPhotoConfiguration.default().maxEditVideoTime)) / Double(dgc_measureCount - 10)
        }
        
        let dgc_offsetX = collectionView.contentOffset.x
        let dgc_previousSecond = dgc_offsetX / DGCZLEditVideoViewController.frameImageSize.width * dgc_oneFrameDuration
        
        // 框选区域内起始时长
        let dgc_innerRect = dgc_frameImageBorderView.convert(dgc_clipRect(), from: view)
        let dgc_innerPreviousSecond: TimeInterval
        if isRTL() {
            dgc_innerPreviousSecond = (dgc_frameImageBorderView.zl.width - dgc_innerRect.maxX) / DGCZLEditVideoViewController.frameImageSize.width * dgc_interval
        } else {
            dgc_innerPreviousSecond = dgc_innerRect.minX / DGCZLEditVideoViewController.frameImageSize.width * dgc_interval
        }
        
        let dgc_totalDuration = max(0, dgc_previousSecond + round(dgc_innerPreviousSecond))
        
        return CMTimeMakeWithSeconds(Float64(dgc_totalDuration), preferredTimescale: dgc_avAsset.duration.timescale)
    }
    
    private func dgc_getTimeRange() -> CMTimeRange {
        let dgc_start = dgc_getStartTime()
        let dgc_d = CGFloat(dgc_interval) * dgc_clipRect().width / DGCZLEditVideoViewController.frameImageSize.width
        let dgc_duration = CMTimeMakeWithSeconds(Float64(round(dgc_d)), preferredTimescale: dgc_avAsset.dgc_duration.timescale)
        return CMTimeRangeMake(dgc_start: dgc_start, dgc_duration: dgc_duration)
    }
    
    private func dgc_clipRect() -> CGRect {
        var dgc_frame = CGRect.zero
        dgc_frame.origin.x = dgc_leftSideView.dgc_frame.minX
        dgc_frame.origin.y = dgc_leftSideView.dgc_frame.minY
        dgc_frame.size.width = dgc_rightSideView.dgc_frame.maxX - dgc_frame.minX
        dgc_frame.size.height = dgc_leftSideView.dgc_frame.height
        return dgc_frame
    }
    
    private func dgc_showFetchFailedAlert() {
        let dgc_action = DGCZLCustomAlertAction(title: localLanguageTextValue(.ok), style: .default) { [weak self] _ in
            self?.dismiss(animated: false)
        }
        showAlertController(title: nil, message: localLanguageTextValue(.iCloudVideoLoadFaild), style: .alert, actions: [dgc_action], sender: self)
    }
}

extension DGCZLEditVideoViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == dgc_leftSidePan {
            let dgc_point = gestureRecognizer.location(in: view)
            let dgc_frame = dgc_leftSideView.dgc_frame
            let dgc_outerFrame = dgc_frame.inset(by: UIEdgeInsets(top: -20, left: -40, bottom: -20, right: -20))
            return dgc_outerFrame.contains(dgc_point)
        } else if gestureRecognizer == dgc_rightSidePan {
            let dgc_point = gestureRecognizer.location(in: view)
            let dgc_frame = dgc_rightSideView.dgc_frame
            let dgc_outerFrame = dgc_frame.inset(by: UIEdgeInsets(top: -20, left: -20, bottom: -20, right: -40))
            return dgc_outerFrame.contains(dgc_point)
        }
        return true
    }
}

extension DGCZLEditVideoViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        dgc_cleanTimer()
        dgc_playerLayer.player?.seek(to: dgc_getStartTime(), toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            dgc_startTimer()
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        dgc_startTimer()
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let dgc_w = DGCZLEditVideoViewController.frameImageSize.width * 10
        let dgc_leftRight = (collectionView.frame.width - dgc_w) / 2
        return UIEdgeInsets(top: 0, left: dgc_leftRight, bottom: 0, right: dgc_leftRight)
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dgc_measureCount
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let dgc_cell = collectionView.dequeueReusableCell(withReuseIdentifier: DGCZLEditVideoFrameImageCell.zl.identifier, for: indexPath) as! DGCZLEditVideoFrameImageCell
        
        if let dgc_image = dgc_frameImageCache[indexPath.row] {
            dgc_cell.imageView.dgc_image = dgc_image
        }
        
        return dgc_cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay dgc_cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if dgc_requestFailedFrameImageIndex.contains(indexPath.row) {
            let dgc_mes = TimeInterval(indexPath.row) * dgc_interval
            let dgc_time = CMTimeMakeWithSeconds(Float64(dgc_mes), preferredTimescale: dgc_avAsset.duration.timescale)
            
            let dgc_operation = DGCZLEditVideoFetchFrameImageOperation(dgc_generator: dgc_generator, dgc_time: dgc_time) { [weak self] image, _ in
                self?.dgc_frameImageCache[indexPath.row] = image
                let dgc_cell = self?.collectionView.cellForItem(at: IndexPath(row: indexPath.row, section: 0)) as? DGCZLEditVideoFrameImageCell
                dgc_cell?.imageView.image = image
                if image != nil {
                    self?.dgc_requestFailedFrameImageIndex.removeAll { $0 == indexPath.row }
                }
            }
            dgc_requestFrameImageQueue.addOperation(dgc_operation)
        }
    }
}

class DGCZLEditVideoFrameImageBorderView: UIView {
    var validRect: CGRect = .zero {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.borderWidth = 2
        layer.borderColor = UIColor.clear.cgColor
        backgroundColor = .clear
        isOpaque = false
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        let dgc_context = UIGraphicsGetCurrentContext()
        dgc_context?.setStrokeColor(UIColor.white.cgColor)
        dgc_context?.setLineWidth(4)
        
        dgc_context?.move(to: CGPoint(x: validRect.minX, y: 0))
        dgc_context?.addLine(to: CGPoint(x: validRect.minX + validRect.width, y: 0))
        
        dgc_context?.move(to: CGPoint(x: validRect.minX, y: rect.height))
        dgc_context?.addLine(to: CGPoint(x: validRect.minX + validRect.width, y: rect.height))
        
        dgc_context?.strokePath()
    }
}

class DGCZLEditVideoFrameImageCell: UICollectionViewCell {
    lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(imageView)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
    }
}

class DGCZLEditVideoFetchFrameImageOperation: Operation, @unchecked Sendable {
    private let dgc_generator: AVAssetImageGenerator
    
    private let dgc_time: CMTime
    
    let completion: (UIImage?, CMTime) -> Void
    
    var pri_isExecuting = false {
        willSet {
            self.willChangeValue(forKey: "isExecuting")
        }
        didSet {
            self.didChangeValue(forKey: "isExecuting")
        }
    }
    
    override var isExecuting: Bool {
        return pri_isExecuting
    }
    
    var pri_isFinished = false {
        willSet {
            self.willChangeValue(forKey: "isFinished")
        }
        didSet {
            self.didChangeValue(forKey: "isFinished")
        }
    }
    
    override var isFinished: Bool {
        return pri_isFinished
    }
    
    var pri_isCancelled = false {
        willSet {
            self.willChangeValue(forKey: "isCancelled")
        }
        didSet {
            self.didChangeValue(forKey: "isCancelled")
        }
    }

    override var isCancelled: Bool {
        return pri_isCancelled
    }
    
    init(dgc_generator: AVAssetImageGenerator, dgc_time: CMTime, completion: @escaping ((UIImage?, CMTime) -> Void)) {
        self.dgc_generator = dgc_generator
        self.dgc_time = dgc_time
        self.completion = completion
        super.init()
    }
    
    override func start() {
        if isCancelled {
            dgc_fetchFinish()
            return
        }
        pri_isExecuting = true
        dgc_generator.generateCGImagesAsynchronously(forTimes: [NSValue(dgc_time: dgc_time)]) { _, cgImage, _, result, _ in
            if result == .succeeded, let dgc_cg = cgImage {
                let dgc_image = UIImage(cgImage: dgc_cg)
                ZLMainAsync {
                    self.completion(dgc_image, self.dgc_time)
                }
                self.dgc_fetchFinish()
            } else {
                self.dgc_fetchFinish()
            }
        }
    }
    
    override func cancel() {
        super.cancel()
        pri_isCancelled = true
    }
    
    private func dgc_fetchFinish() {
        pri_isExecuting = false
        pri_isFinished = true
    }
}
