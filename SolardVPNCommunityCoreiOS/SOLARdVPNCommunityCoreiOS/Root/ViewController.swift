//
//  ViewController.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Viktoriia Kostyleva on 26.09.2022.
//

import UIKit
import WebKit

final class ViewController: UIViewController {
    private let server = DVPNServer(context: ContextBuilder().buildContext())
    private var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        server.start()
        setUpWebView()
    }
}

// MARK: Private

extension ViewController {
    private func setUpWebView() {
        let webConfiguration = WKWebViewConfiguration()
        
        webConfiguration.setValue(true, forKey: "_allowUniversalAccessFromFileURLs")
        
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        view = webView
        
        guard let path = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "dist") else {
            log.error("Fail to load UI from resources")
            return
        }
        
        webView.loadFileURL(path, allowingReadAccessTo: path)
    }
}
