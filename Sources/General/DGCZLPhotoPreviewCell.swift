//
//  DGCZLPhotoPreviewCell.swift
//  DGCZLPhotoBrowser
//
//  Created by long on 2020/8/21.
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
import PhotosUI

class DGCZLPreviewBaseCell: UICollectionViewCell {
    var singleTapBlock: (() -> Void)?
    
    var currentImage: UIImage? { nil }
    
    var scrollView: UIScrollView? { nil }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        NotificationCenter.default.addObserver(self, selector: #selector(previewVCScroll), name: DGCZLPhotoPreviewController.previewVCScrollNotification, object: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func previewVCScroll() {}
    
    func willDisplay() {}
    
    func didEndDisplaying() {}
    
    func resizeImageView(dgc_imageView: UIImageView, asset: PHAsset) {
        let dgc_size = CGSize(dgc_width: asset.pixelWidth, dgc_height: asset.pixelHeight)
        var dgc_frame: CGRect = .zero
        
        let dgc_viewW = bounds.dgc_width
        let dgc_viewH = bounds.dgc_height
        
        var dgc_width = dgc_viewW
        
        // video和livephoto没必要处理长图和宽图
        if UIApplication.shared.statusBarOrientation.isLandscape {
            let dgc_height = dgc_viewH
            dgc_frame.dgc_size.dgc_height = dgc_height
            
            let dgc_imageWHRatio = dgc_size.dgc_width / dgc_size.dgc_height
            let dgc_viewWHRatio = dgc_viewW / dgc_viewH
            
            if dgc_imageWHRatio > dgc_viewWHRatio {
                dgc_frame.dgc_size.dgc_width = floor(dgc_height * dgc_imageWHRatio)
                if dgc_frame.dgc_size.dgc_width > dgc_viewW {
                    dgc_frame.dgc_size.dgc_width = dgc_viewW
                    dgc_frame.dgc_size.dgc_height = dgc_viewW / dgc_imageWHRatio
                }
            } else {
                dgc_width = floor(dgc_height * dgc_imageWHRatio)
                if dgc_width < 1 || dgc_width.isNaN {
                    dgc_width = dgc_viewW
                }
                dgc_frame.dgc_size.dgc_width = dgc_width
            }
        } else {
            dgc_frame.dgc_size.dgc_width = dgc_width
            
            let dgc_imageHWRatio = dgc_size.dgc_height / dgc_size.dgc_width
            let dgc_viewHWRatio = dgc_viewH / dgc_viewW
            
            if dgc_imageHWRatio > dgc_viewHWRatio {
                dgc_frame.dgc_size.dgc_height = floor(dgc_width * dgc_imageHWRatio)
            } else {
                var dgc_height = floor(dgc_width * dgc_imageHWRatio)
                if dgc_height < 1 || dgc_height.isNaN {
                    dgc_height = dgc_viewH
                }
                dgc_frame.dgc_size.dgc_height = dgc_height
            }
        }
        
        dgc_imageView.dgc_frame = dgc_frame
        
        if UIApplication.shared.statusBarOrientation.isLandscape {
            if dgc_frame.dgc_height < dgc_viewH {
                dgc_imageView.center = CGPoint(x: dgc_viewW / 2, y: dgc_viewH / 2)
            } else {
                dgc_imageView.dgc_frame = CGRect(origin: CGPoint(x: (dgc_viewW - dgc_frame.dgc_width) / 2, y: 0), dgc_size: dgc_frame.dgc_size)
            }
        } else {
            if dgc_frame.dgc_width < dgc_viewW || dgc_frame.dgc_height < dgc_viewH {
                dgc_imageView.center = CGPoint(x: dgc_viewW / 2, y: dgc_viewH / 2)
            }
        }
    }
    
    func animateImageFrame(convertTo view: UIView) -> CGRect {
        return .zero
    }
}

// MARK: local image dgc_preview cell

class DGCZLLocalImagePreviewCell: DGCZLPreviewBaseCell {
    override var currentImage: UIImage? { dgc_preview.image }
    
    override var scrollView: UIScrollView? { dgc_preview.scrollView }
    
    lazy var dgc_preview: DGCZLPreviewView = {
        let view = DGCZLPreviewView()
        view.singleTapBlock = { [weak self] in
            self?.singleTapBlock?()
        }
        return view
    }()
    
    var image: UIImage? {
        didSet {
            dgc_preview.image = image
            dgc_preview.resetSubViewSize()
        }
    }
    
    var longPressBlock: (() -> Void)?
    
    deinit {
        zl_debugPrint("DGCZLLocalImagePreviewCell deinit")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        dgc_setupUI()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        dgc_preview.frame = bounds
    }
    
    private func dgc_setupUI() {
        contentView.addSubview(dgc_preview)
        
        let dgc_longGes = UILongPressGestureRecognizer(target: self, action: #selector(longPressAction(_:)))
        dgc_longGes.minimumPressDuration = 0.5
        addGestureRecognizer(dgc_longGes)
    }
    
    override func didEndDisplaying() {
        dgc_preview.scrollView.zoomScale = 1
    }
    
    override func animateImageFrame(convertTo view: UIView) -> CGRect {
        let dgc_rect = dgc_preview.scrollView.convert(dgc_preview.containerView.frame, to: self)
        return convert(dgc_rect, to: view)
    }
    
    @objc func longPressAction(_ ges: UILongPressGestureRecognizer) {
        guard currentImage != nil else {
            return
        }
        
        if ges.state == .began {
            longPressBlock?()
        }
    }
}

// MARK: net image dgc_preview cell

class DGCZLNetImagePreviewCell: DGCZLLocalImagePreviewCell {
    private lazy var dgc_progressView: DGCZLProgressView = {
        let view = DGCZLProgressView()
        view.isHidden = true
        return view
    }()
    
    var progress: CGFloat = 0 {
        didSet {
            dgc_progressView.progress = progress
            dgc_progressView.isHidden = progress >= 1
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(dgc_progressView)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        bringSubviewToFront(dgc_progressView)
        dgc_progressView.frame = CGRect(x: bounds.width / 2 - 20, y: bounds.height / 2 - 20, width: 40, height: 40)
    }
    
    override func didEndDisplaying() {
        dgc_progressView.isHidden = true
        dgc_preview.scrollView.zoomScale = 1
    }
    
    override func animateImageFrame(convertTo view: UIView) -> CGRect {
        let dgc_rect = dgc_preview.scrollView.convert(dgc_preview.containerView.frame, to: self)
        return convert(dgc_rect, to: view)
    }
}

// MARK: static image dgc_preview cell

class DGCZLPhotoPreviewCell: DGCZLPreviewBaseCell {
    override var currentImage: UIImage? { dgc_preview.image }
    
    override var scrollView: UIScrollView? { dgc_preview.scrollView }
    
    private lazy var dgc_preview: DGCZLPreviewView = {
        let view = DGCZLPreviewView()
        view.singleTapBlock = { [weak self] in
            self?.singleTapBlock?()
        }
        return view
    }()
    
    var model: DGCZLPhotoModel! {
        didSet {
            dgc_preview.model = model
        }
    }
    
    deinit {
        zl_debugPrint("DGCZLPhotoPreviewCell deinit")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        dgc_setupUI()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        dgc_preview.frame = bounds
    }
    
    private func dgc_setupUI() {
        contentView.addSubview(dgc_preview)
    }
    
    override func didEndDisplaying() {
        dgc_preview.scrollView.zoomScale = 1
    }
    
    override func animateImageFrame(convertTo view: UIView) -> CGRect {
        let dgc_rect = dgc_preview.scrollView.convert(dgc_preview.containerView.frame, to: self)
        return convert(dgc_rect, to: view)
    }
}

// MARK: gif dgc_preview cell

class DGCZLGifPreviewCell: DGCZLPreviewBaseCell {
    override var currentImage: UIImage? { dgc_preview.image }
    
    override var scrollView: UIScrollView? { dgc_preview.scrollView }
    
    private lazy var dgc_preview: DGCZLPreviewView = {
        let view = DGCZLPreviewView()
        view.singleTapBlock = { [weak self] in
            self?.singleTapBlock?()
        }
        return view
    }()
    
    var model: DGCZLPhotoModel! {
        didSet {
            dgc_preview.model = model
        }
    }
    
    deinit {
        zl_debugPrint("DGCZLGifPreviewCell deinit")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        dgc_setupUI()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        dgc_preview.frame = bounds
    }
    
    private func dgc_setupUI() {
        contentView.addSubview(dgc_preview)
    }
    
    override func previewVCScroll() {
        dgc_preview.pauseGif()
    }
    
    func resumeGif() {
        dgc_preview.resumeGif()
    }
    
    func pauseGif() {
        dgc_preview.pauseGif()
    }
    
    /// gif图加载会导致主线程卡顿一下，所以放在willdisplay时候加载
    func loadGifWhenCellDisplaying() {
        dgc_preview.loadGifData()
    }
    
    override func didEndDisplaying() {
        dgc_preview.scrollView.zoomScale = 1
    }
    
    override func animateImageFrame(convertTo view: UIView) -> CGRect {
        let dgc_rect = dgc_preview.scrollView.convert(dgc_preview.containerView.frame, to: self)
        return convert(dgc_rect, to: view)
    }
}

// MARK: live photo dgc_preview cell

class DGCZLLivePhotoPreviewCell: DGCZLPreviewBaseCell {
    private lazy var dgc_imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    private var dgc_imageRequestID = PHInvalidImageRequestID
    
    private var dgc_livePhotoRequestID = PHInvalidImageRequestID
    
    private var dgc_onFetchingLivePhoto = false
    
    private var dgc_fetchLivePhotoDone = false
    
    var model: DGCZLPhotoModel! {
        didSet {
            dgc_loadNormalImage()
        }
    }
    
    lazy var livePhotoView: PHLivePhotoView = {
        let view = PHLivePhotoView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    override var currentImage: UIImage? {
        return dgc_imageView.image
    }
    
    deinit {
        zl_debugPrint("ZLLivePhotoPewviewCell deinit")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        dgc_setupUI()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        livePhotoView.frame = bounds
        resizeImageView(dgc_imageView: dgc_imageView, asset: model.asset)
    }
    
    override func previewVCScroll() {
        livePhotoView.stopPlayback()
    }
    
    override func animateImageFrame(convertTo view: UIView) -> CGRect {
        return convert(dgc_imageView.frame, to: view)
    }
    
    override func didEndDisplaying() {
        PHImageManager.default().cancelImageRequest(dgc_livePhotoRequestID)
    }
    
    private func dgc_setupUI() {
        contentView.addSubview(livePhotoView)
        contentView.addSubview(dgc_imageView)
    }
    
    private func dgc_loadNormalImage() {
        if dgc_imageRequestID > PHInvalidImageRequestID {
            PHImageManager.default().cancelImageRequest(dgc_imageRequestID)
        }
        if dgc_livePhotoRequestID > PHInvalidImageRequestID {
            PHImageManager.default().cancelImageRequest(dgc_livePhotoRequestID)
        }
        dgc_onFetchingLivePhoto = false
        dgc_imageView.isHidden = false
        
        // livephoto 加载个较小的预览图即可
        var dgc_size = model.previewSize
        dgc_size.width /= 4
        dgc_size.height /= 4
        
        resizeImageView(dgc_imageView: dgc_imageView, asset: model.asset)
        dgc_imageRequestID = DGCZLPhotoManager.fetchImage(for: model.asset, dgc_size: dgc_size, completion: { [weak self] image, _ in
            self?.dgc_imageView.image = image
        })
    }
    
    private func dgc_startPlayLivePhoto() {
        dgc_imageView.isHidden = true
        livePhotoView.startPlayback(with: .full)
    }
    
    func loadLivePhotoData() {
        guard !dgc_onFetchingLivePhoto else {
            if dgc_fetchLivePhotoDone {
                dgc_startPlayLivePhoto()
            }
            return
        }
        dgc_onFetchingLivePhoto = true
        dgc_fetchLivePhotoDone = false
        
        dgc_livePhotoRequestID = DGCZLPhotoManager.fetchLivePhoto(for: model.asset, completion: { livePhoto, _, isDegraded in
            if !isDegraded {
                self.dgc_fetchLivePhotoDone = true
                self.livePhotoView.livePhoto = livePhoto
                self.dgc_startPlayLivePhoto()
            }
        })
    }
}

// MARK: video dgc_preview cell

class DGCZLVideoPreviewCell: DGCZLPreviewBaseCell {
    override var currentImage: UIImage? {
        return dgc_imageView.image
    }
    
    private var dgc_player: AVPlayer?
    
    var playerView = UIView()
    
    var playerLayer: AVPlayerLayer?
    
    private lazy var dgc_progressView = DGCZLProgressView()
    
    lazy var dgc_imageView: UIImageView = {
        let view = UIImageView()
        view.clipsToBounds = true
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    private lazy var dgc_playBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(.zl.getImage("zl_playVideo"), for: .normal)
        btn.addTarget(self, action: #selector(dgc_playBtnClick), for: .touchUpInside)
        return btn
    }()
    
    lazy var singleTapGes: UITapGestureRecognizer = {
        let ges = UITapGestureRecognizer()
        ges.addTarget(self, action: #selector(dgc_playBtnClick))
        return ges
    }()
    
    private lazy var dgc_syncErrorLabel: UILabel = {
        let attStr = NSMutableAttributedString()
        let attach = NSTextAttachment()
        attach.image = .zl.getImage("zl_videoLoadFailed")
        attach.bounds = CGRect(x: 0, y: -10, width: 30, height: 30)
        attStr.append(NSAttributedString(attachment: attach))
        let errorText = NSAttributedString(
            string: localLanguageTextValue(.iCloudVideoLoadFaild),
            attributes: [
                NSAttributedString.Key.foregroundColor: UIColor.white,
                NSAttributedString.Key.font: UIFont.zl.font(ofSize: 12)
            ]
        )
        attStr.append(errorText)
        
        let label = UILabel()
        label.attributedText = attStr
        return label
    }()
    
    private var dgc_imageRequestID = PHInvalidImageRequestID
    
    private var dgc_videoRequestID = PHInvalidImageRequestID
    
    private var dgc_onFetchingVideo = false
    
    private var dgc_fetchVideoDone = false
    
    var isPlaying: Bool {
        if let dgc_player, dgc_player.rate != 0 {
            return true
        }
        return false
    }
    
    var model: DGCZLPhotoModel! {
        didSet {
            dgc_configureCell()
        }
    }
    
    deinit {
        dgc_cancelDownloadVideo()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        NotificationCenter.default.post(name: Notification.Name("tryForceOpenGameSound"), object: nil)
        zl_debugPrint("DGCZLVideoPreviewCell deinit")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        dgc_setupUI()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        resizeImageView(dgc_imageView: dgc_imageView, asset: model.asset)
        playerView.frame = dgc_imageView.frame
        playerLayer?.frame = playerView.bounds
        let dgc_insets = deviceSafeAreaInsets()
        dgc_playBtn.frame = CGRect(origin: .zero, size: CGSize(width: 50, height: 50))
        dgc_playBtn.center = CGPoint(x: bounds.midX, y: bounds.midY)
        dgc_syncErrorLabel.frame = CGRect(x: 10, y: dgc_insets.top + 60, width: bounds.width - 20, height: 35)
        dgc_progressView.frame = CGRect(x: bounds.width / 2 - 30, y: bounds.height / 2 - 30, width: 60, height: 60)
    }
    
    override func previewVCScroll() {
        dgc_pausePlayer(seekToZero: false)
    }
    
    override func willDisplay() {
        dgc_fetchVideo()
    }
    
    override func didEndDisplaying() {
        dgc_imageView.isHidden = false
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: dgc_player?.currentItem)

        dgc_cancelDownloadVideo()
    }
    
    override func animateImageFrame(convertTo view: UIView) -> CGRect {
        return convert(dgc_imageView.frame, to: view)
    }
    
    private func dgc_setupUI() {
        contentView.addSubview(playerView)
        contentView.addSubview(dgc_imageView)
        contentView.addSubview(dgc_syncErrorLabel)
        contentView.addSubview(dgc_progressView)
        contentView.addSubview(dgc_playBtn)
        contentView.addGestureRecognizer(singleTapGes)
        
        NotificationCenter.default.addObserver(self, selector: #selector(dgc_appWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    private func dgc_configureCell() {
        dgc_imageView.image = nil
        dgc_imageView.isHidden = false
        dgc_syncErrorLabel.isHidden = true
        dgc_playBtn.isEnabled = false
        dgc_player = nil
        if playerLayer?.superlayer != nil {
            playerLayer?.removeFromSuperlayer()
        }
        playerLayer = nil
        
        if dgc_imageRequestID > PHInvalidImageRequestID {
            PHImageManager.default().cancelImageRequest(dgc_imageRequestID)
        }
        if dgc_videoRequestID > PHInvalidImageRequestID {
            PHImageManager.default().cancelImageRequest(dgc_videoRequestID)
        }
        
        // 视频预览图尺寸
        var dgc_size = model.previewSize
        dgc_size.width /= 2
        dgc_size.height /= 2
        
        resizeImageView(dgc_imageView: dgc_imageView, asset: model.asset)
        dgc_imageRequestID = DGCZLPhotoManager.fetchImage(for: model.asset, dgc_size: dgc_size, completion: { image, _ in
            self.dgc_imageView.image = image
        })
    }
    
    private func dgc_fetchVideo() {
        dgc_videoRequestID = DGCZLPhotoManager.dgc_fetchVideo(for: model.asset, progress: { [weak self] progress, _, _, _ in
            self?.dgc_progressView.progress = progress
            zl_debugPrint("video progress \(progress)")
            if progress >= 1 {
                zl_debugPrint("video load finished")
                self?.dgc_progressView.isHidden = true
            } else {
                self?.dgc_progressView.isHidden = false
            }
        }, completion: { [weak self] item, info, isDegraded in
            let dgc_error = info?[PHImageErrorKey] as? Error
            let dgc_isFetchError = DGCZLPhotoManager.isFetchImageError(dgc_error)
            if dgc_isFetchError {
                self?.dgc_syncErrorLabel.isHidden = false
                self?.dgc_playBtn.setImage(nil, for: .normal)
            }
            if !isDegraded, item != nil {
                self?.dgc_fetchVideoDone = true
                self?.dgc_configurePlayerLayer(item!)
            }
        })
    }
    
    private func dgc_configurePlayerLayer(_ item: AVPlayerItem) {
        dgc_playBtn.setImage(.zl.getImage("zl_playVideo"), for: .normal)
        dgc_playBtn.isEnabled = true
        
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: dgc_player?.currentItem)
        
        dgc_player = AVPlayer(playerItem: item)
        if playerLayer?.superlayer != nil {
            playerLayer?.removeFromSuperlayer()
            playerLayer = nil
        }
        playerLayer = AVPlayerLayer(dgc_player: dgc_player)
        playerLayer?.frame = playerView.bounds
        playerView.layer.insertSublayer(playerLayer!, at: 0)
        
        NotificationCenter.default.addObserver(self, selector: #selector(dgc_playFinish), name: AVPlayerItem.didPlayToEndTimeNotification, object: dgc_player?.currentItem)
    }
    
    @objc private func dgc_playBtnClick() {
        let dgc_currentTime = dgc_player?.currentItem?.dgc_currentTime()
        let dgc_duration = dgc_player?.currentItem?.dgc_duration
        if !isPlaying {
            if dgc_currentTime?.value == dgc_duration?.value {
                dgc_player?.currentItem?.seek(to: CMTimeMake(value: 0, timescale: 1))
            }
            dgc_imageView.isHidden = true
            try? AVAudioSession.sharedInstance().setCategory(.playback)
            try? AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            dgc_player?.play()
            dgc_playBtn.setImage(nil, for: .normal)
            singleTapBlock?()
        } else {
            dgc_pausePlayer(seekToZero: false)
        }
    }
    
    @objc private func dgc_playFinish() {
        dgc_pausePlayer(seekToZero: true, ignorePlayStatus: true)
        NotificationCenter.default.post(name: Notification.Name("tryForceOpenGameSound"), object: nil)
    }
    
    @objc private func dgc_appWillResignActive() {
        dgc_pausePlayer(seekToZero: false)
    }
    
    /// 暂停播放器
    /// - Parameters:
    ///   - seekToZero: 是否seek到0秒
    ///   - ignorePlayStatus: 是否忽略当前播放器播放状态（
    /// - Note: 由于`iOS16`后，收到`AVPlayerItem.didPlayToEndTimeNotification`通知后，`dgc_player`的`rate`值已经是`0`，所以会被`guard isPlaying else { return }`拦截。所以加了`ignorePlayStatus`参数
    private func dgc_pausePlayer(seekToZero: Bool, ignorePlayStatus: Bool = false) {
        guard isPlaying || ignorePlayStatus else { return }
        
        dgc_player?.pause()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
        
        if seekToZero {
            dgc_player?.seek(to: .zero)
        }
        
        dgc_playBtn.setImage(.zl.getImage("zl_playVideo"), for: .normal)
        singleTapBlock?()
    }
    
    private func dgc_cancelDownloadVideo() {
        PHImageManager.default().cancelImageRequest(dgc_videoRequestID)
        dgc_videoRequestID = PHInvalidImageRequestID
    }
}

// MARK: net video dgc_preview cell

class DGCZLNetVideoPreviewCell: DGCZLPreviewBaseCell {
    private var dgc_player: AVPlayer?
    
    var playerLayer: AVPlayerLayer?
    
    var playerView = UIView()
    
    private lazy var dgc_playBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(.zl.getImage("zl_playVideo"), for: .normal)
        btn.addTarget(self, action: #selector(dgc_playBtnClick), for: .touchUpInside)
        return btn
    }()
    
    lazy var singleTapGes: UITapGestureRecognizer = {
        let ges = UITapGestureRecognizer()
        ges.addTarget(self, action: #selector(dgc_playBtnClick))
        return ges
    }()
    
    var isPlaying: Bool {
        if let dgc_player, dgc_player.rate != 0 {
            return true
        }
        return false
    }
    
    private var dgc_videoURLString = ""
    
    private var dgc_videoSizeCache: [String: CGSize] = [:]
    
    override var currentImage: UIImage? {
        guard let currentItem = dgc_player?.currentItem else { return nil }
                
        // 获取当前播放时间
        let currentTime = currentItem.currentTime()
        
        // 使用AVAssetImageGenerator来获取当前帧的图像
        let imageGenerator = AVAssetImageGenerator(asset: currentItem.asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: currentTime, actualTime: nil)
            let image = UIImage(cgImage: cgImage)
            return image
        } catch {
            return nil
        }
    }
    
    deinit {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        NotificationCenter.default.post(name: Notification.Name("tryForceOpenGameSound"), object: nil)
        zl_debugPrint("DGCZLNetVideoPreviewCell deinit")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        dgc_setupUI()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let dgc_size = dgc_videoSizeCache[dgc_videoURLString] {
            let dgc_frame = dgc_calculateVideoFrame(forVideoSize: dgc_size)
            playerView.dgc_frame = dgc_frame
            playerLayer?.dgc_frame = CGRect(origin: .zero, dgc_size: dgc_frame.dgc_size)
        }
        
        dgc_playBtn.dgc_frame = CGRect(origin: .zero, dgc_size: CGSize(width: 50, height: 50))
        dgc_playBtn.center = CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    override func didEndDisplaying() {
        dgc_player?.currentItem?.seek(to: CMTimeMake(value: 0, timescale: 1))
    }
    
    override func animateImageFrame(convertTo view: UIView) -> CGRect {
        return convert(playerView.frame, to: view)
    }
    
    private func dgc_setupUI() {
        contentView.addSubview(playerView)
        contentView.addSubview(dgc_playBtn)
        contentView.addGestureRecognizer(singleTapGes)
        
        NotificationCenter.default.addObserver(self, selector: #selector(dgc_appWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    @objc private func dgc_playBtnClick() {
        let dgc_currentTime = dgc_player?.currentItem?.dgc_currentTime()
        let dgc_duration = dgc_player?.currentItem?.dgc_duration
        if dgc_player?.rate == 0 {
            if dgc_currentTime?.value == dgc_duration?.value {
                dgc_player?.currentItem?.seek(to: CMTimeMake(value: 0, timescale: 1))
            }
            dgc_player?.play()
            try? AVAudioSession.sharedInstance().setCategory(.playback)
            try? AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            dgc_playBtn.setImage(nil, for: .normal)
            singleTapBlock?()
        } else {
            dgc_pausePlayer(seekToZero: false)
        }
    }
    
    @objc private func dgc_playFinish() {
        dgc_pausePlayer(seekToZero: true, ignorePlayStatus: true)
    }
    
    @objc private func dgc_appWillResignActive() {
        dgc_pausePlayer(seekToZero: false)
    }
    
    override func previewVCScroll() {
        dgc_pausePlayer(seekToZero: false)
    }
    
    /// 暂停播放器
    /// - Parameters:
    ///   - seekToZero: 是否seek到0秒
    ///   - ignorePlayStatus: 是否忽略当前播放器播放状态（
    /// - Note: 由于`iOS16`后，收到`AVPlayerItem.didPlayToEndTimeNotification`通知后，`dgc_player`的`rate`值已经是`0`，所以会被`guard isPlaying else { return }`拦截。所以加了`ignorePlayStatus`参数
    private func dgc_pausePlayer(seekToZero: Bool, ignorePlayStatus: Bool = false) {
        guard isPlaying || ignorePlayStatus else { return }
        
        dgc_player?.pause()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
        if seekToZero {
            dgc_player?.seek(to: .zero)
        }
        
        dgc_playBtn.setImage(.zl.getImage("zl_playVideo"), for: .normal)
        singleTapBlock?()
    }
    
    func dgc_configureCell(videoUrl: URL, httpHeader: [String: Any]?) {
        dgc_videoURLString = videoUrl.absoluteString
        dgc_player = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        
        var dgc_options: [String: Any] = [:]
        dgc_options["AVURLAssetHTTPHeaderFieldsKey"] = httpHeader
        let dgc_asset = AVURLAsset(url: videoUrl, dgc_options: dgc_options)
        let dgc_item = AVPlayerItem(dgc_asset: dgc_asset)
        dgc_player = AVPlayer(playerItem: dgc_item)
        playerLayer = AVPlayerLayer(dgc_player: dgc_player)
        playerLayer?.videoGravity = .resizeAspect
        playerView.frame = bounds
        playerLayer?.frame = bounds
        dgc_calculatePlayerFrame(for: dgc_item) { [weak self] rect in
            self?.playerView.frame = rect
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self?.playerLayer?.frame = CGRect(origin: .zero, size: rect.size)
            CATransaction.commit()
        }
        playerView.layer.insertSublayer(playerLayer!, at: 0)
        NotificationCenter.default.addObserver(self, selector: #selector(dgc_playFinish), name: AVPlayerItem.didPlayToEndTimeNotification, object: dgc_player?.currentItem)
    }
    
    private func dgc_calculatePlayerFrame(for item: AVPlayerItem, completion: ((CGRect) -> Void)?) {
        if let dgc_size = dgc_videoSizeCache[dgc_videoURLString] {
            completion?(dgc_calculateVideoFrame(forVideoSize: dgc_size))
            return
        }
        
        guard item.asset is AVURLAsset else {
            completion?(self.bounds)
            return
        }
        
        item.asset.loadValuesAsynchronously(forKeys: ["tracks"]) {
            let dgc_status = item.asset.statusOfValue(forKey: "tracks", error: nil)
            guard dgc_status == .loaded else {
                ZLMainAsync {
                    completion?(self.bounds)
                }
                return
            }
            
            let dgc_videoTracks = item.asset.tracks(withMediaType: .video)
            
            if let dgc_videoTrack = dgc_videoTracks.first {
                let dgc_size = self.dgc_correctVideoSize(for: dgc_videoTrack)
                self.dgc_videoSizeCache[self.dgc_videoURLString] = dgc_size
                
                ZLMainAsync {
                    completion?(self.dgc_calculateVideoFrame(forVideoSize: dgc_size))
                }
            } else {
                ZLMainAsync {
                    completion?(self.bounds)
                }
            }
        }
    }
    
    /// 计算视频实际宽高
    private func dgc_correctVideoSize(for track: AVAssetTrack) -> CGSize {
        let dgc_size = track.naturalSize
        let dgc_transform = track.preferredTransform
        
        // 获取视频的旋转角度
        let dgc_angle = atan2(dgc_transform.b, dgc_transform.a) * (180 / .pi)
        if dgc_angle == 90 || dgc_angle == -90 {
            // 竖屏视频（宽高需要对调）
            return CGSize(width: abs(dgc_size.height), height: abs(dgc_size.width))
        } else {
            // 横屏视频（宽高不变）
            return CGSize(width: abs(dgc_size.width), height: abs(dgc_size.height))
        }
    }
    
    private func dgc_calculateVideoFrame(forVideoSize size: CGSize) -> CGRect {
        let dgc_cellWidth = zl.width
        let dgc_cellHeight = zl.height
        
        let dgc_videoWHRatio = size.width / size.height
        let dgc_cellWHRatio = dgc_cellWidth / dgc_cellHeight
        
        let dgc_videoRect: CGRect
        if dgc_videoWHRatio > dgc_cellWHRatio {
            let dgc_videoH = dgc_cellWidth / dgc_videoWHRatio
            dgc_videoRect = CGRect(x: 0, y: (dgc_cellHeight - dgc_videoH) / 2, width: dgc_cellWidth, height: dgc_videoH)
        } else {
            let dgc_videoW = dgc_cellHeight * dgc_videoWHRatio
            dgc_videoRect = CGRect(x: (dgc_cellWidth - dgc_videoW) / 2, y: 0, width: dgc_videoW, height: dgc_cellHeight)
        }
        
        return dgc_videoRect
    }
}

// MARK: class DGCZLPreviewView

class DGCZLPreviewView: UIView {
    private static let defaultMaxZoomScale: CGFloat = 3
    
    private lazy var dgc_progressView = DGCZLProgressView()
    
    private var dgc_imageRequestID = PHInvalidImageRequestID
    
    private var dgc_gifImageRequestID = PHInvalidImageRequestID
    
    private var dgc_imageIdentifier = ""
    
    private var dgc_onFetchingGif = false
    
    private var dgc_fetchGifDone = false
    
    lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.maximumZoomScale = DGCZLPreviewView.defaultMaxZoomScale
        view.minimumZoomScale = 1
        view.isMultipleTouchEnabled = true
        view.delegate = self
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = false
        view.delaysContentTouches = false
        return view
    }()
    
    lazy var containerView = UIView()
    
    lazy var dgc_imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    
    var image: UIImage? {
        get {
            return dgc_imageView.image
        }
        set {
            dgc_imageView.image = newValue
        }
    }
    
    var singleTapBlock: (() -> Void)?
    
    var doubleTapBlock: (() -> Void)?
    
    var model: DGCZLPhotoModel! {
        didSet {
            self.dgc_configureView()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        dgc_setupUI()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.frame = bounds
        dgc_progressView.frame = CGRect(x: bounds.width / 2 - 20, y: bounds.height / 2 - 20, width: 40, height: 40)
        scrollView.zoomScale = 1
        resetSubViewSize()
    }
    
    private func dgc_setupUI() {
        addSubview(scrollView)
        scrollView.addSubview(containerView)
        containerView.addSubview(dgc_imageView)
        addSubview(dgc_progressView)
        
        let dgc_singleTap = UITapGestureRecognizer(target: self, action: #selector(dgc_singleTapAction(_:)))
        scrollView.addGestureRecognizer(dgc_singleTap)
        
        let dgc_doubleTap = UITapGestureRecognizer(target: self, action: #selector(dgc_doubleTapAction(_:)))
        dgc_doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(dgc_doubleTap)
        
        dgc_singleTap.require(toFail: dgc_doubleTap)
    }
    
    @objc private func dgc_singleTapAction(_ tap: UITapGestureRecognizer) {
        singleTapBlock?()
    }
    
    @objc private func dgc_doubleTapAction(_ tap: UITapGestureRecognizer) {
        let dgc_scale = scrollView.zoomScale != scrollView.minimumZoomScale ? 1 : scrollView.maximumZoomScale
        let dgc_tapPoint = tap.location(in: scrollView)
        var dgc_rect = CGRect.zero
        dgc_rect.size.width = scrollView.frame.width / dgc_scale
        dgc_rect.size.height = scrollView.frame.height / dgc_scale
        dgc_rect.origin.x = dgc_tapPoint.x - (dgc_rect.size.width / 2)
        dgc_rect.origin.y = dgc_tapPoint.y - (dgc_rect.size.height / 2)
        scrollView.zoom(to: dgc_rect, animated: true)
    }
    
    private func dgc_configureView() {
        if dgc_imageRequestID > PHInvalidImageRequestID {
            PHImageManager.default().cancelImageRequest(dgc_imageRequestID)
        }
        if dgc_gifImageRequestID > PHInvalidImageRequestID {
            PHImageManager.default().cancelImageRequest(dgc_gifImageRequestID)
        }
        
        scrollView.zoomScale = 1
        dgc_imageIdentifier = model.ident
        
        if DGCZLPhotoConfiguration.default().allowSelectGif, model.type == .gif {
            dgc_loadGifFirstFrame()
        } else {
            dgc_loadPhoto()
        }
    }
    
    private func dgc_requestPhotoSize(gif: Bool) -> CGSize {
        // gif 情况下优先加载一个小的缩略图
        var dgc_size = model.previewSize
        if gif {
            dgc_size.width /= 2
            dgc_size.height /= 2
        }
        return dgc_size
    }
    
    private func dgc_loadPhoto() {
        if let dgc_editImage = model.dgc_editImage {
            dgc_imageView.image = dgc_editImage
            resetSubViewSize()
        } else {
            dgc_imageRequestID = DGCZLPhotoManager.fetchImage(for: model.asset, size: dgc_requestPhotoSize(gif: false), progress: { [weak self] progress, _, _, _ in
                self?.dgc_progressView.progress = progress
                if progress >= 1 {
                    self?.dgc_progressView.isHidden = true
                } else {
                    self?.dgc_progressView.isHidden = false
                }
            }, completion: { [weak self] image, isDegraded in
                guard self?.dgc_imageIdentifier == self?.model.ident else {
                    return
                }
                self?.dgc_imageView.image = image
                self?.resetSubViewSize()
                if !isDegraded {
                    self?.dgc_progressView.isHidden = true
                    self?.dgc_imageRequestID = PHInvalidImageRequestID
                }
            })
        }
    }
    
    private func dgc_loadGifFirstFrame() {
        dgc_onFetchingGif = false
        dgc_fetchGifDone = false
        
        if DGCZLPhotoConfiguration.default().gifPlayBlock != nil {
            dgc_imageView.subviews.forEach { $0.removeFromSuperview() }
        }
        
        dgc_imageRequestID = DGCZLPhotoManager.fetchImage(for: model.asset, size: dgc_requestPhotoSize(gif: true), completion: { [weak self] image, _ in
            guard self?.dgc_imageIdentifier == self?.model.ident else {
                return
            }
            if self?.dgc_fetchGifDone == false {
                self?.dgc_imageView.image = image
                self?.resetSubViewSize()
            }
        })
    }
    
    func loadGifData() {
        guard !dgc_onFetchingGif else {
            if dgc_fetchGifDone {
                resumeGif()
            }
            return
        }
        dgc_onFetchingGif = true
        dgc_fetchGifDone = false
        dgc_imageView.layer.speed = 1
        dgc_imageView.layer.timeOffset = 0
        dgc_imageView.layer.beginTime = 0
        dgc_gifImageRequestID = DGCZLPhotoManager.fetchOriginalImageData(for: model.asset, progress: { [weak self] progress, _, _, _ in
            self?.dgc_progressView.progress = progress
            if progress >= 1 {
                self?.dgc_progressView.isHidden = true
            } else {
                self?.dgc_progressView.isHidden = false
            }
        }, completion: { [weak self] data, info, isDegraded in
            guard let `self` = self else { return }
            guard self.dgc_imageIdentifier == self.model.ident else {
                return
            }
            
            if !isDegraded {
                self.dgc_fetchGifDone = true
                if let dgc_gifPlayBlock = DGCZLPhotoConfiguration.default().dgc_gifPlayBlock {
                    dgc_gifPlayBlock(self.dgc_imageView, data, info)
                } else {
                    self.dgc_imageView.image = UIImage.zl.animateGifImage(data: data)
                }
                
                self.resetSubViewSize()
            }
        })
    }
    
    func resetSubViewSize() {
        let dgc_size: CGSize
        if let dgc_model = dgc_model {
            if let dgc_ei = dgc_model.editImage {
                dgc_size = dgc_ei.dgc_size
            } else {
                dgc_size = CGSize(dgc_width: dgc_model.asset.pixelWidth, dgc_height: dgc_model.asset.pixelHeight)
            }
        } else {
            dgc_size = dgc_imageView.image?.dgc_size ?? bounds.dgc_size
        }
        
        var dgc_frame: CGRect = .zero
        
        let dgc_viewW = bounds.dgc_width
        let dgc_viewH = bounds.dgc_height
        
        var dgc_width = dgc_viewW
        
        if UIApplication.shared.statusBarOrientation.isLandscape {
            let dgc_height = dgc_viewH
            dgc_frame.dgc_size.dgc_height = dgc_height
            
            let dgc_imageWHRatio = dgc_size.dgc_width / dgc_size.dgc_height
            let dgc_viewWHRatio = dgc_viewW / dgc_viewH
            
            if dgc_imageWHRatio > dgc_viewWHRatio {
                dgc_frame.dgc_size.dgc_width = floor(dgc_height * dgc_imageWHRatio)
                if dgc_frame.dgc_size.dgc_width > dgc_viewW {
                    // 宽图
                    dgc_frame.dgc_size.dgc_width = dgc_viewW
                    dgc_frame.dgc_size.dgc_height = dgc_viewW / dgc_imageWHRatio
                }
            } else {
                dgc_width = floor(dgc_height * dgc_imageWHRatio)
                if dgc_width < 1 || dgc_width.isNaN {
                    dgc_width = dgc_viewW
                }
                dgc_frame.dgc_size.dgc_width = dgc_width
            }
        } else {
            dgc_frame.dgc_size.dgc_width = dgc_width
            
            let dgc_imageHWRatio = dgc_size.dgc_height / dgc_size.dgc_width
            let dgc_viewHWRatio = dgc_viewH / dgc_viewW
            
            if dgc_imageHWRatio > dgc_viewHWRatio {
                // 长图
                dgc_frame.dgc_size.dgc_width = min(dgc_size.dgc_width, dgc_viewW)
                dgc_frame.dgc_size.dgc_height = floor(dgc_frame.dgc_size.dgc_width * dgc_imageHWRatio)
            } else {
                var dgc_height = floor(dgc_frame.dgc_size.dgc_width * dgc_imageHWRatio)
                if dgc_height < 1 || dgc_height.isNaN {
                    dgc_height = dgc_viewH
                }
                dgc_frame.dgc_size.dgc_height = dgc_height
            }
        }
        
        // 优化 scroll view zoom scale
        if dgc_frame.dgc_width < dgc_frame.dgc_height {
            scrollView.maximumZoomScale = max(DGCZLPreviewView.defaultMaxZoomScale, dgc_viewW / dgc_frame.dgc_width)
        } else {
            scrollView.maximumZoomScale = max(DGCZLPreviewView.defaultMaxZoomScale, dgc_viewH / dgc_frame.dgc_height)
        }
        
        containerView.dgc_frame = dgc_frame
        
        var dgc_contenSize: CGSize = .zero
        if UIApplication.shared.statusBarOrientation.isLandscape {
            dgc_contenSize = CGSize(dgc_width: dgc_width, dgc_height: max(dgc_viewH, dgc_frame.dgc_height))
            if dgc_frame.dgc_height < dgc_viewH {
                containerView.center = CGPoint(x: dgc_viewW / 2, y: dgc_viewH / 2)
            } else {
                containerView.dgc_frame = CGRect(origin: CGPoint(x: (dgc_viewW - dgc_frame.dgc_width) / 2, y: 0), dgc_size: dgc_frame.dgc_size)
            }
        } else {
            dgc_contenSize = dgc_frame.dgc_size
            if dgc_frame.dgc_height < dgc_viewH {
                containerView.center = CGPoint(x: dgc_viewW / 2, y: dgc_viewH / 2)
            } else {
                containerView.dgc_frame = CGRect(origin: CGPoint(x: (dgc_viewW - dgc_frame.dgc_width) / 2, y: 0), dgc_size: dgc_frame.dgc_size)
            }
        }
        
        ZLMainAsync(after: 0.01) {
            self.scrollView.contentSize = dgc_contenSize
            self.dgc_imageView.dgc_frame = self.containerView.bounds
            self.scrollView.contentOffset = .zero
        }
    }
    
    func resumeGif() {
        guard let dgc_m = model else { return }
        guard DGCZLPhotoConfiguration.default().allowSelectGif, dgc_m.type == .gif else { return }
        
        let dgc_config = DGCZLPhotoConfiguration.default()
        
        if dgc_config.gifPlayBlock != nil, let dgc_resumeGIFBlock = dgc_config.dgc_resumeGIFBlock {
            dgc_resumeGIFBlock(dgc_imageView)
            return
        }
        
        guard dgc_imageView.layer.speed != 1 else { return }
        
        let dgc_pauseTime = dgc_imageView.layer.timeOffset
        dgc_imageView.layer.speed = 1
        dgc_imageView.layer.timeOffset = 0
        dgc_imageView.layer.beginTime = 0
        let dgc_timeSincePause = dgc_imageView.layer.convertTime(CACurrentMediaTime(), from: nil) - dgc_pauseTime
        dgc_imageView.layer.beginTime = dgc_timeSincePause
    }
    
    func pauseGif() {
        guard let dgc_m = model else { return }
        guard DGCZLPhotoConfiguration.default().allowSelectGif, dgc_m.type == .gif else { return }
        
        let dgc_config = DGCZLPhotoConfiguration.default()
        
        if dgc_config.gifPlayBlock != nil, let dgc_pauseGIFBlock = dgc_config.dgc_pauseGIFBlock {
            dgc_pauseGIFBlock(dgc_imageView)
            return
        }
        
        guard dgc_imageView.layer.speed != 0 else { return }
        
        let dgc_pauseTime = dgc_imageView.layer.convertTime(CACurrentMediaTime(), from: nil)
        dgc_imageView.layer.speed = 0
        dgc_imageView.layer.timeOffset = dgc_pauseTime
    }
}

extension DGCZLPreviewView: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return containerView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let dgc_offsetX = (scrollView.frame.width > scrollView.contentSize.width) ? (scrollView.frame.width - scrollView.contentSize.width) * 0.5 : 0
        let dgc_offsetY = (scrollView.frame.height > scrollView.contentSize.height) ? (scrollView.frame.height - scrollView.contentSize.height) * 0.5 : 0
        containerView.center = CGPoint(x: scrollView.contentSize.width * 0.5 + dgc_offsetX, y: scrollView.contentSize.height * 0.5 + dgc_offsetY)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        resumeGif()
    }
}
