//
//  DashedLineView.swift
//
//  Created by Andrew Nagata on 12/29/21.
//  Copyright © 2021 rollyk. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable class DashedLineView: UIView {
    
    @IBInspectable var dashColor: UIColor = UIColor.cyan
    @IBInspectable var dashLength: Int = 7
    @IBInspectable var dashSpace: Int = 4
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.backgroundColor = .clear
        self.isOpaque = false
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        self.isOpaque = false
    }

    override func draw(_ rect: CGRect) {
        let p1 = CGPoint(x:0, y: self.frame.height/2)
        let p2 = CGPoint(x:self.frame.width, y:self.frame.height/2)
        
        drawDottedLine(start: p1, end: p2, view: self)
    }
    
    func drawDottedLine(start p0: CGPoint, end p1: CGPoint, view: UIView) {
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = dashColor.cgColor
        shapeLayer.lineWidth = self.frame.height
        shapeLayer.lineDashPattern = [NSNumber.init(value: dashLength), NSNumber.init(value: dashSpace)]

        let path = CGMutablePath()
        path.addLines(between: [p0, p1])
        shapeLayer.path = path
        view.layer.addSublayer(shapeLayer)
    }
}
