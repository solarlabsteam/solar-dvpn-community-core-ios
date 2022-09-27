//
//  ViewController.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Viktoriia Kostyleva on 26.09.2022.
//

import UIKit

class ViewController: UIViewController {
    let server = DVPNServer()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        server.start()
    }
}
