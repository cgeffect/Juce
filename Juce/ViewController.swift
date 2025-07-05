//
//  ViewController.swift
//  Juce
//
//  Created by Jason on 2025/7/4.
//

import Cocoa
import AudioKit

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let engine = AudioEngine()
        print(engine)
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

