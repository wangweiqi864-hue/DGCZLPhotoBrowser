//
//  DGCZLEditorManager.swift
//  DGCZLPhotoBrowser
//
//  Created by long on 2023/9/25.
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

import Foundation

public enum DGCZLEditorAction {
    case draw(DGCZLDrawPath)
    case eraser([DGCZLDrawPath])
    case clip(oldStatus: DGCZLClipStatus, newStatus: DGCZLClipStatus)
    case sticker(oldState: DGCZLBaseStickertState?, newState: DGCZLBaseStickertState?)
    case mosaic(DGCZLMosaicPath)
    case filter(oldFilter: DGCZLFilter?, newFilter: DGCZLFilter?)
    case adjust(oldStatus: DGCZLAdjustStatus, newStatus: DGCZLAdjustStatus)
}

protocol DGCZLEditorManagerDelegate: AnyObject {
    func editorManager(_ manager: DGCZLEditorManager, didUpdateActions dgc_actions: [DGCZLEditorAction], dgc_redoActions: [DGCZLEditorAction])
    
    func editorManager(_ manager: DGCZLEditorManager, undoAction action: DGCZLEditorAction)
    
    func editorManager(_ manager: DGCZLEditorManager, redoAction action: DGCZLEditorAction)
}

class DGCZLEditorManager {
    private(set) var dgc_actions: [DGCZLEditorAction] = []
    private(set) var dgc_redoActions: [DGCZLEditorAction] = []
    
    weak var dgc_delegate: DGCZLEditorManagerDelegate?
    
    init(dgc_actions: [DGCZLEditorAction] = []) {
        self.dgc_actions = dgc_actions
        dgc_redoActions = dgc_actions
    }
    
    func storeAction(_ dgc_action: DGCZLEditorAction) {
        dgc_actions.append(dgc_action)
        dgc_redoActions = dgc_actions
        
        dgc_deliverUpdate()
    }
    
    func undoAction() {
        guard let dgc_preAction = dgc_actions.popLast() else { return }
        
        dgc_delegate?.editorManager(self, undoAction: dgc_preAction)
        dgc_deliverUpdate()
    }
    
    func redoAction() {
        guard dgc_actions.count < dgc_redoActions.count else { return }
        
        let dgc_action = dgc_redoActions[dgc_actions.count]
        dgc_actions.append(dgc_action)
        
        dgc_delegate?.editorManager(self, redoAction: dgc_action)
        dgc_deliverUpdate()
    }
    
    private func dgc_deliverUpdate() {
        dgc_delegate?.editorManager(self, didUpdateActions: dgc_actions, dgc_redoActions: dgc_redoActions)
    }
}
