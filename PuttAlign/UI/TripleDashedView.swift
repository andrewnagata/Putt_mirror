//
//  TripleDashedView.swift
//
//  Created by Andrew Nagata on 12/29/21.
//  Copyright © 2021 rollyk. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable class TripleDashedView: UIView {
    
    @IBInspectable var dashColor: UIColor = UIColor.cyan
    
    private var dashLength: Int = 7
    private var dashSpace: Int = 4
    
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
        let p1a = CGPoint(x:0, y: 0)
        let p2a = CGPoint(x:self.frame.width, y: 0)
        
        let p1b = CGPoint(x:0, y: self.frame.height/2)
        let p2b = CGPoint(x:self.frame.width, y:self.frame.height/2)
        
        let p1c = CGPoint(x:0, y: self.frame.height)
        let p2c = CGPoint(x:self.frame.width, y:self.frame.height)
        
        drawDottedLine(start: p1a, end: p2a, height: 2, length: 2, space: 2)
        drawDottedLine(start: p1b, end: p2b, height: 4, length: 2, space: 2)
        drawDottedLine(start: p1c, end: p2c, height: 2, length: 2, space: 2)
    }
    
    func drawDottedLine(start p0: CGPoint, end p1: CGPoint, height: CGFloat, length: CGFloat, space: CGFloat) {
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = dashColor.cgColor
        shapeLayer.lineWidth = height
        shapeLayer.lineDashPattern = [NSNumber.init(value: length), NSNumber.init(value: space)]

        let path = CGMutablePath()
        path.addLines(between: [p0, p1])
        shapeLayer.path = path
        self.layer.addSublayer(shapeLayer)
    }
}

