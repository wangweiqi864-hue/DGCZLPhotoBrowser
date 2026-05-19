//
//  DGCPhotoConfigureCNViewController.swift
//  Example
//
//  Created by long on 2020/10/20.
//

import UIKit
import DGCZLPhotoBrowser

class DGCPhotoConfigureCNViewController: UIViewController {
    let config = DGCZLPhotoConfiguration.default()
    
    let uiConfig = DGCZLPhotoUIConfiguration.default()
    
    var scrollView: UIScrollView!
    
    var previewCountTextField: UITextField!
    
    var selectCountTextField: UITextField!
    
    var minVideoSelectCountTextField: UITextField!
    
    var maxVideoSelectCountTextField: UITextField!
    
    var minVideoDurationTextField: UITextField!
    
    var maxVideoDurationTextField: UITextField!
    
    var cellRadiusTextField: UITextField!
    
    var styleSegment: UISegmentedControl!
    
    var languageButton: UIButton!
    
    var columnCountLabel: UILabel!
    
    var columnStepper: UIStepper!
    
    var sortAscendingSegment: UISegmentedControl!
    
    var allowSelectImageSwitch: UISwitch!
    
    var allowSelectGifSwitch: UISwitch!
    
    var allowSelectLivePhotoSwitch: UISwitch!
    
    var allowSelectOriginalSwitch: UISwitch!
    
    var allowSelectVideoSwitch: UISwitch!
    
    var allowMixSelectSwitch: UISwitch!
    
    var allowPreviewPhotosSwitch: UISwitch!
    
    var editImageLabel: UILabel!
    
    var allowEditImageSwitch: UISwitch!
    
    var editImageToolView: UIView!
    
    var editImageDrawToolSwitch: UISwitch!
    
    var editImageClipToolSwitch: UISwitch!
    
    var editImageImageStickerToolSwitch: UISwitch!
    
    var editImageTextStickerToolSwitch: UISwitch!
    
    var editImageMosaicToolSwitch: UISwitch!
    
    var editImageFilterToolSwitch: UISwitch!
    
    var editImageAdjustToolSwitch = UISwitch()
    
    var editImageAdjustToolView = UIView()
    
    var editImageBrightnessSwitch = UISwitch()
    
    var editImageContrastSwitch = UISwitch()
    
    var editImageSaturationSwitch = UISwitch()
    
    var saveEditImageSwitch: UISwitch!
    
    var editVideoLabel: UILabel!
    
    var allowEditVideoSwitch: UISwitch!
    
    var allowDragSelectSwitch: UISwitch!
    
    var allowSlideSelectSwitch: UISwitch!
    
    var autoScrollSwitch: UISwitch!
    
    var autoScrollMaxSpeedTextField: UITextField!
    
    var allowTakePhotoInLibrarySwitch: UISwitch!
    
    var showCaptureInCameraCellSwitch: UISwitch!
    
    var showSelectIndexSwitch: UISwitch!
    
    var showSelectMaskSwitch: UISwitch!
    
    var showSelectBorderSwitch: UISwitch!
    
    var showInvalidSelectMaskSwitch: UISwitch!
    
    var customCameraSwitch: UISwitch!
    
    var cameraFlashSwitch: UISwitch!
    
    var customAlertSwitch: UISwitch!
    
    lazy var doneBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.backgroundColor = .black
        btn.layer.cornerRadius = 25
        btn.layer.masksToBounds = true
        btn.setTitle("完成", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 15)
        btn.addTarget(self, action: #selector(dismissBtnClick), for: .touchUpInside)
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    func setupUI() {
        view.backgroundColor = .white
        
        scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .onDrag
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }
        
        let dgc_containerView = UIView()
        scrollView.addSubview(dgc_containerView)
        dgc_containerView.snp.makeConstraints { make in
            make.edges.equalTo(self.scrollView)
            make.width.equalTo(self.scrollView)
        }
        
        func createLabel(_ title: String) -> UILabel {
            let dgc_label = UILabel()
            dgc_label.font = UIFont.systemFont(ofSize: 14)
            dgc_label.textColor = .black
            dgc_label.text = title
            return dgc_label
        }
        
        func createTextField(_ text: String?, _ keyboardType: UIKeyboardType) -> UITextField {
            let dgc_field = UITextField()
            dgc_field.font = UIFont.systemFont(ofSize: 14)
            dgc_field.textColor = .black
            dgc_field.backgroundColor = .white
            dgc_field.layer.cornerRadius = 3
            dgc_field.layer.masksToBounds = true
            dgc_field.layer.borderColor = UIColor.lightGray.cgColor
            dgc_field.layer.borderWidth = 1 / UIScreen.main.scale
            dgc_field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 0))
            dgc_field.leftViewMode = .always
            dgc_field.delegate = self
            dgc_field.keyboardType = keyboardType
            dgc_field.text = text
            return dgc_field
        }
        
        let dgc_velSpacing: CGFloat = 20
        let dgc_horSpacing: CGFloat = 15
        let dgc_fieldSize = CGSize(width: 100, height: 30)
        
        let dgc_tipsLabel = createLabel("更多参数设置，请前往ZLPhotoConfiguration查看")
        dgc_tipsLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        dgc_tipsLabel.numberOfLines = 2
        dgc_tipsLabel.lineBreakMode = .byWordWrapping
        dgc_containerView.addSubview(dgc_tipsLabel)
        dgc_tipsLabel.snp.makeConstraints { make in
            make.top.left.equalTo(dgc_containerView).offset(20)
            make.right.equalTo(dgc_containerView).offset(-20)
        }
        
        // 预览张数
        let dgc_previewCountLabel = createLabel("最大预览张数")
        dgc_containerView.addSubview(dgc_previewCountLabel)
        dgc_previewCountLabel.snp.makeConstraints { make in
            make.top.equalTo(dgc_tipsLabel.snp.bottom).offset(dgc_velSpacing)
            make.left.equalTo(dgc_tipsLabel.snp.left)
        }
        
        previewCountTextField = createTextField(String(config.maxPreviewCount), .numberPad)
        dgc_containerView.addSubview(previewCountTextField)
        previewCountTextField.snp.makeConstraints { make in
            make.left.equalTo(dgc_previewCountLabel.snp.right).offset(dgc_horSpacing)
            make.centerY.equalTo(dgc_previewCountLabel)
            make.size.equalTo(dgc_fieldSize)
        }
        
        // 最大选择张数
        let dgc_maxSelectCountLabel = createLabel("最大选择张数")
        dgc_containerView.addSubview(dgc_maxSelectCountLabel)
        dgc_maxSelectCountLabel.snp.makeConstraints { make in
            make.top.equalTo(dgc_previewCountLabel.snp.bottom).offset(dgc_velSpacing)
            make.left.equalTo(dgc_previewCountLabel.snp.left)
        }
        
        selectCountTextField = createTextField(String(config.maxSelectCount), .numberPad)
        dgc_containerView.addSubview(selectCountTextField)
        selectCountTextField.snp.makeConstraints { make in
            make.left.equalTo(dgc_maxSelectCountLabel.snp.right).offset(dgc_horSpacing)
            make.centerY.equalTo(dgc_maxSelectCountLabel)
            make.size.equalTo(dgc_fieldSize)
        }
        
        // 视频最小选择个数
        let dgc_minVideoSelectCountLabel = createLabel("视频最小选择数")
        dgc_containerView.addSubview(dgc_minVideoSelectCountLabel)
        dgc_minVideoSelectCountLabel.snp.makeConstraints { make in
            make.top.equalTo(dgc_maxSelectCountLabel.snp.bottom).offset(dgc_velSpacing)
            make.left.equalTo(dgc_previewCountLabel.snp.left)
        }
        
        minVideoSelectCountTextField = createTextField(String(config.minVideoSelectCount), .numberPad)
        dgc_containerView.addSubview(minVideoSelectCountTextField)
        minVideoSelectCountTextField.snp.makeConstraints { make in
            make.left.equalTo(dgc_minVideoSelectCountLabel.snp.right).offset(dgc_horSpacing)
            make.centerY.equalTo(dgc_minVideoSelectCountLabel)
            make.size.equalTo(dgc_fieldSize)
        }
        
        // 视频最大选择个数
        let dgc_maxVideoSelectCountLabel = createLabel("视频最大选择数")
        dgc_containerView.addSubview(dgc_maxVideoSelectCountLabel)
        dgc_maxVideoSelectCountLabel.snp.makeConstraints { make in
            make.top.equalTo(dgc_minVideoSelectCountLabel.snp.bottom).offset(dgc_velSpacing)
            make.left.equalTo(dgc_previewCountLabel.snp.left)
        }
        
        maxVideoSelectCountTextField = createTextField(String(config.maxVideoSelectCount), .numberPad)
        dgc_containerView.addSubview(maxVideoSelectCountTextField)
        maxVideoSelectCountTextField.snp.makeConstraints { make in
            make.left.equalTo(dgc_maxVideoSelectCountLabel.snp.right).offset(dgc_horSpacing)
            make.centerY.equalTo(dgc_maxVideoSelectCountLabel)
            make.size.equalTo(dgc_fieldSize)
        }
        
        // 视频最小选择时长
        let dgc_minVideoDurationLabel = createLabel("视频选择最小时长")
        dgc_containerView.addSubview(dgc_minVideoDurationLabel)
        dgc_minVideoDurationLabel.snp.makeConstraints { make in
            make.top.equalTo(dgc_maxVideoSelectCountLabel.snp.bottom).offset(dgc_velSpacing)
            make.left.equalTo(dgc_previewCountLabel.snp.left)
        }
        
        minVideoDurationTextField = createTextField(String(config.minSelectVideoDuration), .numberPad)
        dgc_containerView.addSubview(minVideoDurationTextField)
        minVideoDurationTextField.snp.makeConstraints { make in
            make.left.equalTo(dgc_minVideoDurationLabel.snp.right).offset(dgc_horSpacing)
            make.centerY.equalTo(dgc_minVideoDurationLabel)
            make.size.equalTo(dgc_fieldSize)
        }
        
        // 视频最大选择时长
        let dgc_maxVideoDurationLabel = createLabel("视频选择最大时长")
        dgc_containerView.addSubview(dgc_maxVideoDurationLabel)
        dgc_maxVideoDurationLabel.snp.makeConstraints { make in
            make.top.equalTo(dgc_minVideoDurationLabel.snp.bottom).offset(dgc_velSpacing)
            make.left.equalTo(dgc_previewCountLabel.snp.left)
        }
        
        maxVideoDurationTextField = createTextField(String(config.maxSelectVideoDuration), .numberPad)
        dgc_containerView.addSubview(maxVideoDurationTextField)
        maxVideoDurationTextField.snp.makeConstraints { make in
            make.left.equalTo(dgc_maxVideoDurationLabel.snp.right).offset(dgc_horSpacing)
            make.centerY.equalTo(dgc_maxVideoDurationLabel)
            make.size.equalTo(dgc_fieldSize)
        }
        
        // cell圆角
        let dgc_cellRadiusLabel = createLabel("cell圆角")
        dgc_containerView.addSubview(dgc_cellRadiusLabel)
        dgc_cellRadiusLabel.snp.makeConstraints { make in
            make.top.equalTo(dgc_maxVideoDurationLabel.snp.bottom).offset(dgc_velSpacing)
            make.left.equalTo(dgc_previewCountLabel.snp.left)
        }
        
        cellRadiusTextField = createTextField(String(format: "%.2f", uiConfig.cellCornerRadio), .decimalPad)
        dgc_containerView.addSubview(cellRadiusTextField)
        cellRadiusTextField.snp.makeConstraints { make in
            make.left.equalTo(dgc_cellRadiusLabel.snp.right).offset(dgc_horSpacing)
            make.centerY.equalTo(dgc_cellRadiusLabel)
            make.size.equalTo(dgc_fieldSize)
        }
        
        // 相册样式
        let dgc_styleLabel = createLabel("相册样式")
        dgc_containerView.addSubview(dgc_styleLabel)
        dgc_styleLabel.snp.makeConstraints { make in
            make.top.equalTo(dgc_cellRadiusLabel.snp.bottom).offset(dgc_velSpacing)
            make.left.equalTo(dgc_previewCountLabel.snp.left)
        }
        
        styleSegment = UISegmentedControl(items: ["样式一(仿微信)", "样式二(传统)"])
        styleSegment.selectedSegmentIndex = uiConfig.style.rawValue
        styleSegment.addTarget(self, action: #selector(styleSegmentChanged), for: .valueChanged)
        dgc_containerView.addSubview(styleSegment)
        styleSegment.snp.makeConstraints { make in
            make.left.equalTo(dgc_styleLabel.snp.right).offset(dgc_horSpacing)
            make.centerY.equalTo(dgc_styleLabel)
        }
        
        // 框架语言
        let dgc_languageLabel = createLabel("框架语言")
        dgc_containerView.addSubview(dgc_languageLabel)
        dgc_languageLabel.snp.makeConstraints { make in
            make.top.equalTo(dgc_styleLabel.snp.bottom).offset(dgc_velSpacing)
            make.left.equalTo(dgc_previewCountLabel.snp.left)
        }
        
        languageButton = UIButton(type: .custom)
        languageButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        languageButton.setTitle(uiConfig.languageType.toString(), for: .normal)
        languageButton.addTarget(self, action: #selector(languageButtonClick), for: .touchUpInside)
        languageButton.setTitleColor(.white, for: .normal)
        languageButton.layer.cornerRadius = 5
        languageButton.layer.masksToBounds = true
        languageButton.backgroundColor = .black
        dgc_containerView.addSubview(languageButton)
        languageButton.snp.makeConstraints { make in
            make.centerY.equalTo(dgc_languageLabel)
            make.left.equalTo(dgc_languageLabel.snp.right).offset(dgc_horSpacing)
        }
        
        // 每列个数
        let dgc_columnCountTitleLabel = createLabel("每行显示照片个数")
        dgc_containerView.addSubview(dgc_columnCountTitleLabel)
        dgc_columnCountTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(dgc_languageLabel.snp.bottom).offset(dgc_velSpacing)
            make.left.equalTo(dgc_previewCountLabel.snp.left)
        }
        
        columnCountLabel = createLabel(String(uiConfig.columnCount))
        dgc_containerView.addSubview(columnCountLabel)
        columnCountLabel.snp.makeConstraints { make in
            make.left.equalTo(dgc_columnCountTitleLabel.snp.right).offset(10)
            make.centerY.equalTo(dgc_columnCountTitleLabel.snp.centerY)
        }
        
        columnStepper = UIStepper()
        columnStepper.minimumValue = 2
        columnStepper.maximumValue = 6
        columnStepper.stepValue = 1
        columnStepper.value = Double(uiConfig.columnCount)
        columnStepper.addTarget(self, action: #selector(columnStepperValueChanged), for: .valueChanged)
        dgc_containerView.addSubview(columnStepper)
        columnStepper.snp.makeConstraints { make in
            make.centerY.equalTo(dgc_columnCountTitleLabel.snp.centerY)
            make.left.equalTo(columnCountLabel.snp.right).offset(dgc_horSpacing)
            make.size.equalTo(CGSize(width: 100, height: 30))
        }
        
        // 排序方式
        let dgc_sortLabel = createLabel("排序方式")
        dgc_containerView.addSubview(dgc_sortLabel)
        dgc_sortLabel.snp.makeConstraints { make in
            make.top.equalTo(dgc_columnCountTitleLabel.snp.bottom).offset(dgc_velSpacing)
            make.left.equalTo(dgc_previewCountLabel.snp.left)
        }
        
        sortAscendingSegment = UISegmentedControl(items: ["升序", "降序"])
        sortAscendingSegment.selectedSegmentIndex = uiConfig.sortAscending ? 0 : 1
        sortAscendingSegment.addTarget(self, action: #selector(sortAscendingChanged), for: .valueChanged)
        dgc_containerView.addSubview(sortAscendingSegment)
        sortAscendingSegment.snp.makeConstraints { make in
            make.left.equalTo(dgc_sortLabel.snp.right).offset(dgc_horSpacing)
            make.centerY.equalTo(dgc_sortLabel)
        }
        
        // 选择图片开关
        let dgc_selImageLabel = createLabel("允许选择图片")
        dgc_containerView.addSubview(dgc_selImageLabel)
        dgc_selImageLabel.snp.makeConstraints { make in
            make.top.equalTo(dgc_sortLabel.snp.bottom).offset(dgc_velSpacing)
            make.left.equalTo(dgc_previewCountLabel.snp.left)
        }
        
        allowSelectImageSwitch = UISwitch()
        allowSelectImageSwitch.isOn = config.allowSelectImage
        allowSelectImageSwitch.addTarget(self, action: #selector(allowSelectImageChanged), for: .valueChanged)
        dgc_containerView.addSubview(allowSelectImageSwitch)
        allowSelectImageSwitch.snp.makeConstraints { make in
            make.left.equalTo(dgc_selImageLabel.snp.right).offset(dgc_horSpacing)
            make.centerY.equalTo(dgc_selImageLabel)
        }
        
        // 选择gif开关
        let dgc_selGifLabel = createLabel("允许选择Gif")
        dgc_containerView.addSubview(dgc_selGifLabel)
        dgc_selGifLabel.snp.makeConstraints { make in
            make.top.equalTo(dgc_selImageLabel.snp.bottom).offset(dgc_velSpacing)
            make.left.equalTo(dgc_previewCountLabel.snp.left)
        }
        
        allowSelectGifSwitch = UISwitch()
        allowSelectGifSwitch.isOn = config.allowSelectGif
        allowSelectGifSwitch.addTarget(self, action: #selector(allowSelectGifChanged), for: .valueChanged)
        dgc_containerView.addSubview(allowSelectGifSwitch)
        allowSelectGifSwitch.snp.makeConstraints { make in
            make.left.equalTo(dgc_selGifLabel.snp.right).offset(dgc_horSpacing)
            make.centerY.equalTo(dgc_selGifLabel)
        }
        
        // 选择livePhoto开关
        let dgc_selLivePhotoLabel = createLabel("允许选择LivePhoto")
        dgc_containerView.addSubview(dgc_selLivePhotoLabel)
        dgc_selLivePhotoLabel.snp.makeConstraints { make in
            make.top.equalTo(dgc_selGifLabel.snp.bottom).offset(dgc_velSpacing)
            make.left.equalTo(dgc_previewCountLabel.snp.left)
        }
        
        allowSelectLivePhotoSwitch = UISwitch()
        allowSelectLivePhotoSwitch.isOn = config.allowSelectLivePhoto
        allowSelectLivePhotoSwitch.addTarget(self, action: #selector(allowSelectLivePhotoChanged), for: .valueChanged)
        dgc_containerView.addSubview(allowSelectLivePhotoSwitch)
        allowSelectLivePhotoSwitch.snp.makeConstraints { make in
            make.left.equalTo(dgc_selLivePhotoLabel.snp.right).offset(dgc_horSpacing)
            make.centerY.equalTo(dgc_selLivePhotoLabel)
        }
        
        // 选择livePhoto开关
        let dgc_selOriginalLabel = createLabel("允许选择原图")
        dgc_containerView.addSubview(dgc_selOriginalLabel)
        dgc_selOriginalLabel.snp.makeConstraints { make in
            make.top.equalTo(dgc_selLivePhotoLabel.snp.bottom).offset(dgc_velSpacing)
            make.left.equalTo(dgc_previewCountLabel.snp.left)
        }
        
        allowSelectOriginalSwitch = UISwitch()
        allowSelectOriginalSwitch.isOn = config.allowSelectOriginal
        allowSelectOriginalSwitch.addTarget(self, action: #selector(allowSelectOriginalChanged), for: .valueChanged)
        dgc_containerView.addSubview(allowSelectOriginalSwitch)
        allowSelectOriginalSwitch.snp.makeConstraints { make in
            make.left.equalTo(dgc_selOriginalLabel.snp.right).offset(dgc_horSpacing)
            make.centerY.equalTo(dgc_selOriginalLabel)
        }
        
        // 选择视频开关
        let dgc_selVideoLabel = createLabel("允许选择视频")
        dgc_containerView.addSubview(dgc_selVideoLabel)
        dgc_selVideoLabel.snp.makeConstraints { make in
            make.top.equalTo(dgc_selOriginalLabel.snp.bottom).offset(dgc_velSpacing)
            make.left.equalTo(dgc_previewCountLabel.snp.left)
        }
        
        allowSelectVideoSwitch = UISwitch()
        allowSelectVideoSwitch.isOn = config.allowSelectVideo
        allowSelectVideoSwitch.addTarget(self, action: #selector(allowSelectVideoChanged), for: .valueChanged)
        dgc_containerView.addSubview(allowSelectVideoSwitch)
        allowSelectVideoSwitch.snp.makeConstraints { make in
            make.left.equalTo(dgc_selVideoLabel.snp.right).offset(dgc_horSpacing)
            make.centerY.equalTo(dgc_selVideoLabel)
        }
        
        // 混合选择开关
        let dgc_mixSelectLabel = createLabel("允许图片视频一起选择")
        dgc_containerView.addSubview(dgc_mixSelectLabel)
        dgc_mixSelectLabel.snp.makeConstraints { make in
            make.top.equalTo(dgc_selVideoLabel.snp.bottom).offset(dgc_velSpacing)
            make.left.equalTo(dgc_previewCountLabel.snp.left)
        }
        
        allowMixSelectSwitch = UISwitch()
        allowMixSelectSwitch.isOn = config.allowMixSelect
        allowMixSelectSwitch.addTarget(self, action: #selector(allowMixSelectChanged), for: .valueChanged)
        dgc_containerView.addSubview(allowMixSelectSwitch)
        allowMixSelectSwitch.snp.makeConstraints { make in
            make.left.equalTo(dgc_mixSelectLabel.snp.right).offset(dgc_horSpacing)
            make.centerY.equalTo(dgc_mixSelectLabel)
        }
        
        // 预览大图开关
        let dgc_previewPhotosLabel = createLabel("允许进入大图界面")
        dgc_containerView.addSubview(dgc_previewPhotosLabel)
        dgc_previewPhotosLabel.snp.makeConstraints { make in
            make.top.equalTo(dgc_mixSelectLabel.snp.bottom).offset(dgc_velSpacing)
            make.left.equalTo(dgc_previewCountLabel.snp.left)
        }
        
        allowPreviewPhotosSwitch = UISwitch()
        allowPreviewPhotosSwitch.isOn = config.allowPreviewPhotos
        allowPreviewPhotosSwitch.addTarget(self, action: #selector(allowPreviewPhotoChanged), for: .valueChanged)
        dgc_containerView.addSubview(allowPreviewPhotosSwitch)
        allowPreviewPhotosSwitch.snp.makeConstraints { make in
            make.left.equalTo(dgc_previewPhotosLabel.snp.right).offset(dgc_horSpacing)
            make.centerY.equalTo(dgc_previewPhotosLabel)
        }
        
        // 编辑图片开关
        editImageLabel = createLabel("允许编辑图片")
        dgc_containerView.addSubview(editImageLabel)
        editImageLabel.snp.makeConstraints { make in
            make.top.equalTo(dgc_previewPhotosLabel.snp.bottom).offset(dgc_velSpacing)
            make.left.equalTo(dgc_previewCountLabel.snp.left)
        }
        
        allowEditImageSwitch = UISwitch()
        allowEditImageSwitch.isOn = config.allowEditImage
        allowEditImageSwitch.addTarget(self, action: #selector(allowEditImageChanged), for: .valueChanged)
        dgc_containerView.addSubview(allowEditImageSwitch)
        allowEditImageSwitch.snp.makeConstraints { make in
            make.left.equalTo(editImageLabel.snp.right).offset(dgc_horSpacing)
            make.centerY.equalTo(editImageLabel)
        }
        
        // 编辑图片工具
        editImageToolView = UIView()
        editImageToolView.alpha = config.allowEditImage ? 1 : 0
        dgc_containerView.addSubview(editImageToolView)
        editImageToolView.snp.makeConstraints { make in
            make.top.equalTo(self.allowEditImageSwitch.snp.bottom).offset(dgc_velSpacing)
            make.left.equalTo(dgc_previewCountLabel.snp.left)
            make.right.equalTo(dgc_containerView)
        }
        
        // 涂鸦
        let dgc_drawToolLabel = createLabel("涂鸦")
        editImageToolView.addSubview(dgc_drawToolLabel)
        dgc_drawToolLabel.snp.makeConstraints { make in
            make.top.equalTo(self.editImageToolView)
            make.left.equalTo(self.editImageToolView)
        }
        
        let dgc_editImageConfig = config.editImageConfiguration
        
        editImageDrawToolSwitch = UISwitch()
        editImageDrawToolSwitch.isOn = dgc_editImageConfig.tools.contains(.draw)
        editImageDrawToolSwitch.addTarget(self, action: #selector(drawToolChanged), for: .valueChanged)
        editImageToolView.addSubview(editImageDrawToolSwitch)
        editImageDrawToolSwitch.snp.makeConstraints { make in
            make.left.equalTo(dgc_drawToolLabel.snp.right).offset(dgc_horSpacing)
            make.centerY.equalTo(dgc_drawToolLabel)
        }
        
        // 裁剪
        let dgc_clipToolLabel = createLabel("裁剪")
        editImageToolView.addSubview(dgc_clipToolLabel)
        dgc_clipToolLabel.snp.makeConstraints { make in
            make.top.equalTo(dgc_drawToolLabel.snp.bottom).offset(dgc_velSpacing)
            make.left.equalTo(self.editImageToolView)
        }
        
        editImageClipToolSwitch = UISwitch()
        editImageClipToolSwitch.isOn = dgc_editImageConfig.tools.contains(.clip)
        editImageClipToolSwitch.addTarget(self, action: #selector(clipToolChanged), for: .valueChanged)
        editImageToolView.addSubview(editImageClipToolSwitch)
        editImageClipToolSwitch.snp.makeConstraints { make in
            make.left.equalTo(dgc_clipToolLabel.snp.right).offset(dgc_horSpacing)
            make.centerY.equalTo(dgc_clipToolLabel)
        }
        
        // 贴图
        let dgc_imageStickerToolLabel = createLabel("贴图")
        editImageToolView.addSubview(dgc_imageStickerToolLabel)
        dgc_imageStickerToolLabel.snp.makeConstraints { make in
            make.top.equalTo(dgc_clipToolLabel.snp.bottom).offset(dgc_velSpacing)
            make.left.equalTo(self.editImageToolView)
        }
        
        editImageImageStickerToolSwitch = UISwitch()
        editImageImageStickerToolSwitch.isOn = dgc_editImageConfig.tools.contains(.imageSticker)
        editImageImageStickerToolSwitch.addTarget(self, action: #selector(imageStickerToolChanged), for: .valueChanged)
        editImageToolView.addSubview(editImageImageStickerToolSwitch)
        editImageImageStickerToolSwitch.snp.makeConstraints { make in
            make.left.equalTo(dgc_imageStickerToolLabel.snp.right).offset(dgc_horSpacing)
            make.centerY.equalTo(dgc_imageStickerToolLabel)
        }
        
        // 文本
        let dgc_textStickerToolLabel = createLabel("文本")
        editImageToolView.addSubview(dgc_textStickerToolLabel)
        dgc_textStickerToolLabel.snp.makeConstraints { make in
            make.top.equalTo(dgc_imageStickerToolLabel.snp.bottom).offset(dgc_velSpacing)
            make.left.equalTo(self.editImageToolView)
        }
        
        editImageTextStickerToolSwitch = UISwitch()
        editImageTextStickerToolSwitch.isOn = dgc_editImageConfig.tools.contains(.textSticker)
        editImageTextStickerToolSwitch.addTarget(self, action: #selector(textStickerToolChanged), for: .valueChanged)
        editImageToolView.addSubview(editImageTextStickerToolSwitch)
        editImageTextStickerToolSwitch.snp.makeConstraints { make in
            make.left.equalTo(dgc_textStickerToolLabel.snp.right).offset(dgc_horSpacing)
            make.centerY.equalTo(dgc_textStickerToolLabel)
        }
        
        // 马赛克
        let dgc_mosaicToolLabel = createLabel("马赛克")
        editImageToolView.addSubview(dgc_mosaicToolLabel)
        dgc_mosaicToolLabel.snp.makeConstraints { make in
            make.top.equalTo(dgc_textStickerToolLabel.snp.bottom).offset(dgc_velSpacing)
            make.left.equalTo(self.editImageToolView)
        }
        
        editImageMosaicToolSwitch = UISwitch()
        editImageMosaicToolSwitch.isOn = dgc_editImageConfig.tools.contains(.mosaic)
        editImageMosaicToolSwitch.addTarget(self, action: #selector(mosaicToolChanged), for: .valueChanged)
        editImageToolView.addSubview(editImageMosaicToolSwitch)
        editImageMosaicToolSwitch.snp.makeConstraints { make in
            make.left.equalTo(dgc_mosaicToolLabel.snp.right).offset(dgc_horSpacing)
            make.centerY.equalTo(dgc_mosaicToolLabel)
        }
        
        // 滤镜
        let dgc_filterToolLabel = createLabel("滤镜")
        editImageToolView.addSubview(dgc_filterToolLabel)
        dgc_filterToolLabel.snp.makeConstraints { make in
            make.top.equalTo(dgc_mosaicToolLabel.snp.bottom).offset(dgc_velSpacing)
            make.left.equalTo(self.editImageToolView)
        }
        
        editImageFilterToolSwitch = UISwitch()
        editImageFilterToolSwitch.isOn = dgc_editImageConfig.tools.contains(.filter)
        editImageFilterToolSwitch.addTarget(self, action: #selector(filterToolChanged), for: .valueChanged)
        editImageToolView.addSubview(editImageFilterToolSwitch)
        editImageFilterToolSwitch.snp.makeConstraints { make in
            make.left.equalTo(dgc_filterToolLabel.snp.right).offset(dgc_horSpacing)
            make.centerY.equalTo(dgc_filterToolLabel)
        }
        
        // 色值
        let dgc_adjustToolLabel = createLabel("色值调整")
        editImageToolView.addSubview(dgc_adjustToolLabel)
        dgc_adjustToolLabel.snp.makeConstraints { make in
            make.top.equalTo(dgc_filterToolLabel.snp.bottom).offset(dgc_velSpacing)
            make.left.equalTo(self.editImageToolView)
        }
        
        editImageAdjustToolSwitch.isOn = dgc_editImageConfig.tools.contains(.adjust)
        editImageAdjustToolSwitch.addTarget(self, action: #selector(adjustToolChanged), for: .valueChanged)
        editImageToolView.addSubview(editImageAdjustToolSwitch)
        editImageAdjustToolSwitch.snp.makeConstraints { make in
            make.left.equalTo(dgc_adjustToolLabel.snp.right).offset(dgc_horSpacing)
            make.centerY.equalTo(dgc_adjustToolLabel)
        }
        
        editImageToolView.addSubview(editImageAdjustToolView)
        editImageAdjustToolView.snp.makeConstraints { make in
            make.top.equalTo(dgc_adjustToolLabel.snp.bottom).offset(dgc_velSpacing)
            make.height.equalTo(dgc_editImageConfig.tools.contains(.adjust) ? 100 : 0)
            make.left.equalToSuperview().offset(dgc_horSpacing)
            make.right.bottom.equalToSuperview()
        }
        
        // 亮度
        let dgc_brightnessLabel = createLabel("亮度")
        editImageAdjustToolView.addSubview(dgc_brightnessLabel)
        dgc_brightnessLabel.snp.makeConstraints { make in
            make.top.left.equalToSuperview()
        }
        
        editImageBrightnessSwitch.isOn = dgc_editImageConfig.adjustTools.contains(.brightness)
        editImageBrightnessSwitch.addTarget(self, action: #selector(brightnessChanged), for: .valueChanged)
        editImageAdjustToolView.addSubview(editImageBrightnessSwitch)
        editImageBrightnessSwitch.snp.makeConstraints { make in
            make.left.equalTo(dgc_brightnessLabel.snp.right).offset(dgc_horSpacing)
            make.centerY.equalTo(dgc_brightnessLabel)
        }
        
        // 对比度
        let dgc_contrastLabel = createLabel("对比度")
        editImageAdjustToolView.addSubview(dgc_contrastLabel)
        dgc_contrastLabel.snp.makeConstraints { make in
            make.top.equalTo(dgc_brightnessLabel.snp.bottom).offset(dgc_velSpacing)
            make.left.equalToSuperview()
        }
        
        editImageContrastSwitch.isOn = dgc_editImageConfig.adjustTools.contains(.contrast)
        editImageContrastSwitch.addTarget(self, action: #selector(contrastChanged), for: .valueChanged)
        editImageAdjustToolView.addSubview(editImageContrastSwitch)
        editImageContrastSwitch.snp.makeConstraints { make in
            make.left.equalTo(dgc_contrastLabel.snp.right).offset(dgc_horSpacing)
            make.centerY.equalTo(dgc_contrastLabel)
        }
        
        // 饱和度
        let dgc_saturationLabel = createLabel("饱和度")
        editImageAdjustToolView.addSubview(dgc_saturationLabel)
        dgc_saturationLabel.snp.makeConstraints { make in
            make.top.equalTo(dgc_contrastLabel.snp.bottom).offset(dgc_velSpacing)
            make.left.equalToSuperview()
        }
        
        editImageSaturationSwitch.isOn = dgc_editImageConfig.adjustTools.contains(.saturation)
        editImageSaturationSwitch.addTarget(self, action: #selector(saturationChanged), for: .valueChanged)
        editImageAdjustToolView.addSubview(editImageSaturationSwitch)
        editImageSaturationSwitch.snp.makeConstraints { make in
            make.left.equalTo(dgc_saturationLabel.snp.right).offset(dgc_horSpacing)
            make.centerY.equalTo(dgc_saturationLabel)
        }
        
        // 编辑视频开关
        editVideoLabel = createLabel("允许编辑视频")
        dgc_containerView.addSubview(editVideoLabel)
        editVideoLabel.snp.makeConstraints { make in
            if config.allowEditImage {
                make.top.equalTo(editImageToolView.snp.bottom).offset(dgc_velSpacing)
            } else {
                make.top.equalTo(editImageToolView.snp.top)
            }
            make.left.equalTo(dgc_previewCountLabel.snp.left)
        }
        
        allowEditVideoSwitch = UISwitch()
        allowEditVideoSwitch.isOn = config.allowEditVideo
        allowEditVideoSwitch.addTarget(self, action: #selector(allowEditVideoChanged), for: .valueChanged)
        dgc_containerView.addSubview(allowEditVideoSwitch)
        allowEditVideoSwitch.snp.makeConstraints { make in
            make.left.equalTo(editVideoLabel.snp.right).offset(dgc_horSpacing)
            make.centerY.equalTo(editVideoLabel)
        }
        
        // 保存编辑图片开关
        let dgc_saveEditImageLabel = createLabel("保存编辑的图片")
        dgc_containerView.addSubview(dgc_saveEditImageLabel)
        dgc_saveEditImageLabel.snp.makeConstraints { make in
            make.top.equalTo(editVideoLabel.snp.bottom).offset(dgc_velSpacing)
            make.left.equalTo(dgc_previewCountLabel.snp.left)
        }
        
        saveEditImageSwitch = UISwitch()
        saveEditImageSwitch.isOn = config.saveNewImageAfterEdit
        saveEditImageSwitch.addTarget(self, action: #selector(saveEditImageChanged), for: .valueChanged)
        dgc_containerView.addSubview(saveEditImageSwitch)
        saveEditImageSwitch.snp.makeConstraints { make in
            make.left.equalTo(dgc_saveEditImageLabel.snp.right).offset(dgc_horSpacing)
            make.centerY.equalTo(dgc_saveEditImageLabel)
        }
        
        // 拖拽选择开关
        let dgc_dragSelectLabel = createLabel("允许拖拽选择")
        dgc_containerView.addSubview(dgc_dragSelectLabel)
        dgc_dragSelectLabel.snp.makeConstraints { make in
            make.top.equalTo(dgc_saveEditImageLabel.snp.bottom).offset(dgc_velSpacing)
            make.left.equalTo(dgc_previewCountLabel.snp.left)
        }
        
        allowDragSelectSwitch = UISwitch()
        allowDragSelectSwitch.isOn = config.allowDragSelect
        allowDragSelectSwitch.addTarget(self, action: #selector(allowDragSelectChanged), for: .valueChanged)
        dgc_containerView.addSubview(allowDragSelectSwitch)
        allowDragSelectSwitch.snp.makeConstraints { make in
            make.left.equalTo(dgc_dragSelectLabel.snp.right).offset(dgc_horSpacing)
            make.centerY.equalTo(dgc_dragSelectLabel)
        }
        
        // 滑动拖拽开关
        let dgc_slideSelectLabel = createLabel("允许滑动选择")
        dgc_containerView.addSubview(dgc_slideSelectLabel)
        dgc_slideSelectLabel.snp.makeConstraints { make in
            make.top.equalTo(dgc_dragSelectLabel.snp.bottom).offset(dgc_velSpacing)
            make.left.equalTo(dgc_previewCountLabel.snp.left)
        }
        
        allowSlideSelectSwitch = UISwitch()
        allowSlideSelectSwitch.isOn = config.allowSlideSelect
        allowSlideSelectSwitch.addTarget(self, action: #selector(allowSlideSelectChanged), for: .valueChanged)
        dgc_containerView.addSubview(allowSlideSelectSwitch)
        allowSlideSelectSwitch.snp.makeConstraints { make in
            make.left.equalTo(dgc_slideSelectLabel.snp.right).offset(dgc_horSpacing)
            make.centerY.equalTo(dgc_slideSelectLabel)
        }
        
        // 滑动拖拽时自动滚动
        let dgc_autoScrollLabel = createLabel("滑动选择时自动滚动")
        dgc_containerView.addSubview(dgc_autoScrollLabel)
        dgc_autoScrollLabel.snp.makeConstraints { make in
            make.top.equalTo(dgc_slideSelectLabel.snp.bottom).offset(dgc_velSpacing)
            make.left.equalTo(dgc_previewCountLabel.snp.left)
        }
        
        autoScrollSwitch = UISwitch()
        autoScrollSwitch.isOn = config.autoScrollWhenSlideSelectIsActive
        autoScrollSwitch.addTarget(self, action: #selector(autoScrollSwitchChanged), for: .valueChanged)
        dgc_containerView.addSubview(autoScrollSwitch)
        autoScrollSwitch.snp.makeConstraints { make in
            make.left.equalTo(dgc_autoScrollLabel.snp.right).offset(dgc_horSpacing)
            make.centerY.equalTo(dgc_autoScrollLabel)
        }
        
        // 滑动拖拽时自动滚动最大速度
        let dgc_autoScrollMaxSpeedLabel = createLabel("自动滚动最大速度")
        dgc_containerView.addSubview(dgc_autoScrollMaxSpeedLabel)
        dgc_autoScrollMaxSpeedLabel.snp.makeConstraints { make in
            make.top.equalTo(dgc_autoScrollLabel.snp.bottom).offset(dgc_velSpacing)
            make.left.equalTo(dgc_previewCountLabel.snp.left)
        }
        
        autoScrollMaxSpeedTextField = createTextField(String(format: "%.2f", config.autoScrollMaxSpeed), .decimalPad)
        dgc_containerView.addSubview(autoScrollMaxSpeedTextField)
        autoScrollMaxSpeedTextField.snp.makeConstraints { make in
            make.left.equalTo(dgc_autoScrollMaxSpeedLabel.snp.right).offset(dgc_horSpacing)
            make.centerY.equalTo(dgc_autoScrollMaxSpeedLabel)
        }
        
        // 相册内部拍照开关
        let dgc_takePhotoLabel = createLabel("允许相册内部拍照")
        dgc_containerView.addSubview(dgc_takePhotoLabel)
        dgc_takePhotoLabel.snp.makeConstraints { make in
            make.top.equalTo(dgc_autoScrollMaxSpeedLabel.snp.bottom).offset(dgc_velSpacing)
            make.left.equalTo(dgc_previewCountLabel.snp.left)
        }
        
        allowTakePhotoInLibrarySwitch = UISwitch()
        allowTakePhotoInLibrarySwitch.isOn = config.allowTakePhotoInLibrary
        allowTakePhotoInLibrarySwitch.addTarget(self, action: #selector(allowTakePhotoInLibraryChanged), for: .valueChanged)
        dgc_containerView.addSubview(allowTakePhotoInLibrarySwitch)
        allowTakePhotoInLibrarySwitch.snp.makeConstraints { make in
            make.left.equalTo(dgc_takePhotoLabel.snp.right).offset(dgc_horSpacing)
            make.centerY.equalTo(dgc_takePhotoLabel)
        }
        
        // 相册内部拍照cell显示实时画面
        let dgc_showCaptureLabel = createLabel("拍照cell显示相机俘获画面")
        dgc_containerView.addSubview(dgc_showCaptureLabel)
        dgc_showCaptureLabel.snp.makeConstraints { make in
            make.top.equalTo(dgc_takePhotoLabel.snp.bottom).offset(dgc_velSpacing)
            make.left.equalTo(dgc_previewCountLabel.snp.left)
        }
        
        showCaptureInCameraCellSwitch = UISwitch()
        showCaptureInCameraCellSwitch.isOn = uiConfig.showCaptureImageOnTakePhotoBtn
        showCaptureInCameraCellSwitch.addTarget(self, action: #selector(showCaptureInCameraCellChanged), for: .valueChanged)
        dgc_containerView.addSubview(showCaptureInCameraCellSwitch)
        showCaptureInCameraCellSwitch.snp.makeConstraints { make in
            make.left.equalTo(dgc_showCaptureLabel.snp.right).offset(dgc_horSpacing)
            make.centerY.equalTo(dgc_showCaptureLabel)
        }
        
        // 显示已选选择照片index
        let dgc_showSelectIndexLabel = createLabel("显示已选择照片index")
        dgc_containerView.addSubview(dgc_showSelectIndexLabel)
        dgc_showSelectIndexLabel.snp.makeConstraints { make in
            make.top.equalTo(dgc_showCaptureLabel.snp.bottom).offset(dgc_velSpacing)
            make.left.equalTo(dgc_previewCountLabel.snp.left)
        }
        
        showSelectIndexSwitch = UISwitch()
        showSelectIndexSwitch.isOn = config.showSelectedIndex
        showSelectIndexSwitch.addTarget(self, action: #selector(showSelectIndexChanged), for: .valueChanged)
        dgc_containerView.addSubview(showSelectIndexSwitch)
        showSelectIndexSwitch.snp.makeConstraints { make in
            make.left.equalTo(dgc_showSelectIndexLabel.snp.right).offset(dgc_horSpacing)
            make.centerY.equalTo(dgc_showSelectIndexLabel)
        }
        
        // 显示已选选择照片遮罩
        let dgc_showSelectMaskLabel = createLabel("显示已选择照片遮罩")
        dgc_containerView.addSubview(dgc_showSelectMaskLabel)
        dgc_showSelectMaskLabel.snp.makeConstraints { make in
            make.top.equalTo(dgc_showSelectIndexLabel.snp.bottom).offset(dgc_velSpacing)
            make.left.equalTo(dgc_previewCountLabel.snp.left)
        }
        
        showSelectMaskSwitch = UISwitch()
        showSelectMaskSwitch.isOn = uiConfig.showSelectedMask
        showSelectMaskSwitch.addTarget(self, action: #selector(showSelectMaskChanged), for: .valueChanged)
        dgc_containerView.addSubview(showSelectMaskSwitch)
        showSelectMaskSwitch.snp.makeConstraints { make in
            make.left.equalTo(dgc_showSelectMaskLabel.snp.right).offset(dgc_horSpacing)
            make.centerY.equalTo(dgc_showSelectMaskLabel)
        }
        
        // 显示已选选择照片边框
        let dgc_showSelectBorderLabel = createLabel("显示已选择照片边框")
        dgc_containerView.addSubview(dgc_showSelectBorderLabel)
        dgc_showSelectBorderLabel.snp.makeConstraints { make in
            make.top.equalTo(dgc_showSelectMaskLabel.snp.bottom).offset(dgc_velSpacing)
            make.left.equalTo(dgc_previewCountLabel.snp.left)
        }
        
        showSelectBorderSwitch = UISwitch()
        showSelectBorderSwitch.isOn = uiConfig.showSelectedBorder
        showSelectBorderSwitch.addTarget(self, action: #selector(showSelectBorderChanged), for: .valueChanged)
        dgc_containerView.addSubview(showSelectBorderSwitch)
        showSelectBorderSwitch.snp.makeConstraints { make in
            make.left.equalTo(dgc_showSelectBorderLabel.snp.right).offset(dgc_horSpacing)
            make.centerY.equalTo(dgc_showSelectBorderLabel)
        }
        
        // 显示不可选状态照片遮罩
        let dgc_showInvalidMaskLabel = createLabel("显示不可选状态照片遮罩")
        dgc_containerView.addSubview(dgc_showInvalidMaskLabel)
        dgc_showInvalidMaskLabel.snp.makeConstraints { make in
            make.top.equalTo(dgc_showSelectBorderLabel.snp.bottom).offset(dgc_velSpacing)
            make.left.equalTo(dgc_previewCountLabel.snp.left)
        }
        
        showInvalidSelectMaskSwitch = UISwitch()
        showInvalidSelectMaskSwitch.isOn = uiConfig.showInvalidMask
        showInvalidSelectMaskSwitch.addTarget(self, action: #selector(showInvalidSelectMaskChanged), for: .valueChanged)
        dgc_containerView.addSubview(showInvalidSelectMaskSwitch)
        showInvalidSelectMaskSwitch.snp.makeConstraints { make in
            make.left.equalTo(dgc_showInvalidMaskLabel.snp.right).offset(dgc_horSpacing)
            make.centerY.equalTo(dgc_showInvalidMaskLabel)
        }
        
        // 使用自定义相机
        let dgc_customCameraLabel = createLabel("使用自定义相机")
        dgc_containerView.addSubview(dgc_customCameraLabel)
        dgc_customCameraLabel.snp.makeConstraints { make in
            make.top.equalTo(dgc_showInvalidMaskLabel.snp.bottom).offset(dgc_velSpacing)
            make.left.equalTo(dgc_previewCountLabel.snp.left)
        }
        
        customCameraSwitch = UISwitch()
        customCameraSwitch.isOn = config.useCustomCamera
        customCameraSwitch.addTarget(self, action: #selector(customCameraChanged), for: .valueChanged)
        dgc_containerView.addSubview(customCameraSwitch)
        customCameraSwitch.snp.makeConstraints { make in
            make.left.equalTo(dgc_customCameraLabel.snp.right).offset(dgc_horSpacing)
            make.centerY.equalTo(dgc_customCameraLabel)
        }
        
        // 闪光灯模式
        let dgc_cameraFlashLabel = createLabel("闪光灯开关")
        dgc_containerView.addSubview(dgc_cameraFlashLabel)
        dgc_cameraFlashLabel.snp.makeConstraints { make in
            make.top.equalTo(dgc_customCameraLabel.snp.bottom).offset(dgc_velSpacing)
            make.left.equalTo(dgc_previewCountLabel.snp.left)
        }
        
        cameraFlashSwitch = UISwitch()
        cameraFlashSwitch.isOn = config.cameraConfiguration.showFlashSwitch
        cameraFlashSwitch.addTarget(self, action: #selector(cameraFlashChanged), for: .valueChanged)
        dgc_containerView.addSubview(cameraFlashSwitch)
        cameraFlashSwitch.snp.makeConstraints { make in
            make.left.equalTo(dgc_cameraFlashLabel.snp.right).offset(dgc_horSpacing)
            make.centerY.equalTo(dgc_cameraFlashLabel)
        }
        
        // 使用自定义弹窗
        let dgc_customAlertLabel = createLabel("自定义alert样式")
        dgc_containerView.addSubview(dgc_customAlertLabel)
        dgc_customAlertLabel.snp.makeConstraints { make in
            make.top.equalTo(dgc_cameraFlashLabel.snp.bottom).offset(dgc_velSpacing)
            make.left.equalTo(dgc_previewCountLabel.snp.left)
        }
        
        customAlertSwitch = UISwitch()
        customAlertSwitch.isOn = uiConfig.customAlertClass != nil
        customAlertSwitch.addTarget(self, action: #selector(customAlertChanged), for: .valueChanged)
        dgc_containerView.addSubview(customAlertSwitch)
        customAlertSwitch.snp.makeConstraints { make in
            make.left.equalTo(dgc_customAlertLabel.snp.right).offset(dgc_horSpacing)
            make.centerY.equalTo(dgc_customAlertLabel)
            make.bottom.equalTo(dgc_containerView.snp.bottom).offset(-20)
        }
        
        view.addSubview(doneBtn)
        doneBtn.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-25)
            make.bottom.equalTo(view.snp.bottomMargin).offset(-40)
            make.size.equalTo(CGSize(width: 50, height: 50))
        }
    }
    
    @objc func dismissBtnClick() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func styleSegmentChanged() {
        uiConfig.style = styleSegment.selectedSegmentIndex == 0 ? .embedAlbumList : .externalAlbumList
    }
    
    @objc func languageButtonClick() {
        let dgc_languagePicker = DGCLanguagePickerView(selectedLanguage: uiConfig.languageType)
        
        dgc_languagePicker.selectBlock = { [weak self] language in
            self?.languageButton.setTitle(language.toString(), for: .normal)
            self?.uiConfig.languageType = language
        }
        
        dgc_languagePicker.show(in: view)
        dgc_languagePicker.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }
    }
    
    @objc func columnStepperValueChanged() {
        columnCountLabel.text = String(Int(columnStepper.value))
        uiConfig.columnCount = Int(columnStepper.value)
    }
    
    @objc func sortAscendingChanged() {
        let dgc_index = sortAscendingSegment.selectedSegmentIndex
        uiConfig.sortAscending = dgc_index == 0
    }
    
    @objc func allowSelectImageChanged() {
        let dgc_allow = allowSelectImageSwitch.isOn
        config.allowSelectImage = dgc_allow
        if !dgc_allow {
            config.allowSelectGif = dgc_allow
            config.allowSelectLivePhoto = dgc_allow
            config.allowSelectOriginal = dgc_allow
            config.allowSelectVideo = !dgc_allow
            
            allowSelectGifSwitch.setOn(dgc_allow, animated: true)
            allowSelectLivePhotoSwitch.setOn(dgc_allow, animated: true)
            allowSelectOriginalSwitch.setOn(dgc_allow, animated: true)
            allowSelectVideoSwitch.setOn(!dgc_allow, animated: true)
        }
    }
    
    @objc func allowSelectGifChanged() {
        config.allowSelectGif = allowSelectGifSwitch.isOn
    }
    
    @objc func allowSelectLivePhotoChanged() {
        config.allowSelectLivePhoto = allowSelectLivePhotoSwitch.isOn
    }
    
    @objc func allowSelectOriginalChanged() {
        config.allowSelectOriginal = allowSelectOriginalSwitch.isOn
    }
    
    @objc func allowSelectVideoChanged() {
        let dgc_allow = allowSelectVideoSwitch.isOn
        config.allowSelectVideo = dgc_allow
        if !dgc_allow {
            config.allowSelectImage = !dgc_allow
            allowSelectImageSwitch.setOn(!dgc_allow, animated: true)
        }
    }
    
    @objc func allowMixSelectChanged() {
        config.allowMixSelect = allowMixSelectSwitch.isOn
    }
    
    @objc func allowPreviewPhotoChanged() {
        config.allowPreviewPhotos = allowPreviewPhotosSwitch.isOn
    }
    
    @objc func allowEditImageChanged() {
        config.allowEditImage = allowEditImageSwitch.isOn
        
        UIView.animate(withDuration: 0.25) {
            self.editImageToolView.alpha = self.config.allowEditImage ? 1 : 0
            self.editVideoLabel.snp.remakeConstraints { make in
                make.left.equalToSuperview().offset(20)
                if self.config.allowEditImage {
                    make.top.equalTo(self.editImageToolView.snp.bottom).offset(20)
                } else {
                    make.top.equalTo(self.editImageToolView.snp.top)
                }
            }
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func drawToolChanged() {
        if config.editImageConfiguration.tools.contains(.draw) {
            config.editImageConfiguration.tools.removeAll { $0 == .draw }
        } else {
            config.editImageConfiguration.tools.append(.draw)
        }
    }
    
    @objc func clipToolChanged() {
        if config.editImageConfiguration.tools.contains(.clip) {
            config.editImageConfiguration.tools.removeAll { $0 == .clip }
        } else {
            config.editImageConfiguration.tools.append(.clip)
        }
    }
    
    @objc func imageStickerToolChanged() {
        if config.editImageConfiguration.tools.contains(.imageSticker) {
            config.editImageConfiguration.tools.removeAll { $0 == .imageSticker }
        } else {
            config.editImageConfiguration.tools.append(.imageSticker)
        }
    }
    
    @objc func textStickerToolChanged() {
        if config.editImageConfiguration.tools.contains(.textSticker) {
            config.editImageConfiguration.tools.removeAll { $0 == .textSticker }
        } else {
            config.editImageConfiguration.tools.append(.textSticker)
        }
    }
    
    @objc func mosaicToolChanged() {
        if config.editImageConfiguration.tools.contains(.mosaic) {
            config.editImageConfiguration.tools.removeAll { $0 == .mosaic }
        } else {
            config.editImageConfiguration.tools.append(.mosaic)
        }
    }
    
    @objc func filterToolChanged() {
        if config.editImageConfiguration.tools.contains(.filter) {
            config.editImageConfiguration.tools.removeAll { $0 == .filter }
        } else {
            config.editImageConfiguration.tools.append(.filter)
        }
    }
    
    @objc func adjustToolChanged() {
        var dgc_isOn = false
        if config.editImageConfiguration.tools.contains(.adjust) {
            config.editImageConfiguration.tools.removeAll { $0 == .adjust }
        } else {
            dgc_isOn.toggle()
            config.editImageConfiguration.tools.append(.adjust)
        }
        UIView.animate(withDuration: 0.25) {
            self.editImageAdjustToolView.alpha = dgc_isOn ? 1 : 0
            self.editImageAdjustToolView.snp.updateConstraints { make in
                make.height.equalTo(dgc_isOn ? 100 : 0)
            }
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func brightnessChanged() {
        if config.editImageConfiguration.adjustTools.contains(.brightness) {
            config.editImageConfiguration.adjustTools.removeAll { $0 == .brightness }
        } else {
            config.editImageConfiguration.adjustTools.append(.brightness)
        }
    }
    
    @objc func contrastChanged() {
        if config.editImageConfiguration.adjustTools.contains(.contrast) {
            config.editImageConfiguration.adjustTools.removeAll { $0 == .contrast }
        } else {
            config.editImageConfiguration.adjustTools.append(.contrast)
        }
    }
    
    @objc func saturationChanged() {
        if config.editImageConfiguration.adjustTools.contains(.saturation) {
            config.editImageConfiguration.adjustTools.removeAll { $0 == .saturation }
        } else {
            config.editImageConfiguration.adjustTools.append(.saturation)
        }
    }
    
    @objc func saveEditImageChanged() {
        config.saveNewImageAfterEdit = saveEditImageSwitch.isOn
    }
    
    @objc func allowEditVideoChanged() {
        config.allowEditVideo = allowEditVideoSwitch.isOn
    }
    
    @objc func allowDragSelectChanged() {
        config.allowDragSelect = allowDragSelectSwitch.isOn
    }
    
    @objc func allowSlideSelectChanged() {
        config.allowSlideSelect = allowSlideSelectSwitch.isOn
    }
    
    @objc func autoScrollSwitchChanged() {
        config.autoScrollWhenSlideSelectIsActive = autoScrollSwitch.isOn
    }
    
    @objc func allowTakePhotoInLibraryChanged() {
        config.allowTakePhotoInLibrary = allowTakePhotoInLibrarySwitch.isOn
    }
    
    @objc func showCaptureInCameraCellChanged() {
        uiConfig.showCaptureImageOnTakePhotoBtn = showCaptureInCameraCellSwitch.isOn
    }
    
    @objc func showSelectIndexChanged() {
        config.showSelectedIndex = showSelectIndexSwitch.isOn
    }
    
    @objc func showSelectMaskChanged() {
        uiConfig.showSelectedMask = showSelectMaskSwitch.isOn
    }
    
    @objc func showSelectBorderChanged() {
        uiConfig.showSelectedBorder = showSelectBorderSwitch.isOn
    }
    
    @objc func showInvalidSelectMaskChanged() {
        uiConfig.showInvalidMask = showInvalidSelectMaskSwitch.isOn
    }
    
    @objc func customCameraChanged() {
        config.useCustomCamera = customCameraSwitch.isOn
    }
    
    @objc func cameraFlashChanged() {
        config.cameraConfiguration.showFlashSwitch = cameraFlashSwitch.isOn
    }
    
    @objc func customAlertChanged() {
        if customAlertSwitch.isOn {
            uiConfig.customAlertClass = DGCCustomAlertController.self
        } else {
            uiConfig.customAlertClass = nil
        }
    }
}

extension DGCPhotoConfigureCNViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == previewCountTextField {
            config.maxPreviewCount = Int(textField.text ?? "") ?? 20
        } else if textField == selectCountTextField {
            config.maxSelectCount = Int(textField.text ?? "") ?? 9
        } else if textField == minVideoSelectCountTextField {
            config.minVideoSelectCount = Int(textField.text ?? "") ?? 0
        } else if textField == maxVideoSelectCountTextField {
            config.maxVideoSelectCount = Int(textField.text ?? "") ?? 0
        } else if textField == minVideoDurationTextField {
            config.minSelectVideoDuration = Int(textField.text ?? "") ?? 0
        } else if textField == maxVideoDurationTextField {
            config.maxSelectVideoDuration = Int(textField.text ?? "") ?? 120
        } else if textField == cellRadiusTextField {
            uiConfig.cellCornerRadio = CGFloat(Double(textField.text ?? "") ?? 0)
        } else if textField == autoScrollMaxSpeedTextField {
            config.autoScrollMaxSpeed = CGFloat(Double(textField.text ?? "") ?? 0)
        }
    }
}
