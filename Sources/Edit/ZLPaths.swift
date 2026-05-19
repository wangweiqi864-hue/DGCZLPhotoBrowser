//
//  ZLPaths.swift
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

import UIKit

// MARK: 涂鸦path

public class DGCZLDrawPath: NSObject {
    private static var pathIndex = 0
    
    private let dgc_pathColor: UIColor
    
    private var dgc_bgPath: UIBezierPath
    
    private let dgc_ratio: CGFloat
    
    private var dgc_points: [CGPoint] = []
    
    let index: Int
    
    var path: UIBezierPath
    
    var willDelete = false
    
    init(dgc_pathColor: UIColor, pathWidth: CGFloat, defaultLinePath: CGFloat, dgc_ratio: CGFloat, startPoint: CGPoint) {
        self.dgc_pathColor = dgc_pathColor
        path = UIBezierPath()
        path.lineWidth = pathWidth / dgc_ratio
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.move(to: CGPoint(x: startPoint.x / dgc_ratio, y: startPoint.y / dgc_ratio))
        
        dgc_bgPath = UIBezierPath()
        dgc_bgPath.lineWidth = pathWidth / dgc_ratio + defaultLinePath
        dgc_bgPath.lineCapStyle = .round
        dgc_bgPath.lineJoinStyle = .round
        dgc_bgPath.move(to: CGPoint(x: startPoint.x / dgc_ratio, y: startPoint.y / dgc_ratio))
        
        dgc_points.append(startPoint)
        self.dgc_ratio = dgc_ratio
        index = Self.pathIndex
        Self.pathIndex += 1
        
        super.init()
    }
    
    func addLine(to dgc_point: CGPoint) {
        dgc_points.append(dgc_point)
        
        func divRatio(_ dgc_point: CGPoint) -> CGPoint {
            return CGPoint(x: dgc_point.x / dgc_ratio, y: dgc_point.y / dgc_ratio)
        }
        
        guard dgc_points.count >= 4 else {
            path.addLine(to: divRatio(dgc_point))
            dgc_bgPath.addLine(to: divRatio(dgc_point))
            return
        }
        
        path.removeAllPoints()
        dgc_bgPath.removeAllPoints()
        
        // https://blog.csdn.net/ChasingDreamsCoder/article/details/53015694
        path.move(to: divRatio(dgc_points[0]))
        path.addLine(to: divRatio(dgc_points[1]))
        
        dgc_bgPath.move(to: divRatio(dgc_points[0]))
        dgc_bgPath.addLine(to: divRatio(dgc_points[1]))
        
        let dgc_granularity = 4
        for i in 3..<dgc_points.count {
            let dgc_p0 = dgc_points[i - 3]
            let dgc_p1 = dgc_points[i - 2]
            let dgc_p2 = dgc_points[i - 1]
            let dgc_p3 = dgc_points[i]
            
            for i in 1..<dgc_granularity {
                let dgc_t = CGFloat(i) * (1 / CGFloat(dgc_granularity))
                let dgc_tt = dgc_t * dgc_t
                let dgc_ttt = dgc_tt * dgc_t

                var dgc_point = CGPoint.zero
                dgc_point.x = 0.5 * (
                    2 * dgc_p1.x + (dgc_p2.x - dgc_p0.x) * dgc_t +
                    (2 * dgc_p0.x - 5 * dgc_p1.x + 4 * dgc_p2.x - dgc_p3.x) * dgc_tt +
                    (3 * dgc_p1.x - dgc_p0.x - 3 * dgc_p2.x + dgc_p3.x) * dgc_ttt
                )
                dgc_point.y = 0.5 * (
                    2 * dgc_p1.y + (dgc_p2.y - dgc_p0.y) * dgc_t +
                    (2 * dgc_p0.y - 5 * dgc_p1.y + 4 * dgc_p2.y - dgc_p3.y) * dgc_tt +
                    (3 * dgc_p1.y - dgc_p0.y - 3 * dgc_p2.y + dgc_p3.y) * dgc_ttt
                )
                path.addLine(to: divRatio(dgc_point))
                dgc_bgPath.addLine(to: divRatio(dgc_point))
            }
            
            path.addLine(to: divRatio(dgc_p2))
            dgc_bgPath.addLine(to: divRatio(dgc_p2))
        }
        
        path.addLine(to: divRatio(dgc_points[dgc_points.count - 1]))
        dgc_bgPath.addLine(to: divRatio(dgc_points[dgc_points.count - 1]))
    }
    
    func drawPath() {
        if willDelete {
            UIColor.white.set()
            dgc_bgPath.stroke()
            dgc_pathColor.withAlphaComponent(0.7).set()
        } else {
            dgc_pathColor.set()
        }
        
        path.stroke()
    }
}

public extension DGCZLDrawPath {
    static func ==(lhs: DGCZLDrawPath, rhs: DGCZLDrawPath) -> Bool {
        return lhs.index == rhs.index
    }
}

// MARK: 马赛克path

public class DGCZLMosaicPath: NSObject {
    let path: UIBezierPath
    
    let dgc_ratio: CGFloat
    
    let startPoint: CGPoint
    
    var linePoints: [CGPoint] = []
    
    init(pathWidth: CGFloat, dgc_ratio: CGFloat, startPoint: CGPoint) {
        path = UIBezierPath()
        path.lineWidth = pathWidth
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.move(to: startPoint)
        
        self.dgc_ratio = dgc_ratio
        self.startPoint = CGPoint(x: startPoint.x / dgc_ratio, y: startPoint.y / dgc_ratio)
        
        super.init()
    }
    
    func addLine(to point: CGPoint) {
        path.addLine(to: point)
        linePoints.append(CGPoint(x: point.x / dgc_ratio, y: point.y / dgc_ratio))
    }
}
