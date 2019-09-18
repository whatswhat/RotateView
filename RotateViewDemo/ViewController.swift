//
//  ViewController.swift
//  RotateViewDemo
//
//  Created by Diego on 2019/9/16.
//  Copyright © 2019 whatzwhat. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var valueLabel: UILabel!
    
    @IBOutlet weak var resultLabel: UILabel!
    
    @IBOutlet weak var imageView: UIImageView!
    
    var rotate: RotateView?
    
    var results: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        rotate = RotateView(imageView)
        
        // 順時針或逆時針
        rotate?.lowerValue = 12
        rotate?.upperValue = 0
        
        // 點擊觸發
        rotate?.addPointTarget { value in
            self.showValue(value)
            self.addResult(value)
        }
        
        // 拖移觸發
        rotate?.addRotateTarget({ (value) in
            self.showValue(value)
        }, completion: { (result) in
            self.addResult(result)
        })
    }
    
    private func showValue(_ value: CGFloat) {
        let valueString = String(format:"%.2f", value)
        valueLabel.text = "Value: \(valueString)"
    }
    
    private func addResult(_ value: CGFloat) {
        results.append("\(value.rounded())")
        resultLabel.text = "\(results)"
    }

}

