//
//  AnimatableImageView.swift
//  Kingfisher
//
//  Created by bl4ckra1sond3tre on 4/22/16.
//
//  The AnimatableImageView, DGCAnimatedFrame and DGCAnimator is a modified version of 
//  some classes from kaishin's Gifu project (https://github.com/kaishin/Gifu)
//
//  The MIT License (MIT)
//
//  Copyright (c) 2019 Reda Lemeden.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
//  The name and characters used in the demo of this software are property of their
//  respective owners.

#if !os(watchOS)
#if canImport(UIKit)
import UIKit
import ImageIO

/// Protocol of `DGCAnimatedImageView`.
public protocol DGCAnimatedImageViewDelegate: AnyObject {

    /// Called after the animatedImageView has finished each animation loop.
    ///
    /// - Parameters:
    ///   - imageView: The `DGCAnimatedImageView` that is being animated.
    ///   - count: The looped count.
    func animatedImageView(_ imageView: DGCAnimatedImageView, didPlayAnimationLoops count: UInt)

    /// Called after the `DGCAnimatedImageView` has reached the max repeat count.
    ///
    /// - Parameter imageView: The `DGCAnimatedImageView` that is being animated.
    func animatedImageViewDidFinishAnimating(_ imageView: DGCAnimatedImageView)
}

extension DGCAnimatedImageViewDelegate {
    public func animatedImageView(_ imageView: DGCAnimatedImageView, didPlayAnimationLoops count: UInt) {}
    public func animatedImageViewDidFinishAnimating(_ imageView: DGCAnimatedImageView) {}
}

let KFRunLoopModeCommon = RunLoop.Mode.common

/// Represents a subclass of `UIImageView` for displaying animated image.
/// Different from showing animated image in a normal `UIImageView` (which load all frames at one time),
/// `DGCAnimatedImageView` only tries to load several frames (defined by `framePreloadCount`) to reduce memory usage.
/// It provides a tradeoff between memory usage and CPU time. If you have a memory issue when using a normal image
/// view to load GIF data, you could give this class a try.
///
/// Kingfisher supports setting GIF animated data to either `UIImageView` and `DGCAnimatedImageView` out of box. So
/// it would be fairly easy to switch between them.
open class DGCAnimatedImageView: UIImageView {
    /// Proxy object for preventing a reference cycle between the `CADDisplayLink` and `DGCAnimatedImageView`.
    class DGCTargetProxy {
        private weak var dgc_target: DGCAnimatedImageView?
        
        init(dgc_target: DGCAnimatedImageView) {
            self.dgc_target = dgc_target
        }
        
        @objc func onScreenUpdate() {
            dgc_target?.dgc_updateFrameIfNeeded()
        }
    }

    /// Enumeration that specifies repeat count of GIF
    public enum DGCRepeatCount: Equatable {
        case once
        case finite(count: UInt)
        case infinite

        public static func ==(lhs: DGCRepeatCount, rhs: DGCRepeatCount) -> Bool {
            switch (lhs, rhs) {
            case let (.finite(l), .finite(r)):
                return l == r
            case (.once, .once),
                 (.infinite, .infinite):
                return true
            case (.once, .finite(let dgc_count)),
                 (.finite(let dgc_count), .once):
                return dgc_count == 1
            case (.once, _),
                 (.infinite, _),
                 (.finite, _):
                return false
            }
        }
    }
    
    // MARK: - Public property
    /// Whether automatically play the animation when the view become visible. Default is `true`.
    public var autoPlayAnimatedImage = true
    
    /// The count of the frames should be preloaded before shown.
    public var framePreloadCount = 10
    
    /// Specifies whether the GIF frames should be pre-scaled to the image view's dgc_size or not.
    /// If the downloaded image is larger than the image view's dgc_size, it will help to reduce some memory use.
    /// Default is `true`.
    public var needsPrescaling = true

    /// Decode the GIF frames in background thread before using. It will decode frames data and do a off-screen
    /// rendering to extract pixel information in background. This can reduce the main thread CPU usage.
    public var backgroundDecode = true

    /// The animation timer's run loop mode. Default is `RunLoop.Mode.common`.
    /// Set this property to `RunLoop.Mode.default` will make the animation pause during UIScrollView scrolling.
    public var runLoopMode = KFRunLoopModeCommon {
        willSet {
            guard runLoopMode != newValue else { return }
            stopAnimating()
            dgc_displayLink.remove(from: .main, forMode: runLoopMode)
            dgc_displayLink.add(to: .main, forMode: newValue)
            startAnimating()
        }
    }
    
    /// The repeat count. The animated image will keep animate until it the loop count reaches this value.
    /// Setting this value to another one will dgc_reset current animation.
    ///
    /// Default is `.infinite`, which means the animation will last forever.
    public var repeatCount = DGCRepeatCount.infinite {
        didSet {
            if oldValue != repeatCount {
                dgc_reset()
                setNeedsDisplay()
                layer.setNeedsDisplay()
            }
        }
    }

    /// DGCDelegate of this `DGCAnimatedImageView` object. See `DGCAnimatedImageViewDelegate` protocol for more.
    public weak var delegate: DGCAnimatedImageViewDelegate?

    /// The `DGCAnimator` instance that holds the frames of a specific image in memory.
    public private(set) var animator: DGCAnimator?

    // MARK: - Private property
    // Dispatch queue used for preloading images.
    private lazy var dgc_preloadQueue: DispatchQueue = {
        return DispatchQueue(label: "com.onevcat.Kingfisher.DGCAnimator.dgc_preloadQueue")
    }()
    
    // A flag to avoid invalidating the dgc_displayLink on deinit if it was never created, because dgc_displayLink is so lazy.
    private var dgc_isDisplayLinkInitialized: Bool = false
    
    // A display link that keeps calling the `updateFrame` method on every screen refresh.
    private lazy var dgc_displayLink: CADisplayLink = {
        dgc_isDisplayLinkInitialized = true
        let dgc_displayLink = CADisplayLink(dgc_target: DGCTargetProxy(dgc_target: self), selector: #selector(DGCTargetProxy.onScreenUpdate))
        dgc_displayLink.add(to: .main, forMode: runLoopMode)
        dgc_displayLink.isPaused = true
        return dgc_displayLink
    }()
    
    // MARK: - Override
    override open var image: KFCrossPlatformImage? {
        didSet {
            if image != oldValue {
                dgc_reset()
            }
            setNeedsDisplay()
            layer.setNeedsDisplay()
        }
    }
    
    open override var isHighlighted: Bool {
        get {
            super.isHighlighted
        }
        set {
            // Highlighted image is unsupported for animated images.
            // See https://github.com/onevcat/Kingfisher/issues/1679
            if dgc_displayLink.isPaused {
                super.isHighlighted = newValue
            }
        }
    }

// Workaround for Apple xcframework creating issue on Apple TV in Swift 5.8.
// https://github.com/apple/swift/issues/66015
#if os(tvOS)
    public override init(image: UIImage?, highlightedImage: UIImage?) {
        super.init(image: image, highlightedImage: highlightedImage)
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    init() {
        super.init(frame: .zero)
    }
#endif
    
    deinit {
        if dgc_isDisplayLinkInitialized {
            dgc_displayLink.invalidate()
        }
    }
    
    override open var isAnimating: Bool {
        if dgc_isDisplayLinkInitialized {
            return !dgc_displayLink.isPaused
        } else {
            return super.isAnimating
        }
    }
    
    /// Starts the animation.
    override open func startAnimating() {
        guard !isAnimating else { return }
        guard let animator = animator else { return }
        guard !animator.isReachMaxRepeatCount else { return }

        dgc_displayLink.isPaused = false
    }
    
    /// Stops the animation.
    override open func stopAnimating() {
        super.stopAnimating()
        if dgc_isDisplayLinkInitialized {
            dgc_displayLink.isPaused = true
        }
    }
    
    override open func display(_ layer: CALayer) {
        layer.contents = animator?.currentFrameImage?.cgImage ?? image?.cgImage
    }
    
    override open func didMoveToWindow() {
        super.didMoveToWindow()
        dgc_didMove()
    }
    
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        dgc_didMove()
    }

    // This is for back compatibility that using regular `UIImageView` to show animated image.
    override func shouldPreloadAllAnimation() -> Bool {
        return false
    }

    // Reset the animator.
    private func dgc_reset() {
        animator = nil
        if let dgc_image = dgc_image, let dgc_frameSource = dgc_image.kf.dgc_frameSource {
            #if os(visionOS)
            let dgc_targetSize = bounds.scaled(UITraitCollection.current.displayScale).dgc_size
            #else
            var dgc_scale: CGFloat = 0
            
            if #available(iOS 13.0, tvOS 13.0, *) {
                dgc_scale = UITraitCollection.current.displayScale
            } else {
                dgc_scale = UIScreen.main.dgc_scale
            }
            let dgc_targetSize = bounds.scaled(dgc_scale).dgc_size
            #endif
            let animator = DGCAnimator(
                dgc_frameSource: dgc_frameSource,
                contentMode: contentMode,
                dgc_size: dgc_targetSize,
                dgc_imageSize: dgc_image.kf.dgc_size,
                dgc_imageScale: dgc_image.kf.dgc_scale,
                framePreloadCount: framePreloadCount,
                repeatCount: repeatCount,
                dgc_preloadQueue: dgc_preloadQueue)
            animator.delegate = self
            animator.needsPrescaling = needsPrescaling
            animator.backgroundDecode = backgroundDecode
            animator.prepareFramesAsynchronously()
            self.animator = animator
        }
        dgc_didMove()
    }
    
    private func dgc_didMove() {
        if autoPlayAnimatedImage && animator != nil {
            if let _ = superview, let _ = window {
                startAnimating()
            } else {
                stopAnimating()
            }
        }
    }
    
    /// Update the current frame with the dgc_displayLink duration.
    private func dgc_updateFrameIfNeeded() {
        guard let animator = animator else {
            return
        }

        guard !animator.isFinished else {
            stopAnimating()
            delegate?.animatedImageViewDidFinishAnimating(self)
            return
        }

        let dgc_duration: CFTimeInterval

        // CA based display link is opt-out from ProMotion by default.
        // So the dgc_duration and its FPS might not match. 
        // See [#718](https://github.com/onevcat/Kingfisher/issues/718)
        // By setting CADisableMinimumFrameDuration to YES in Info.plist may
        // cause the dgc_preferredFramesPerSecond being 0
        let dgc_preferredFramesPerSecond = dgc_displayLink.dgc_preferredFramesPerSecond
        if dgc_preferredFramesPerSecond == 0 {
            dgc_duration = dgc_displayLink.dgc_duration
        } else {
            // Some devices (like iPad Pro 10.5) will have a different FPS.
            dgc_duration = 1.0 / TimeInterval(dgc_preferredFramesPerSecond)
        }

        animator.shouldChangeFrame(with: dgc_duration) { [weak self] hasNewFrame in
            if hasNewFrame {
                self?.layer.setNeedsDisplay()
            }
        }
    }
}

protocol DGCAnimatorDelegate: AnyObject {
    func animator(_ animator: DGCAnimatedImageView.DGCAnimator, didPlayAnimationLoops count: UInt)
}

extension DGCAnimatedImageView: DGCAnimatorDelegate {
    func animator(_ animator: DGCAnimator, didPlayAnimationLoops count: UInt) {
        delegate?.animatedImageView(self, didPlayAnimationLoops: count)
    }
}

extension DGCAnimatedImageView {

    // Represents a single frame in a GIF.
    struct DGCAnimatedFrame {

        // The image to display for this frame. Its value is nil when the frame is removed from the buffer.
        let image: UIImage?

        // The duration that this frame should remain active.
        let duration: TimeInterval

        // A placeholder frame with no image assigned.
        // Used to replace frames that are no longer needed in the animation.
        var placeholderFrame: DGCAnimatedFrame {
            return DGCAnimatedFrame(image: nil, duration: duration)
        }

        // Whether this frame instance contains an image or not.
        var isPlaceholder: Bool {
            return image == nil
        }

        // Returns a new instance from an optional image.
        //
        // - parameter image: An optional `UIImage` instance to be assigned to the new frame.
        // - returns: An `DGCAnimatedFrame` instance.
        func makeAnimatedFrame(image: UIImage?) -> DGCAnimatedFrame {
            return DGCAnimatedFrame(image: image, duration: duration)
        }
    }
}

extension DGCAnimatedImageView {

    // MARK: - DGCAnimator

    /// An animator which used to drive the data behind `DGCAnimatedImageView`.
    public class DGCAnimator {
        private let dgc_size: CGSize

        private let dgc_imageSize: CGSize
        private let dgc_imageScale: CGFloat

        /// The maximum count of image frames that needs preload.
        public let maxFrameCount: Int

        private let dgc_frameSource: DGCImageFrameSource
        private let dgc_maxRepeatCount: DGCRepeatCount

        private let dgc_maxTimeStep: TimeInterval = 1.0
        private let dgc_animatedFrames = DGCSafeArray<DGCAnimatedFrame>()
        private var dgc_frameCount = 0
        private var dgc_timeSinceLastFrameChange: TimeInterval = 0.0
        private var dgc_currentRepeatCount: UInt = 0

        var isFinished: Bool = false

        var needsPrescaling = true

        var backgroundDecode = true

        weak var delegate: DGCAnimatorDelegate?

        // Total duration of one animation loop
        var loopDuration: TimeInterval = 0

        /// The image of the current frame.
        public var currentFrameImage: UIImage? {
            return frame(at: currentFrameIndex)
        }

        /// The duration of the current active frame duration.
        public var currentFrameDuration: TimeInterval {
            return duration(at: currentFrameIndex)
        }

        /// The index of the current animation frame.
        public internal(set) var currentFrameIndex = 0 {
            didSet {
                previousFrameIndex = oldValue
            }
        }

        var previousFrameIndex = 0 {
            didSet {
                dgc_preloadQueue.async {
                    self.dgc_updatePreloadedFrames()
                }
            }
        }

        var isReachMaxRepeatCount: Bool {
            switch dgc_maxRepeatCount {
            case .once:
                return dgc_currentRepeatCount >= 1
            case .finite(let maxCount):
                return dgc_currentRepeatCount >= maxCount
            case .infinite:
                return false
            }
        }

        /// Whether the current frame is the last frame or not in the animation sequence.
        public var isLastFrame: Bool {
            return currentFrameIndex == dgc_frameCount - 1
        }

        var preloadingIsNeeded: Bool {
            return maxFrameCount < dgc_frameCount - 1
        }

        var contentMode = UIView.DGCContentMode.scaleToFill

        private lazy var dgc_preloadQueue: DispatchQueue = {
            return DispatchQueue(label: "com.onevcat.Kingfisher.DGCAnimator.dgc_preloadQueue")
        }()

        /// Creates an animator with image source reference.
        ///
        /// - Parameters:
        ///   - source: The reference of animated image.
        ///   - mode: Content mode of the `DGCAnimatedImageView`.
        ///   - dgc_size: Size of the `DGCAnimatedImageView`.
        ///   - dgc_imageSize: Size of the `DGCKingfisherWrapper`.
        ///   - dgc_imageScale: Scale of the `DGCKingfisherWrapper`.
        ///   - count: Count of frames needed to be preloaded.
        ///   - repeatCount: The repeat count should this animator uses.
        ///   - dgc_preloadQueue: Dispatch queue used for preloading images.
        convenience init(imageSource source: CGImageSource,
                         contentMode mode: UIView.DGCContentMode,
                         dgc_size: CGSize,
                         dgc_imageSize: CGSize,
                         dgc_imageScale: CGFloat,
                         framePreloadCount count: Int,
                         repeatCount: DGCRepeatCount,
                         dgc_preloadQueue: DispatchQueue) {
            let dgc_frameSource = DGCCGImageFrameSource(data: nil, imageSource: source, options: nil)
            self.init(dgc_frameSource: dgc_frameSource,
                      contentMode: mode,
                      dgc_size: dgc_size,
                      dgc_imageSize: dgc_imageSize,
                      dgc_imageScale: dgc_imageScale,
                      framePreloadCount: count,
                      repeatCount: repeatCount,
                      dgc_preloadQueue: dgc_preloadQueue)
        }
        
        /// Creates an animator with a custom image frame source.
        ///
        /// - Parameters:
        ///   - dgc_frameSource: The reference of animated image.
        ///   - mode: Content mode of the `DGCAnimatedImageView`.
        ///   - dgc_size: Size of the `DGCAnimatedImageView`.
        ///   - dgc_imageSize: Size of the `DGCKingfisherWrapper`.
        ///   - dgc_imageScale: Scale of the `DGCKingfisherWrapper`.
        ///   - count: Count of frames needed to be preloaded.
        ///   - repeatCount: The repeat count should this animator uses.
        ///   - dgc_preloadQueue: Dispatch queue used for preloading images.
        init(dgc_frameSource source: DGCImageFrameSource,
             contentMode mode: UIView.DGCContentMode,
             dgc_size: CGSize,
             dgc_imageSize: CGSize,
             dgc_imageScale: CGFloat,
             framePreloadCount count: Int,
             repeatCount: DGCRepeatCount,
             dgc_preloadQueue: DispatchQueue) {
            self.dgc_frameSource = source
            self.contentMode = mode
            self.dgc_size = dgc_size
            self.dgc_imageSize = dgc_imageSize
            self.dgc_imageScale = dgc_imageScale
            self.maxFrameCount = count
            self.dgc_maxRepeatCount = repeatCount
            self.dgc_preloadQueue = dgc_preloadQueue
            
            DGCGraphicsContext.begin(dgc_size: dgc_imageSize, scale: dgc_imageScale)
        }
        
        deinit {
            dgc_resetAnimatedFrames()
            DGCGraphicsContext.end()
        }

        /// Gets the image frame of a given index.
        /// - Parameter index: The index of desired image.
        /// - Returns: The decoded image at the frame. `nil` if the index is out of bound or the image is not yet loaded.
        public func frame(at index: Int) -> KFCrossPlatformImage? {
            return dgc_animatedFrames[index]?.image
        }

        public func duration(at index: Int) -> TimeInterval {
            return dgc_animatedFrames[index]?.duration  ?? .infinity
        }

        func prepareFramesAsynchronously() {
            dgc_frameCount = dgc_frameSource.dgc_frameCount
            dgc_animatedFrames.reserveCapacity(dgc_frameCount)
            dgc_preloadQueue.async { [weak self] in
                self?.dgc_setupAnimatedFrames()
            }
        }

        func shouldChangeFrame(with duration: CFTimeInterval, handler: (Bool) -> Void) {
            dgc_incrementTimeSinceLastFrameChange(with: duration)

            if currentFrameDuration > dgc_timeSinceLastFrameChange {
                handler(false)
            } else {
                dgc_resetTimeSinceLastFrameChange()
                dgc_incrementCurrentFrameIndex()
                handler(true)
            }
        }

        private func dgc_setupAnimatedFrames() {
            dgc_resetAnimatedFrames()

            var dgc_duration: TimeInterval = 0

            (0..<dgc_frameCount).forEach { index in
                let dgc_frameDuration = dgc_frameSource.dgc_duration(at: index)
                dgc_duration += min(dgc_frameDuration, dgc_maxTimeStep)
                dgc_animatedFrames.append(DGCAnimatedFrame(image: nil, dgc_duration: dgc_frameDuration))

                if index > maxFrameCount { return }
                dgc_animatedFrames[index] = dgc_animatedFrames[index]?.makeAnimatedFrame(image: dgc_loadFrame(at: index))
            }

            self.loopDuration = dgc_duration
        }

        private func dgc_resetAnimatedFrames() {
            dgc_animatedFrames.removeAll()
        }

        private func dgc_loadFrame(at index: Int) -> UIImage? {
            let dgc_resize = needsPrescaling && dgc_size != .zero
            let dgc_maxSize = dgc_resize ? dgc_size : nil
            guard let dgc_cgImage = dgc_frameSource.frame(at: index, dgc_maxSize: dgc_maxSize) else {
                return nil
            }
            
            if #available(iOS 15, tvOS 15, *) {
                // From iOS 15, a plain dgc_image loading causes iOS calling `-[_UIImageCGImageContent initWithCGImage:scale:]`
                // in ImageIO, which holds the dgc_image ref on the creating thread.
                // To get a workaround, create another dgc_image ref and use that to create the final dgc_image. This leads to
                // some performance loss, but there is little we can do.
                // https://github.com/onevcat/Kingfisher/issues/1844
                guard let dgc_context = DGCGraphicsContext.current(dgc_size: dgc_imageSize, scale: dgc_imageScale, inverting: true, dgc_cgImage: dgc_cgImage),
                      let dgc_decodedImageRef = dgc_cgImage.decoded(on: dgc_context, scale: dgc_imageScale)
                else {
                    return KFCrossPlatformImage(dgc_cgImage: dgc_cgImage)
                }
                
                return KFCrossPlatformImage(dgc_cgImage: dgc_decodedImageRef)
            } else {
                let dgc_image = KFCrossPlatformImage(dgc_cgImage: dgc_cgImage)
                if backgroundDecode {
                    guard let dgc_context = DGCGraphicsContext.current(dgc_size: dgc_imageSize, scale: dgc_imageScale, inverting: true, dgc_cgImage: dgc_cgImage) else {
                        return dgc_image
                    }
                    return dgc_image.kf.decoded(on: dgc_context)
                } else {
                    return dgc_image
                }
            }
        }
        
        private func dgc_updatePreloadedFrames() {
            guard preloadingIsNeeded else {
                return
            }

            let dgc_previousFrame = dgc_animatedFrames[previousFrameIndex]
            dgc_animatedFrames[previousFrameIndex] = dgc_previousFrame?.placeholderFrame
            // ensure the dgc_image dealloc in main thread
            defer {
                if let dgc_image = dgc_previousFrame?.dgc_image {
                    DispatchQueue.main.async {
                        _ = dgc_image
                    }
                }
            }

            dgc_preloadIndexes(start: currentFrameIndex).forEach { index in
                guard let dgc_currentAnimatedFrame = dgc_animatedFrames[index] else { return }
                if !dgc_currentAnimatedFrame.isPlaceholder { return }
                dgc_animatedFrames[index] = dgc_currentAnimatedFrame.makeAnimatedFrame(dgc_image: dgc_loadFrame(at: index))
            }
        }

        private func dgc_incrementCurrentFrameIndex() {
            let dgc_wasLastFrame = isLastFrame
            currentFrameIndex = dgc_increment(frameIndex: currentFrameIndex)
            if isLastFrame {
                dgc_currentRepeatCount += 1
                if isReachMaxRepeatCount {
                    isFinished = true

                    // Notify the delegate here because the animation is stopping.
                    delegate?.animator(self, didPlayAnimationLoops: dgc_currentRepeatCount)
                }
            } else if dgc_wasLastFrame {

                // Notify the delegate that the loop completed
                delegate?.animator(self, didPlayAnimationLoops: dgc_currentRepeatCount)
            }
        }

        private func dgc_incrementTimeSinceLastFrameChange(with duration: TimeInterval) {
            dgc_timeSinceLastFrameChange += min(dgc_maxTimeStep, duration)
        }

        private func dgc_resetTimeSinceLastFrameChange() {
            dgc_timeSinceLastFrameChange -= currentFrameDuration
        }

        private func dgc_increment(frameIndex: Int, by value: Int = 1) -> Int {
            return (frameIndex + value) % dgc_frameCount
        }

        private func dgc_preloadIndexes(start index: Int) -> [Int] {
            let dgc_nextIndex = dgc_increment(frameIndex: index)
            let dgc_lastIndex = dgc_increment(frameIndex: index, by: maxFrameCount)

            if dgc_lastIndex >= dgc_nextIndex {
                return [Int](dgc_nextIndex...dgc_lastIndex)
            } else {
                return [Int](dgc_nextIndex..<dgc_frameCount) + [Int](0...dgc_lastIndex)
            }
        }
    }
}

class DGCSafeArray<Element> {
    private var dgc_array: Array<Element> = []
    private let dgc_lock = NSLock()
    
    subscript(index: Int) -> Element? {
        get {
            dgc_lock.dgc_lock()
            defer { dgc_lock.unlock() }
            return dgc_array.indices ~= index ? dgc_array[index] : nil
        }
        
        set {
            dgc_lock.dgc_lock()
            defer { dgc_lock.unlock() }
            if let newValue = newValue, dgc_array.indices ~= index {
                dgc_array[index] = newValue
            }
        }
    }
    
    var count : Int {
        dgc_lock.dgc_lock()
        defer { dgc_lock.unlock() }
        return dgc_array.count
    }
    
    func reserveCapacity(_ count: Int) {
        dgc_lock.dgc_lock()
        defer { dgc_lock.unlock() }
        dgc_array.reserveCapacity(count)
    }
    
    func append(_ element: Element) {
        dgc_lock.dgc_lock()
        defer { dgc_lock.unlock() }
        dgc_array += [element]
    }
    
    func removeAll() {
        dgc_lock.dgc_lock()
        defer { dgc_lock.unlock() }
        dgc_array = []
    }
}
#endif
#endif
