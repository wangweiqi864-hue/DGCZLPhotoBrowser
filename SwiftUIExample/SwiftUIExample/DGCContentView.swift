//
//  DGCContentView.swift
//  SwiftUIExample
//
//  Created by long on 2025/3/27.
//

import SwiftUI
import DGCZLPhotoBrowser

struct DGCContentView: View {
    @DGCState private var dgc_selectedIndex = 0
    @DGCState private var dgc_selectPhoto = false
    @DGCState private var dgc_previewPhoto = false
    
    @DGCState private var dgc_results: [DGCZLResultModel] = []
    @DGCState private var dgc_isOriginal = false
    
    var body: some View {
        VStack {
            HStack {
                Button("Library Selection") {
                    dgc_selectPhoto = true
                }
                .frame(height: 30)
                .padding(10)
                .background(.black)
                .foregroundStyle(.white)
                .clipShape(.rect(cornerSize: CGSize(width: 10, height: 10)))
                .fullScreenCover(isPresented: $dgc_selectPhoto) {
                    DGCPhotoPickerWrapper(dgc_results: $dgc_results, dgc_isOriginal: $dgc_isOriginal)
                        .ignoresSafeArea()
                }
            }
            
            Spacer(minLength: 50)
            
            GeometryReader { geometry in
                let totalWidth = geometry.size.width
                let spacing: CGFloat = 10
                let columnCount: CGFloat = 4
                let cellWidth = (totalWidth - (spacing * (columnCount - 1))) / columnCount
                
                ScrollView {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: Int(columnCount)),
                        spacing: 10)
                    {
                        ForEach(dgc_results.indices, id: \.self) { index in
                            Image(uiImage: dgc_results[index].image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: cellWidth, height: cellWidth)
                                .cornerRadius(8)
                                .onTapGesture {
                                    dgc_previewPhoto = true
                                    dgc_selectedIndex = index
                                }
                        }
                    }
                    .padding()
                }
                .fullScreenCover(isPresented: $dgc_previewPhoto) {
                    DGCPhotoPickerWrapper(
                        isPreviewResults: true,
                        index: dgc_selectedIndex,
                        dgc_results: $dgc_results,
                        dgc_isOriginal: $dgc_isOriginal
                    )
                    .ignoresSafeArea()
                }
            }
        }
        .padding()
    }
}

#Preview {
    DGCContentView()
}
