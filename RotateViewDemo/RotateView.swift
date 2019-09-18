//
//  RotateView.swift
//  RotateViewDemo
//
//  Created by Diego on 2019/9/16.
//  Copyright © 2019 whatzwhat. All rights reserved.
//
//  ------------------
//  2019/9/18 - v0.1
//  ------------------

import UIKit

class RotateView {

    // 本體 View 轉動事件動畫都會體現在它身上
    private weak var view: UIView!
    // 背景 View 所有的觸控監聽都會加倒它身上
    private lazy var backgroundView = UIView()
    // 點擊用動畫
    private lazy var animator = UIViewPropertyAnimator(duration: animateTime, curve: .easeInOut)
    // 防止點擊動畫重複執行
    private lazy var animatorLock = NSLock()
    // 點擊觸控
    private var pointGesture: PointGestureRecognizer?
    // 點擊後要做的事情
    private var pointHandler: ((CGFloat)->Void)?
    // 拖移觸控
    private var rotateGesture: RotationGestureRecognizer?
    // 拖移開始後要做的事情
    private var rotateHandler: ((CGFloat)->Void)?
    // 拖移結束後要做的事情
    private var rotateCompletion: ((CGFloat)->Void)?
    // 保存角度變化計算移動角度
    private var lastUpdateAngle: CGFloat = 0
    
    /// 在一定程度上這邊是可以自由修改的, 但還是有暫時不能突破的限制
    // 開始角度, 必須為 -Double.pi, 起始位置為正左方, 以此為例 -Double.pi * 0.5 位置會順時針移動到正上方
    private var startAngle = CGFloat(-Double.pi) * 0.5
    // 結束角度, 必須為 Double.pi, 起始位置一樣為正左方與 -pi 無限接近, 以此為例 Double.pi * 1.5 位置一樣會順時針移動到正上方
    private var endAngle = CGFloat(Double.pi) * 1.5

    // 目前 view 角度 (範圍為 0 到 Double.pi * 2)
    private(set) var nowAngle: CGFloat = 0
    // 點擊動畫播放時間
    public var animateTime: TimeInterval = 0.5
    // 影響拖移靈敏度 1 = 沒影響, 0.5 = 減少一半的靈敏度
    public var damping: CGFloat = 0.5
    // 開始值 lowerValue > upperValue 是可以的, 看是要"順時針"還是"逆時針"
    public var lowerValue: CGFloat = 0
    // 結束值
    public var upperValue: CGFloat = 1

    deinit {
        removePoint()
        removeRotate()
        backgroundView.removeFromSuperview()
    }
    
    init(_ view: UIView) {
        self.view = view
        prepareBackgroundView()
    }

    private func prepareBackgroundView() {
        guard let superview = view.superview else {
            return
        }
        backgroundView.frame = view.frame
        backgroundView.backgroundColor = .clear
        backgroundView.isMultipleTouchEnabled = true
        backgroundView.isUserInteractionEnabled = true
        superview.insertSubview(backgroundView, belowSubview: view)
    }
    
    @objc private func handlePointGesture(_ gesture: PointGestureRecognizer) {
        guard animatorLock.try() else { return }
        nowAngle -= getBoundedAngle(gesture.touchAngle)
        reorganizingAngle()
        pointHandler?(getAngleValue(from: nowAngle))
        changeAngle(to: nowAngle, animate: true)
    }
 
    @objc private func handleRotationGesture(_ gesture: RotationGestureRecognizer) {
        
        print(gesture.touchAngle)
        
        if gesture.state == .ended || gesture.state == .cancelled {
            rotateCompletion?(getAngleValue(from: nowAngle))
            lastUpdateAngle = 0
            return
        }
        let touchAngle = getBoundedAngle(gesture.touchAngle)
        if gesture.state == .began {
            lastUpdateAngle = touchAngle
            return
        }
        var moveAngle = touchAngle - lastUpdateAngle
        lastUpdateAngle = touchAngle
        // 0 與 pi * 2 互相轉換邏輯
        if moveAngle > CGFloat.pi {
            moveAngle += CGFloat(Double.pi) * 2
        } else if moveAngle < -CGFloat.pi {
            moveAngle -= CGFloat(Double.pi) * 2
        }
        moveAngle *= damping
        nowAngle += moveAngle
        reorganizingAngle()
        rotateHandler?(getAngleValue(from: nowAngle))
        changeAngle(to: nowAngle)
    }

}



// MARK: - public Methods.
extension RotateView {
    
    public func addPointTarget(_ handler: ((CGFloat)->Void)? = nil) {
        pointHandler = handler
        if pointGesture == nil {
            pointGesture = PointGestureRecognizer(target: self, action: #selector(handlePointGesture(_:)))
            backgroundView.addGestureRecognizer(pointGesture!)
        }
    }
    
    public func addRotateTarget(_ handler: ((CGFloat)->Void)? = nil,
                                completion: ((CGFloat)->Void)? = nil) {
        rotateHandler = handler
        rotateCompletion = completion
        if rotateGesture == nil {
            rotateGesture = RotationGestureRecognizer(target: self, action: #selector(handleRotationGesture(_:)))
            backgroundView.addGestureRecognizer(rotateGesture!)
        }
    }
    
    public func removePoint() {
        if let rotateGesture = rotateGesture {
            backgroundView.removeGestureRecognizer(rotateGesture)
        }
    }
    
    public func removeRotate() {
        if let pointGesture = pointGesture {
            backgroundView.removeGestureRecognizer(pointGesture)
        }
    }
 
}



// MARK: - private Methods.
extension RotateView {
    
    /// 取得矯正後的角度
    private func getBoundedAngle(_ touchAngle: CGFloat) -> CGFloat {
        let midPointAngle = (2 * CGFloat(Double.pi) + startAngle - endAngle) / 2 + endAngle
        var boundedAngle = touchAngle
        if boundedAngle > midPointAngle {
            boundedAngle -= 2 * CGFloat(Double.pi)
        } else if boundedAngle < (midPointAngle - 2 * CGFloat(Double.pi)) {
            boundedAngle -= 2 * CGFloat(-Double.pi)
        }
        boundedAngle = min(endAngle, max(startAngle, boundedAngle))
        return boundedAngle - startAngle
    }
    
    /// 判斷使否重制角度
    private func reorganizingAngle() {
        if nowAngle > CGFloat(Double.pi) * 2 {
            nowAngle -= CGFloat(Double.pi) * 2
        } else if nowAngle < 0 {
            nowAngle += CGFloat(Double.pi) * 2
        }
    }
    
    /// 取得目前所在角度的數值
    private func getAngleValue(from angle: CGFloat) -> CGFloat {
        let angleRange = endAngle - startAngle
        let valueRange = upperValue - lowerValue
        let angleValue = angle / angleRange * valueRange + lowerValue
        return angleValue
    }
  
    /// 改變 View 的角度
    private func changeAngle(to angle: CGFloat, animate: Bool? = nil) {
        guard let animate = animate else {
            view.transform = CGAffineTransform(rotationAngle: angle)
            return
        }
        if animate {
            animator.addAnimations {
                self.view.transform = CGAffineTransform(rotationAngle: angle)
            }
            animator.addCompletion { _ in
                self.animatorLock.unlock()
            }
            animator.startAnimation()
        } else {
            view.transform = CGAffineTransform(rotationAngle: angle)
        }
    }
    
}



// MARK: - Rotate GestureRecognizer.
private class RotationGestureRecognizer: UIPanGestureRecognizer, RotateFormula {
    
    private(set) var touchAngle: CGFloat = 0
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        touchAngle = angle(for: touches, in: view)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        touchAngle = angle(for: touches, in: view)
    }
    
    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        maximumNumberOfTouches = 1
        minimumNumberOfTouches = 1
    }
    
}

private class PointGestureRecognizer: UITapGestureRecognizer, RotateFormula {
    
    private(set) var touchAngle: CGFloat = 0
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        touchAngle = angle(for: touches, in: view)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        touchAngle = angle(for: touches, in: view)
    }
}

// MARK: - Rotate protocol.
private protocol RotateFormula {
    
    func angle(for touches: Set<UITouch>, in view: UIView?) -> CGFloat
    
}

extension RotateFormula {
    
    func angle(for touches: Set<UITouch>, in view: UIView?) -> CGFloat {
        guard
            let touch = touches.first,
            let view = view
        else {
            return 0
        }
        let touchPoint = touch.location(in: view)
        let centerOffset = CGPoint(x: touchPoint.x - view.bounds.midX, y: touchPoint.y - view.bounds.midY)
        return atan2(centerOffset.y, centerOffset.x)
    }
    
}
