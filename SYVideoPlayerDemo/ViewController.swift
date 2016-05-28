//
//  ViewController.swift
//  SYVideoPlayerDemo
//
//  Created by Quang Ha on 5/14/16.
//  Copyright © 2016 soyo. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func presentPlayerController(sender: UIButton) {
        let videoPlayer = SYVideoPlayerController()
        
        videoPlayer.presentIn(self)
    }

}

