//
//  ViewController.swift
//  DLR WebView
//
//  Created by xulihang on 2022/5/31.
//

import UIKit
import WebKit
import GCDWebServer

class ViewController: UIViewController, WKScriptMessageHandler {
    
    var webServer:GCDWebServer!;
    var webView: WKWebView!
    var button: UIButton!
    var resultLabel: UILabel!
    var initialized = false
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.webServer = GCDWebServer()
        
        let websitePath = Bundle.main.path(forResource: "www", ofType: nil)
        // Add a default handler to serve static files (i.e. anything other than HTML files)
        self.webServer.addGETHandler(forBasePath: "/", directoryPath: websitePath!, indexFilename: nil, cacheAge: 3600, allowRangeRequests: true)
        
        startServer()
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)

        // Do any additional setup after loading the view.
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        if #available(iOS 9.0, *){
            configuration.requiresUserActionForMediaPlayback = false
        }else{
            configuration.mediaPlaybackRequiresUserAction = false
        }
        let contentController = WKUserContentController()
        contentController.add(self,name: "onScanned")
        contentController.add(self,name: "onInitialized")
        configuration.userContentController = contentController
        
        //create the webView with the custom configuration.
        self.webView = WKWebView(frame: .zero, configuration: configuration)
        
        self.button = UIButton(frame: .zero)
        self.button.setTitle("Recognize Text", for: .normal)
        self.button.setTitleColor(.systemBlue, for: .normal)
        self.button.setTitleColor(.lightGray, for: .highlighted)

        self.button.addTarget(self,
                         action: #selector(buttonAction),
                         for: .touchUpInside)
        
        
        self.resultLabel = UILabel()
        self.resultLabel.textAlignment = NSTextAlignment.center
        self.resultLabel.numberOfLines = 0
        self.resultLabel.lineBreakMode = .byCharWrapping
        
        self.view.addSubview(self.resultLabel)
        self.view.addSubview(self.button)
        self.view.addSubview(self.webView)
        
        self.webView.isHidden = true
        
        
        let url = URL(string:"http://localhost:8888/scanner.html")
        let request = URLRequest(url: url!)
        self.webView.load(request)
    }
    
    func startServer(){
        
        self.webServer.start(withPort: 8888, bonjourName: "GCD Web Server")
    }
    
    @objc
    func buttonAction() {
        startScan();
    }
    
    func startScan(){
        if self.initialized == true {
            self.webView.isHidden = false
            self.webView.evaluateJavaScript("startScan();")
        }else{
            print("not initialized")
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let webView = self.webView {
            let insets = view.safeAreaInsets
            let width: CGFloat = view.frame.width
            let x = view.frame.width - insets.right - width
            let y = insets.top
            let height = view.frame.height - insets.top - insets.bottom
            webView.frame = CGRect.init(x: x, y: y, width: width, height: height)
        }
        if let button = self.button {
            let width: CGFloat = 300
            let height: CGFloat = 50
            let x = view.frame.width/2 - width/2
            let y = view.frame.height - 100
            button.frame = CGRect.init(x: x, y: y, width: width, height: height)
        }
        if let label = self.resultLabel {
            let width: CGFloat = 300
            let height: CGFloat = 200
            let x = view.frame.width/2 - width/2
            let y = 50.0
            label.frame = CGRect.init(x: x, y: y, width: width, height: height)
        }
    }
    
    @objc func applicationWillResignActive(notification: NSNotification){
        print("entering background")
        self.webView.evaluateJavaScript("stopScan();")
    }
    
    @objc func applicationDidBecomeActive(notification: NSNotification) {
        print("back active")
        if self.webView.isHidden == false {
            print("Scanner is on, start scan")
            self.webView.evaluateJavaScript("startScan();")
        }
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("mesasge name: "+message.name)
        if message.name == "onScanned" {
            self.webView.isHidden = true
            self.resultLabel.text = message.body as? String
            print("JavaScript is sending a message \(message.body)")
        } else if message.name == "onInitialized" {
            self.initialized = true
        }
    }
}
