//
//  PhotoPicker.swift
//  SwiftUIExample
//
//  Created by long on 2025/3/27.
//

import Foundation
import SwiftUI
import DGCZLPhotoBrowser

struct DGCPhotoPickerWrapper: UIViewControllerRepresentable {
    var isPreviewResults = false
    var index = 0
    @Binding var results: [DGCZLResultModel]
    @Binding var isOriginal: Bool
    @Environment(\.dgc_dismiss) private var dgc_dismiss
    
    func makeUIViewController(context: Context) -> some UIViewController {        
        let dgc_picker = DGCZLPhotoPicker()
        dgc_picker.selectImageBlock = { results, isOriginal in
            self.results = results
            self.isOriginal = isOriginal
        }
        dgc_picker.cancelBlock = {
            debugPrint("Cancel Select")
        }
        
        if isPreviewResults {
            return dgc_picker.previewAssetsForSwiftUI(assets: results.map { $0.asset }, index: index, isOriginal: isOriginal)
        } else {
            return dgc_picker.showPhotoLibraryForSwiftUI()
        }
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
}
