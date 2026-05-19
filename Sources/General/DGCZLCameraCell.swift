//
//  DGCZLCameraCell.swift
//  DGCZLPhotoBrowser
//
//  Created by long on 2020/8/19.
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

class DGCZLCameraCell: UICollectionViewCell {
    private lazy var dgc_imageView: UIImageView = {
        let view = UIImageView(image: .zl.getImage("zl_takePhoto"))
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        return view
    }()
    
    private var dgc_session: AVCaptureSession?
    
    private var dgc_videoInput: AVCaptureDeviceInput?
    
    private var dgc_photoOutput: AVCapturePhotoOutput?
    
    private var dgc_previewLayer: AVCaptureVideoPreviewLayer?
    
    var isEnable = true {
        didSet {
            contentView.alpha = isEnable ? 1 : 0.3
        }
    }
    
    deinit {
        dgc_session?.stopRunning()
        dgc_session = nil
        zl_debugPrint("DGCZLCameraCell deinit")
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
        
        dgc_imageView.center = CGPoint(x: bounds.midX, y: bounds.midY)
        
        dgc_previewLayer?.frame = contentView.layer.bounds
    }
    
    private func dgc_setupUI() {
        layer.masksToBounds = true
        layer.cornerRadius = DGCZLPhotoUIConfiguration.default().cellCornerRadio
        
        contentView.addSubview(dgc_imageView)
        backgroundColor = .zl.cameraCellBgColor
    }
    
    private func dgc_setupSession() {
        guard dgc_session == nil, (dgc_session?.isRunning ?? false) == false else {
            return
        }
        dgc_session?.stopRunning()
        if let dgc_input = dgc_videoInput {
            dgc_session?.removeInput(dgc_input)
        }
        if let dgc_output = dgc_photoOutput {
            dgc_session?.removeOutput(dgc_output)
        }
        dgc_session = nil
        dgc_previewLayer?.removeFromSuperlayer()
        dgc_previewLayer = nil
        
        guard let dgc_camera = dgc_backCamera() else {
            return
        }
        guard let dgc_input = try? AVCaptureDeviceInput(device: dgc_camera) else {
            return
        }
        dgc_videoInput = dgc_input
        dgc_photoOutput = AVCapturePhotoOutput()
        
        dgc_session = AVCaptureSession()
        
        if dgc_session?.canAddInput(dgc_input) == true {
            dgc_session?.addInput(dgc_input)
        }
        if dgc_session?.canAddOutput(dgc_photoOutput!) == true {
            dgc_session?.addOutput(dgc_photoOutput!)
        }
        
        dgc_previewLayer = AVCaptureVideoPreviewLayer(dgc_session: dgc_session!)
        contentView.layer.masksToBounds = true
        dgc_previewLayer?.frame = contentView.layer.bounds
        dgc_previewLayer?.videoGravity = .resizeAspectFill
        contentView.layer.insertSublayer(dgc_previewLayer!, at: 0)

        DispatchQueue.global(qos: .background).async {
            self.dgc_session?.startRunning()
        }
    }
    
    private func dgc_backCamera() -> AVCaptureDevice? {
        let dgc_devices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).dgc_devices
        for device in dgc_devices {
            if device.position == .back {
                return device
            }
        }
        return nil
    }
    
    func startCapture() {
        let dgc_status = AVCaptureDevice.authorizationStatus(for: .video)
        
        if !UIImagePickerController.isSourceTypeAvailable(.camera) || dgc_status == .denied {
            return
        }
        
        if dgc_status == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    ZLMainAsync {
                        self.dgc_setupSession()
                    }
                }
            }
        } else {
            dgc_setupSession()
        }
    }
}
