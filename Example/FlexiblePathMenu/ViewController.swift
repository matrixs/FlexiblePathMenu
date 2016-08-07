//
//  ViewController.swift
//  FlexiblePathMenu
//
//  Created by matrixs on 08/03/2016.
//  Copyright (c) 2016 matrixs. All rights reserved.
//

import UIKit
import FlexiblePathMenu

class ViewController: UIViewController, FPMItemsViewClickDelegate {
    
    var pathMenu: FlexiblePathMenu!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let center = UIImageView(frame: CGRectMake(0, 0, 40, 40))
        center.image = UIImage(named: "icon4")
        pathMenu = FlexiblePathMenu(frame: CGRectMake(0, 0, 300, 300) ,centerView: center)
        pathMenu.clickDelegate = self
        view.addSubview(pathMenu)
        pathMenu.draggable = true
        pathMenu.scrollable = true
        pathMenu.menuStartArc = M_PI_2
        pathMenu.menuEndArc = M_PI
        
        pathMenu.scrollStartArc = M_PI_2
        pathMenu.scrollEndArc = M_PI_2*3
        
        var item = UIImageView(frame: CGRectMake(0, 0, 40, 40))
        item.image = UIImage(named: "setting")
        pathMenu.addItemView(item)
        
        item = UIImageView(frame: CGRectMake(0, 0, 40, 40))
        item.image = UIImage(named: "icon2")
        pathMenu.addItemView(item)

        item = UIImageView(frame: CGRectMake(0, 0, 40, 40))
        item.image = UIImage(named: "icon3")
        pathMenu.addItemView(item)
        
        item = UIImageView(frame: CGRectMake(0, 0, 40, 40))
        item.image = UIImage(named: "icon5")
        pathMenu.addItemView(item)
        
        pathMenu.scrollAngleGranularity = .CoustomNum
        pathMenu.scrollMinimiumNum = 4
        
        pathMenu.itemViewAniamtionType = .RotateLinear
    }
    
    func clickAt(view: UIView) {
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

