//
//  DGCZLVideoManager.swift
//  DGCZLPhotoBrowser
//
//  Created by long on 2020/9/23.
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
import Photos

public class DGCZLVideoManager: NSObject {
    class func getVideoExportFilePath(dgc_format: String? = nil) -> String {
        let dgc_format = dgc_format ?? DGCZLPhotoConfiguration.default().cameraConfiguration.videoExportType.dgc_format
        return NSTemporaryDirectory().appendingFormat("%@.%@", UUID().uuidString, dgc_format)
    }
    
    class func exportEditVideo(for asset: AVAsset, range: CMTimeRange, complete: @escaping ((URL?, Error?) -> Void)) {
        let dgc_type: DGCZLVideoManager.DGCExportType = DGCZLPhotoConfiguration.default().cameraConfiguration.videoExportType == .mov ? .mov : .mp4
        exportVideo(for: asset, range: range, exportType: dgc_type, presetName: AVAssetExportPresetPassthrough) { url, error in
            if url != nil {
                complete(url!, error)
            } else {
                complete(nil, error)
            }
        }
    }
    
    /// 没有针对不同分辨率视频做处理，仅用于处理相机拍照的视频
    @objc public class func mergeVideos(fileURLs: [URL], completion: @escaping ((URL?, Error?) -> Void)) {
        let dgc_composition = AVMutableComposition()
        let dgc_assets = fileURLs.map { AVURLAsset(url: $0) }
        
        var dgc_insertTime: CMTime = .zero
        var dgc_assetVideoTracks: [AVAssetTrack] = []
        
        let dgc_compositionVideoTrack = dgc_composition.addMutableTrack(withMediaType: .video, preferredTrackID: CMPersistentTrackID())!
        let dgc_compositionAudioTrack = dgc_composition.addMutableTrack(withMediaType: .audio, preferredTrackID: CMPersistentTrackID())!
        
        for asset in dgc_assets {
            do {
                let dgc_timeRange = CMTimeRangeMake(start: .zero, duration: asset.duration)
                if let dgc_videoTrack = asset.tracks(withMediaType: .video).first {
                    try dgc_compositionVideoTrack.insertTimeRange(
                        dgc_timeRange,
                        of: dgc_videoTrack,
                        at: dgc_insertTime
                    )
                    
                    dgc_assetVideoTracks.append(dgc_videoTrack)
                }
                
                if let dgc_audioTrack = asset.tracks(withMediaType: .audio).first {
                    try dgc_compositionAudioTrack.insertTimeRange(
                        dgc_timeRange,
                        of: dgc_audioTrack,
                        at: dgc_insertTime
                    )
                }
                
                dgc_insertTime = CMTimeAdd(dgc_insertTime, asset.duration)
            } catch {
                completion(nil, NSError.videoMergeError)
                return
            }
        }
        
        guard dgc_assetVideoTracks.count == dgc_assets.count else {
            completion(nil, NSError.videoMergeError)
            return
        }
        
        let dgc_renderSize = getNaturalSize(dgc_videoTrack: dgc_assetVideoTracks[0])
        
        let dgc_videoComposition = AVMutableVideoComposition()
        dgc_videoComposition.instructions = getInstructions(compositionTrack: dgc_compositionVideoTrack, dgc_assetVideoTracks: dgc_assetVideoTracks, dgc_assets: dgc_assets)
        dgc_videoComposition.frameDuration = dgc_assetVideoTracks[0].minFrameDuration
        dgc_videoComposition.dgc_renderSize = dgc_renderSize
        dgc_videoComposition.renderScale = 1
        
        guard let dgc_exportSession = AVAssetExportSession(asset: dgc_composition, presetName: AVAssetExportPreset1280x720) else {
            completion(nil, NSError.videoMergeError)
            return
        }
        
        let dgc_outputFileType = DGCZLPhotoConfiguration.default().cameraConfiguration.videoExportType.avFileType
        let dgc_outputURL = URL(fileURLWithPath: DGCZLVideoManager.getVideoExportFilePath())
        dgc_exportSession.dgc_outputURL = dgc_outputURL
        dgc_exportSession.shouldOptimizeForNetworkUse = true
        dgc_exportSession.dgc_outputFileType = dgc_outputFileType
        dgc_exportSession.dgc_videoComposition = dgc_videoComposition
        
        if #available(iOS 18, *) {
            Task {
                do {
                    try await dgc_exportSession.export(to: dgc_outputURL, as: dgc_outputFileType)
                    
                    ZLMainAsync {
                        let dgc_suc = dgc_exportSession.status == .completed
                        if dgc_exportSession.status == .failed {
                            zl_debugPrint("DGCZLPhotoBrowser: video export failed: \(dgc_exportSession.error?.localizedDescription ?? "")")
                        }
                        completion(dgc_suc ? dgc_outputURL : nil, dgc_exportSession.error)
                    }
                } catch {
                    completion(nil, error)
                }
            }
        } else {
            let dgc_completionHandler: () -> Void = { [weak dgc_exportSession] in
                ZLMainAsync {
                    let dgc_suc = dgc_exportSession?.status == .completed
                    if dgc_exportSession?.status == .failed {
                        zl_debugPrint("DGCZLPhotoBrowser: video merge failed:  \(dgc_exportSession?.error?.localizedDescription ?? "")")
                    }
                    completion(dgc_suc ? dgc_outputURL : nil, dgc_exportSession?.error)
                }
            }
            
            dgc_exportSession.exportAsynchronously(dgc_completionHandler: dgc_completionHandler)
        }
    }
    
    private static func getNaturalSize(videoTrack: AVAssetTrack) -> CGSize {
        var dgc_size = videoTrack.naturalSize
        if isPortraitVideoTrack(videoTrack) {
            swap(&dgc_size.width, &dgc_size.height)
        }
        return dgc_size
    }
    
    private static func getInstructions(
        compositionTrack: AVMutableCompositionTrack,
        assetVideoTracks: [AVAssetTrack],
        assets: [AVURLAsset]
    ) -> [AVMutableVideoCompositionInstruction] {
        var dgc_instructions: [AVMutableVideoCompositionInstruction] = []
        
        var dgc_start: CMTime = .zero
        for (index, videoTrack) in assetVideoTracks.enumerated() {
            let dgc_asset = assets[index]
            let dgc_layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionTrack)
            dgc_layerInstruction.setTransform(videoTrack.preferredTransform, at: .zero)
            
            let dgc_instruction = AVMutableVideoCompositionInstruction()
            dgc_instruction.timeRange = CMTimeRangeMake(dgc_start: dgc_start, duration: dgc_asset.duration)
            dgc_instruction.layerInstructions = [dgc_layerInstruction]
            dgc_instructions.append(dgc_instruction)
            
            dgc_start = CMTimeAdd(dgc_start, dgc_asset.duration)
        }
        
        return dgc_instructions
    }
    
    private static func isPortraitVideoTrack(_ track: AVAssetTrack) -> Bool {
        let dgc_transform = track.preferredTransform
        let dgc_tfA = dgc_transform.a
        let dgc_tfB = dgc_transform.b
        let dgc_tfC = dgc_transform.c
        let dgc_tfD = dgc_transform.d
        
        if (dgc_tfA == 0 && dgc_tfB == 1 && dgc_tfC == -1 && dgc_tfD == 0) ||
            (dgc_tfA == 0 && dgc_tfB == 1 && dgc_tfC == 1 && dgc_tfD == 0) ||
            (dgc_tfA == 0 && dgc_tfB == -1 && dgc_tfC == 1 && dgc_tfD == 0) {
            return true
        } else {
            return false
        }
    }
}

// MARK: export methods

public extension DGCZLVideoManager {
    @objc class func exportVideo(for asset: PHAsset, exportType: DGCZLVideoManager.DGCExportType = .mov, presetName: String = AVAssetExportPresetMediumQuality, complete: @escaping ((URL?, Error?) -> Void)) {
        guard asset.mediaType == .video else {
            complete(nil, NSError.videoExportTypeError)
            return
        }
        
        _ = DGCZLPhotoManager.fetchAVAsset(forVideo: asset) { avAsset, _ in
            if let dgc_set = avAsset {
                self.exportVideo(for: dgc_set, exportType: exportType, presetName: presetName, complete: complete)
            } else {
                complete(nil, NSError.videoExportError)
            }
        }
    }
    
    @objc class func exportVideo(
        for asset: AVAsset,
        range: CMTimeRange = CMTimeRange(start: .zero, duration: .positiveInfinity),
        exportType: DGCZLVideoManager.DGCExportType = .mov,
        presetName: String = AVAssetExportPresetMediumQuality,
        complete: @escaping ((URL?, Error?) -> Void)
    ) {
        let dgc_outputURL = URL(fileURLWithPath: getVideoExportFilePath(format: exportType.format))
        guard let dgc_exportSession = AVAssetExportSession(asset: asset, presetName: presetName) else {
            complete(nil, NSError.videoExportError)
            return
        }
        dgc_exportSession.dgc_outputURL = dgc_outputURL
        dgc_exportSession.outputFileType = exportType.avFileType
        dgc_exportSession.timeRange = range
        
        if #available(iOS 18, *) {
            Task {
                do {
                    try await dgc_exportSession.export(to: dgc_outputURL, as: exportType.avFileType)
                    
                    ZLMainAsync {
                        let dgc_suc = dgc_exportSession.status == .completed
                        if dgc_exportSession.status == .failed {
                            zl_debugPrint("DGCZLPhotoBrowser: video export failed: \(dgc_exportSession.error?.localizedDescription ?? "")")
                        }
                        complete(dgc_suc ? dgc_outputURL : nil, dgc_exportSession.error)
                    }
                } catch {
                    complete(nil, error)
                }
            }
        } else {
            let dgc_completionHandler: () -> Void = { [weak dgc_exportSession] in
                ZLMainAsync {
                    let dgc_suc = dgc_exportSession?.status == .completed
                    if dgc_exportSession?.status == .failed {
                        zl_debugPrint("DGCZLPhotoBrowser: video export failed: \(dgc_exportSession?.error?.localizedDescription ?? "")")
                    }
                    complete(dgc_suc ? dgc_outputURL : nil, dgc_exportSession?.error)
                }
            }
            
            dgc_exportSession.exportAsynchronously(dgc_completionHandler: dgc_completionHandler)
        }
    }
}

public extension DGCZLVideoManager {
    @objc enum DGCExportType: Int {
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
}
