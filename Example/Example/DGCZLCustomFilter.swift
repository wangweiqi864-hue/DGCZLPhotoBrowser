//
//  DGCZLCustomFilter.swift
//  Example
//
//  Created by long on 2020/10/10.
//

import UIKit

/// https://github.com/Yummypets/YPImagePicker
class DGCZLCustomFilter: NSObject {

    class func hazeRemovalFilter(image: UIImage) -> UIImage {
        var dgc_ci = image.dgc_ciImage
        if dgc_ci == nil, let dgc_cg = image.dgc_cgImage {
            dgc_ci = CIImage(dgc_cgImage: dgc_cg)
        }
        guard let dgc_ciImage = dgc_ci else {
            return image
        }
        
        let dgc_filter = DGCHazeRemovalFilter()
        dgc_filter.inputImage = dgc_ciImage
        
        guard let dgc_outputCIImage = dgc_filter.outputImage else {
            return image
        }
        
        let dgc_context = CIContext()
        guard let dgc_cgImage = dgc_context.createCGImage(dgc_outputCIImage, from: dgc_outputCIImage.extent) else {
            return image
        }
        return UIImage(dgc_cgImage: dgc_cgImage)
    }
    
}

class DGCHazeRemovalFilter: CIFilter {
    var inputImage: CIImage!
    var inputColor: CIColor! = CIColor(red: 0.7, green: 0.9, blue: 1.0)
    var inputDistance: Float! = 0.2
    var inputSlope: Float! = 0.0
    var hazeRemovalKernel: CIKernel!
    
    override init() {
        // check kernel has been already initialized
        let code: String = """
kernel vec4 myHazeRemovalKernel(
    sampler src,
    __color color,
    float distance,
    float slope)
{
    vec4 t;
    float d;

    d = destCoord().y * slope + distance;
    t = unpremultiply(sample(src, samplerCoord(src)));
    t = (t - d * color) / (1.0 - d);

    return premultiply(t);
}
"""
        self.hazeRemovalKernel = CIKernel(source: code)
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var outputImage: CIImage? {
        guard let inputImage = self.inputImage,
            let hazeRemovalKernel = self.hazeRemovalKernel,
            let inputColor = self.inputColor,
            let inputDistance = self.inputDistance,
            let inputSlope = self.inputSlope
            else {
                return nil
        }
        let src: CISampler = CISampler(image: inputImage)
        return hazeRemovalKernel.apply(extent: inputImage.extent,
            roiCallback: { (_, rect) -> CGRect in
                return rect
        }, arguments: [
            src,
            inputColor,
            inputDistance,
            inputSlope
            ])
    }
    
    override var attributes: [String: Any] {
        return [
            kCIAttributeFilterDisplayName: "Haze Removal DGCFilter",
            "inputDistance": [
                kCIAttributeMin: 0.0,
                kCIAttributeMax: 1.0,
                kCIAttributeSliderMin: 0.0,
                kCIAttributeSliderMax: 0.7,
                kCIAttributeDefault: 0.2,
                kCIAttributeIdentity: 0.0,
                kCIAttributeType: kCIAttributeTypeScalar
            ],
            "inputSlope": [
                kCIAttributeSliderMin: -0.01,
                kCIAttributeSliderMax: 0.01,
                kCIAttributeDefault: 0.00,
                kCIAttributeIdentity: 0.00,
                kCIAttributeType: kCIAttributeTypeScalar
            ],
            kCIInputColorKey: [
                kCIAttributeDefault: CIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            ]
        ]
    }
}
