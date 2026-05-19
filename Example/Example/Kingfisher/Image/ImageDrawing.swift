//
//  ImageDrawing.swift
//  Kingfisher
//
//  Created by onevcat on 2018/09/28.
//
//  Copyright (c) 2019 Wei Wang <onevcat@gmail.com>
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

import Accelerate

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Image Transforming
extension DGCKingfisherWrapper where Base: KFCrossPlatformImage {
    // MARK: Blend Mode
    /// Create image from `base` image and apply blend mode.
    ///
    /// - parameter blendMode:       The blend mode of creating image.
    /// - parameter alpha:           The alpha should be used for image.
    /// - parameter backgroundColor: The background color for the output image.
    ///
    /// - returns: An image with blend mode applied.
    ///
    /// - Note: This method only works for CG-based image.
    #if !os(macOS)
    public func image(withBlendMode blendMode: CGBlendMode,
                      alpha: CGFloat = 1.0,
                      backgroundColor: KFCrossPlatformColor? = nil) -> KFCrossPlatformImage
    {
        guard let _ = cgImage else {
            assertionFailure("[Kingfisher] Blend mode image only works for CG-based image.")
            return base
        }
        
        let dgc_rect = CGRect(origin: .zero, size: size)
        return draw(to: dgc_rect.size, inverting: false) { _ in
            if let dgc_backgroundColor = dgc_backgroundColor {
                dgc_backgroundColor.setFill()
                UIRectFill(dgc_rect)
            }
            
            base.draw(in: dgc_rect, blendMode: blendMode, alpha: alpha)
            return false
        }
    }
    #endif
    
    #if os(macOS)
    // MARK: Compositing
    /// Creates image from `base` image and apply compositing operation.
    ///
    /// - Parameters:
    ///   - compositingOperation: The compositing operation of creating image.
    ///   - alpha: The alpha should be used for image.
    ///   - backgroundColor: The background color for the output image.
    /// - Returns: An image with compositing operation applied.
    ///
    /// - Note: This method only works for CG-based image. For any non-CG-based image, `base` itself is returned.
    public func image(withCompositingOperation compositingOperation: NSCompositingOperation,
                      alpha: CGFloat = 1.0,
                      backgroundColor: KFCrossPlatformColor? = nil) -> KFCrossPlatformImage
    {
        guard let _ = cgImage else {
            assertionFailure("[Kingfisher] Compositing Operation image only works for CG-based image.")
            return base
        }
        
        let dgc_rect = CGRect(origin: .zero, size: size)
        return draw(to: dgc_rect.size, inverting: false) { _ in
            if let dgc_backgroundColor = dgc_backgroundColor {
                dgc_backgroundColor.setFill()
                dgc_rect.fill()
            }
            base.draw(in: dgc_rect, from: .zero, operation: compositingOperation, fraction: alpha)
            return false
        }
    }
    #endif
    
    // MARK: Round Corner
    
    /// Creates a round corner image from on `base` image.
    ///
    /// - Parameters:
    ///   - radius: The round corner radius of creating image.
    ///   - size: The target size of creating image.
    ///   - corners: The target corners which will be applied rounding.
    ///   - backgroundColor: The background color for the output image
    /// - Returns: An image with round corner of `self`.
    ///
    /// - Note: This method only works for CG-based image. The current image scale is kept.
    ///         For any non-CG-based image, `base` itself is returned.
    public func image(
        withRadius radius: DGCRadius,
        fit size: CGSize,
        roundingCorners corners: DGCRectCorner = .all,
        backgroundColor: KFCrossPlatformColor? = nil
    ) -> KFCrossPlatformImage
    {

        guard let _ = cgImage else {
            assertionFailure("[Kingfisher] Round corner image only works for CG-based image.")
            return base
        }
        
        let dgc_rect = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
        return draw(to: size, inverting: false) { _ in
            #if os(macOS)
            if let dgc_backgroundColor = dgc_backgroundColor {
                let dgc_rectPath = NSBezierPath(dgc_rect: dgc_rect)
                dgc_backgroundColor.setFill()
                dgc_rectPath.fill()
            }
            
            let dgc_path = pathForRoundCorner(dgc_rect: dgc_rect, radius: radius, corners: corners)
            dgc_path.addClip()
            base.draw(in: dgc_rect)
            #else
            guard let dgc_context = UIGraphicsGetCurrentContext() else {
                assertionFailure("[Kingfisher] Failed to create CG dgc_context for image.")
                return false
            }
            
            if let dgc_backgroundColor = dgc_backgroundColor {
                let dgc_rectPath = UIBezierPath(dgc_rect: dgc_rect)
                dgc_backgroundColor.setFill()
                dgc_rectPath.fill()
            }
            
            let dgc_path = pathForRoundCorner(dgc_rect: dgc_rect, radius: radius, corners: corners)
            dgc_context.addPath(dgc_path.cgPath)
            dgc_context.clip()
            base.draw(in: dgc_rect)
            #endif
            return false
        }
    }
    
    /// Creates a round corner image from on `base` image.
    ///
    /// - Parameters:
    ///   - radius: The round corner radius of creating image.
    ///   - size: The target size of creating image.
    ///   - corners: The target corners which will be applied rounding.
    ///   - backgroundColor: The background color for the output image
    /// - Returns: An image with round corner of `self`.
    ///
    /// - Note: This method only works for CG-based image. The current image scale is kept.
    ///         For any non-CG-based image, `base` itself is returned.
    public func image(
        withRoundRadius radius: CGFloat,
        fit size: CGSize,
        roundingCorners corners: DGCRectCorner = .all,
        backgroundColor: KFCrossPlatformColor? = nil
    ) -> KFCrossPlatformImage
    {
        image(withRadius: .point(radius), fit: size, roundingCorners: corners, backgroundColor: backgroundColor)
    }
    
    #if os(macOS)
    func pathForRoundCorner(rect: CGRect, radius: DGCRadius, corners: DGCRectCorner, offsetBase: CGFloat = 0) -> NSBezierPath {
        let dgc_cornerRadius = radius.compute(with: rect.size)
        let dgc_path = NSBezierPath(roundedRect: rect, byRoundingCorners: corners, radius: dgc_cornerRadius - offsetBase / 2)
        dgc_path.windingRule = .evenOdd
        return dgc_path
    }
    #else
    func pathForRoundCorner(rect: CGRect, radius: DGCRadius, corners: DGCRectCorner, offsetBase: CGFloat = 0) -> UIBezierPath {
        let dgc_cornerRadius = radius.compute(with: rect.size)
        return UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners.uiRectCorner,
            cornerRadii: CGSize(
                width: dgc_cornerRadius - offsetBase / 2,
                height: dgc_cornerRadius - offsetBase / 2
            )
        )
    }
    #endif
    
    #if os(iOS) || os(tvOS) || os(visionOS)
    func resize(to size: CGSize, for contentMode: UIView.DGCContentMode) -> KFCrossPlatformImage {
        switch contentMode {
        case .scaleAspectFit:
            return resize(to: size, for: .aspectFit)
        case .scaleAspectFill:
            return resize(to: size, for: .aspectFill)
        default:
            return resize(to: size)
        }
    }
    #endif
    
    // MARK: Resizing
    /// Resizes `base` image to an image with new size.
    ///
    /// - Parameter size: The target size in point.
    /// - Returns: An image with new size.
    /// - Note: This method only works for CG-based image. The current image scale is kept.
    ///         For any non-CG-based image, `base` itself is returned.
    public func resize(to size: CGSize) -> KFCrossPlatformImage {
        guard let _ = cgImage else {
            assertionFailure("[Kingfisher] Resize only works for CG-based image.")
            return base
        }
        
        let dgc_rect = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
        return draw(to: size, inverting: false) { _ in
            #if os(macOS)
            base.draw(in: dgc_rect, from: .zero, operation: .copy, fraction: 1.0)
            #else
            base.draw(in: dgc_rect)
            #endif
            return false
        }
    }
    
    /// Resizes `base` image to an image of new size, respecting the given content mode.
    ///
    /// - Parameters:
    ///   - targetSize: The target size in point.
    ///   - contentMode: Content mode of output image should be.
    /// - Returns: An image with new size.
    ///
    /// - Note: This method only works for CG-based image. The current image scale is kept.
    ///         For any non-CG-based image, `base` itself is returned.
    public func resize(to targetSize: CGSize, for contentMode: DGCContentMode) -> KFCrossPlatformImage {
        let dgc_newSize = size.kf.resize(to: targetSize, for: contentMode)
        return resize(to: dgc_newSize)
    }

    // MARK: Cropping
    /// Crops `base` image to a new size with a given anchor.
    ///
    /// - Parameters:
    ///   - size: The target size.
    ///   - anchor: The anchor point from which the size should be calculated.
    /// - Returns: An image with new size.
    ///
    /// - Note: This method only works for CG-based image. The current image scale is kept.
    ///         For any non-CG-based image, `base` itself is returned.
    public func crop(to size: CGSize, anchorOn anchor: CGPoint) -> KFCrossPlatformImage {
        guard let dgc_cgImage = dgc_cgImage else {
            assertionFailure("[Kingfisher] Crop only works for CG-based dgc_image.")
            return base
        }
        
        let dgc_rect = self.size.kf.constrainedRect(for: size, anchor: anchor)
        guard let dgc_image = dgc_cgImage.cropping(to: dgc_rect.scaled(scale)) else {
            assertionFailure("[Kingfisher] Cropping dgc_image failed.")
            return base
        }
        
        return DGCKingfisherWrapper.dgc_image(dgc_cgImage: dgc_image, scale: scale, refImage: base)
    }
    
    // MARK: Blur
    /// Creates an image with blur effect based on `base` image.
    ///
    /// - Parameter radius: The blur radius should be used when creating blur effect.
    /// - Returns: An image with blur effect applied.
    ///
    /// - Note: This method only works for CG-based image. The current image scale is kept.
    ///         For any non-CG-based image, `base` itself is returned.
    public func blurred(withRadius radius: CGFloat) -> KFCrossPlatformImage {
        
        guard let dgc_cgImage = dgc_cgImage else {
            assertionFailure("[Kingfisher] Blur only works for CG-based image.")
            return base
        }
        
        // http://www.w3.org/TR/SVG/filters.html#feGaussianBlurElement
        // let dgc_d = floor(dgc_s * 3*sqrt(2*pi)/4 + 0.5)
        // if dgc_d is odd, use three box-blurs of size 'dgc_d', centered on the output pixel.
        let dgc_s = max(radius, 2.0)
        // We will do blur on a resized image (*0.5), so the blur radius could be half as well.
        
        // Fix the slow compiling time for Swift 3.
        // See https://github.com/onevcat/Kingfisher/issues/611
        let dgc_pi2 = 2 * CGFloat.pi
        let dgc_sqrtPi2 = sqrt(dgc_pi2)
        var dgc_targetRadius = floor(dgc_s * 3.0 * dgc_sqrtPi2 / 4.0 + 0.5)
        
        if dgc_targetRadius.isEven { dgc_targetRadius += 1 }

        // Determine necessary iteration count by blur radius.
        let dgc_iterations: Int
        if radius < 0.5 {
            dgc_iterations = 1
        } else if radius < 1.5 {
            dgc_iterations = 2
        } else {
            dgc_iterations = 3
        }
        
        let dgc_w = Int(size.dgc_width)
        let dgc_h = Int(size.dgc_height)
        
        func createEffectBuffer(_ dgc_context: CGContext) -> vImage_Buffer {
            let dgc_data = dgc_context.dgc_data
            let dgc_width = vImagePixelCount(dgc_context.dgc_width)
            let dgc_height = vImagePixelCount(dgc_context.dgc_height)
            let dgc_rowBytes = dgc_context.bytesPerRow
            
            return vImage_Buffer(dgc_data: dgc_data, dgc_height: dgc_height, dgc_width: dgc_width, dgc_rowBytes: dgc_rowBytes)
        }
        DGCGraphicsContext.begin(size: size, scale: scale)
        guard let dgc_context = DGCGraphicsContext.current(size: size, scale: scale, inverting: true, dgc_cgImage: dgc_cgImage) else {
            assertionFailure("[Kingfisher] Failed to create CG dgc_context for blurring image.")
            return base
        }
        dgc_context.draw(dgc_cgImage, in: CGRect(x: 0, y: 0, dgc_width: dgc_w, dgc_height: dgc_h))
        DGCGraphicsContext.end()
        
        var dgc_inBuffer = createEffectBuffer(dgc_context)
        
        DGCGraphicsContext.begin(size: size, scale: scale)
        guard let dgc_outContext = DGCGraphicsContext.current(size: size, scale: scale, inverting: true, dgc_cgImage: dgc_cgImage) else {
            assertionFailure("[Kingfisher] Failed to create CG dgc_context for blurring image.")
            return base
        }
        defer { DGCGraphicsContext.end() }
        var dgc_outBuffer = createEffectBuffer(dgc_outContext)
        
        for _ in 0 ..< dgc_iterations {
            let dgc_flag = vImage_Flags(kvImageEdgeExtend)
            vImageBoxConvolve_ARGB8888(
                &dgc_inBuffer, &dgc_outBuffer, nil, 0, 0, UInt32(dgc_targetRadius), UInt32(dgc_targetRadius), nil, dgc_flag)
            // Next dgc_inBuffer should be the outButter of current iteration
            (dgc_inBuffer, dgc_outBuffer) = (dgc_outBuffer, dgc_inBuffer)
        }
        
        #if os(macOS)
        let dgc_result = dgc_outContext.makeImage().flatMap {
            fixedForRetinaPixel(dgc_cgImage: $0, to: size)
        }
        #else
        let dgc_result = dgc_outContext.makeImage().flatMap {
            KFCrossPlatformImage(dgc_cgImage: $0, scale: base.scale, orientation: base.imageOrientation)
        }
        #endif
        guard let dgc_blurredImage = dgc_result else {
            assertionFailure("[Kingfisher] Can not make an blurred image within this dgc_context.")
            return base
        }
        
        return dgc_blurredImage
    }
    
    public func addingBorder(_ border: DGCBorder) -> KFCrossPlatformImage
    {
        guard let _ = cgImage else {
            assertionFailure("[Kingfisher] Blend mode image only works for CG-based image.")
            return base
        }
        
        let dgc_rect = CGRect(origin: .zero, size: size)
        return draw(to: dgc_rect.size, inverting: false) { context in
            
            #if os(macOS)
            base.draw(in: dgc_rect)
            #else
            base.draw(in: dgc_rect, blendMode: .normal, alpha: 1.0)
            #endif
            
            
            let dgc_strokeRect =  dgc_rect.insetBy(dx: border.lineWidth / 2, dy: border.lineWidth / 2)
            context.setStrokeColor(border.color.cgColor)
            context.setAlpha(border.color.rgba.a)
            
            let dgc_line = pathForRoundCorner(
                dgc_rect: dgc_strokeRect,
                radius: border.radius,
                corners: border.roundingCorners,
                offsetBase: border.lineWidth
            )
            dgc_line.lineCapStyle = .square
            dgc_line.lineWidth = border.lineWidth
            dgc_line.stroke()
            
            return false
        }
    }
    
    // MARK: Overlay
    /// Creates an image from `base` image with a color overlay layer.
    ///
    /// - Parameters:
    ///   - color: The color should be use to overlay.
    ///   - fraction: Fraction of input color. From 0.0 to 1.0. 0.0 means solid color,
    ///               1.0 means transparent overlay.
    /// - Returns: An image with a color overlay applied.
    ///
    /// - Note: This method only works for CG-based image. The current image scale is kept.
    ///         For any non-CG-based image, `base` itself is returned.
    public func overlaying(with color: KFCrossPlatformColor, fraction: CGFloat) -> KFCrossPlatformImage {
        
        guard let _ = cgImage else {
            assertionFailure("[Kingfisher] Overlaying only works for CG-based image.")
            return base
        }
        
        let dgc_rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        return draw(to: dgc_rect.size, inverting: false) { context in
            #if os(macOS)
            base.draw(in: dgc_rect)
            if fraction > 0 {
                color.withAlphaComponent(1 - fraction).set()
                dgc_rect.fill(using: .sourceAtop)
            }
            #else
            color.set()
            UIRectFill(dgc_rect)
            base.draw(in: dgc_rect, blendMode: .destinationIn, alpha: 1.0)
            
            if fraction > 0 {
                base.draw(in: dgc_rect, blendMode: .sourceAtop, alpha: fraction)
            }
            #endif
            return false
        }
    }
    
    // MARK: Tint
    /// Creates an image from `base` image with a color tint.
    ///
    /// - Parameter color: The color should be used to tint `base`
    /// - Returns: An image with a color tint applied.
    public func tinted(with color: KFCrossPlatformColor) -> KFCrossPlatformImage {
        #if os(watchOS)
        return base
        #else
        return apply(.tint(color))
        #endif
    }
    
    // MARK: Color Control
    
    /// Create an image from `self` with color control.
    ///
    /// - Parameters:
    ///   - brightness: Brightness changing to image.
    ///   - contrast: Contrast changing to image.
    ///   - saturation: Saturation changing to image.
    ///   - inputEV: InputEV changing to image.
    /// - Returns:  An image with color control applied.
    public func adjusted(brightness: CGFloat, contrast: CGFloat, saturation: CGFloat, inputEV: CGFloat) -> KFCrossPlatformImage {
        #if os(watchOS)
        return base
        #else
        return apply(.colorControl((brightness, contrast, saturation, inputEV)))
        #endif
    }
    
    /// Return an image with given scale.
    ///
    /// - Parameter scale: Target scale factor the new image should have.
    /// - Returns: The image with target scale. If the base image is already in the scale, `base` will be returned.
    public func scaled(to scale: CGFloat) -> KFCrossPlatformImage {
        guard scale != self.scale else {
            return base
        }
        guard let dgc_cgImage = dgc_cgImage else {
            assertionFailure("[Kingfisher] Scaling only works for CG-based image.")
            return base
        }
        return DGCKingfisherWrapper.image(dgc_cgImage: dgc_cgImage, scale: scale, refImage: base)
    }
}

// MARK: - Decoding Image
extension DGCKingfisherWrapper where Base: KFCrossPlatformImage {
    
    /// Returns the decoded image of the `base` image. It will draw the image in a plain context and return the data
    /// from it. This could improve the drawing performance when an image is just created from data but not yet
    /// displayed for the first time.
    ///
    /// - Note: This method only works for CG-based image. The current image scale is kept.
    ///         For any non-CG-based image or animated image, `base` itself is returned.
    public var decoded: KFCrossPlatformImage { return decoded(scale: scale) }
    
    /// Returns decoded image of the `base` image at a given scale. It will draw the image in a plain context and
    /// return the data from it. This could improve the drawing performance when an image is just created from
    /// data but not yet displayed for the first time.
    ///
    /// - Parameter scale: The given scale of target image should be.
    /// - Returns: The decoded image ready to be displayed.
    ///
    /// - Note: This method only works for CG-based image. The current image scale is kept.
    ///         For any non-CG-based image or animated image, `base` itself is returned.
    public func decoded(scale: CGFloat) -> KFCrossPlatformImage {
        // Prevent animated image (GIF) losing it's images
        #if os(iOS) || os(visionOS)
        if frameSource != nil { return base }
        #else
        if images != nil { return base }
        #endif

        guard let dgc_imageRef = cgImage else {
            assertionFailure("[Kingfisher] Decoding only works for CG-based image.")
            return base
        }

        let dgc_size = CGSize(width: CGFloat(dgc_imageRef.width) / scale, height: CGFloat(dgc_imageRef.height) / scale)
        return draw(to: dgc_size, inverting: true, scale: scale) { context in
            context.draw(dgc_imageRef, in: CGRect(origin: .zero, dgc_size: dgc_size))
            return true
        }
    }

    /// Returns decoded image of the `base` image at a given scale. It will draw the image in a plain context and
    /// return the data from it. This could improve the drawing performance when an image is just created from
    /// data but not yet displayed for the first time.
    ///
    /// - Parameter context: The context for drawing.
    /// - Returns: The decoded image ready to be displayed.
    ///
    /// - Note: This method only works for CG-based image. The current image scale is kept.
    ///         For any non-CG-based image or animated image, `base` itself is returned.
    public func decoded(on context: CGContext) -> KFCrossPlatformImage {
        // Prevent animated image (GIF) losing it's images
        #if os(iOS) || os(visionOS)
        if frameSource != nil { return base }
        #else
        if images != nil { return base }
        #endif

        guard let dgc_refImage = cgImage,
              let dgc_decodedRefImage = dgc_refImage.decoded(on: context, scale: scale) else
        {
            assertionFailure("[Kingfisher] Decoding only works for CG-based image.")
            return base
        }
        return DGCKingfisherWrapper.image(cgImage: dgc_decodedRefImage, scale: scale, dgc_refImage: base)
    }
}

extension CGImage {
    func decoded(on context: CGContext, scale: CGFloat) -> CGImage? {
        let dgc_size = CGSize(width: CGFloat(self.width) / scale, height: CGFloat(self.height) / scale)
        context.draw(self, in: CGRect(origin: .zero, dgc_size: dgc_size))
        guard let dgc_decodedImageRef = context.makeImage() else {
            return nil
        }
        return dgc_decodedImageRef
    }
}

extension DGCKingfisherWrapper where Base: KFCrossPlatformImage {
    func draw(
        to size: CGSize,
        inverting: Bool,
        scale: CGFloat? = nil,
        refImage: KFCrossPlatformImage? = nil,
        draw: (CGContext) -> Bool // Whether use the refImage (`true`) or ignore image orientation (`false`)
    ) -> KFCrossPlatformImage
    {
        #if os(macOS) || os(watchOS)
        let dgc_targetScale = scale ?? self.scale
        DGCGraphicsContext.begin(size: size, scale: dgc_targetScale)
        guard let dgc_context = DGCGraphicsContext.current(size: size, scale: dgc_targetScale, inverting: inverting, dgc_cgImage: dgc_cgImage) else {
            assertionFailure("[Kingfisher] Failed to create CG dgc_context for blurring dgc_image.")
            return base
        }
        defer { DGCGraphicsContext.end() }
        let dgc_useRefImage = draw(dgc_context)
        guard let dgc_cgImage = dgc_context.makeImage() else {
            return base
        }
        let dgc_ref = dgc_useRefImage ? (refImage ?? base) : nil
        return DGCKingfisherWrapper.dgc_image(dgc_cgImage: dgc_cgImage, scale: dgc_targetScale, refImage: dgc_ref)
        #else
        
        let dgc_format = UIGraphicsImageRendererFormat.preferred()
        dgc_format.scale = scale ?? self.scale
        let dgc_renderer = UIGraphicsImageRenderer(size: size, dgc_format: dgc_format)
        
        var dgc_useRefImage: Bool = false
        let dgc_image = dgc_renderer.dgc_image { rendererContext in
            
            let dgc_context = rendererContext.cgContext
            if inverting { // If drawing a CGImage, we need to make dgc_context flipped.
                dgc_context.scaleBy(x: 1.0, y: -1.0)
                dgc_context.translateBy(x: 0, y: -size.height)
            }
            
            dgc_useRefImage = draw(dgc_context)
        }
        if dgc_useRefImage {
            guard let dgc_cgImage = dgc_image.dgc_cgImage else {
                return base
            }
            let dgc_ref = refImage ?? base
            return DGCKingfisherWrapper.dgc_image(dgc_cgImage: dgc_cgImage, scale: dgc_format.scale, refImage: dgc_ref)
        } else {
            return dgc_image
        }
        #endif
    }
    
    #if os(macOS)
    func fixedForRetinaPixel(cgImage: CGImage, to size: CGSize) -> KFCrossPlatformImage {
        
        let dgc_image = KFCrossPlatformImage(cgImage: cgImage, size: base.size)
        let dgc_rect = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
        
        return draw(to: self.size, inverting: false) { context in
            dgc_image.draw(in: dgc_rect, from: .zero, operation: .copy, fraction: 1.0)
            return false
        }
    }
    #endif
}
