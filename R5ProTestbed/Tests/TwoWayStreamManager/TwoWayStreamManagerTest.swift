//
//  TwoWayStreamManagerTest.swift
//  R5ProTestbed
//
//  Created by David Heimann on 7/2/18.
//  Copyright © 2018 Infrared5. All rights reserved.
//

import UIKit
import R5Streaming

@objc(TwoWayStreamManagerTest)
class TwoWayStreamManagerTest: BaseTest {
    var publishView : R5VideoViewController? = nil
    var timer : Timer? = nil
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        requestServer(Testbed.getParameter(param: "stream1") as! String, action: "broadcast", resolve: { (url) in
            self.publishTo(url: url)
        })
        callForStreamList()
    }
    
    func requestServer(_ streamName: String, action: String, resolve: @escaping (_ ip: String) -> Void) {
        
        let port = (Testbed.getParameter(param: "server_port") as! String)
        let portURI = port == "80" ? "" : ":" + port
        let originURI = "http://" + (Testbed.getParameter(param: "host") as! String) + portURI + "/streammanager/api/2.0/event/" +
            (Testbed.getParameter(param: "context") as! String) + "/" + streamName + "?action=" + action
        
        NSURLConnection.sendAsynchronousRequest(
            NSURLRequest( url: NSURL(string: originURI)! as URL ) as URLRequest,
            queue: OperationQueue(),
            completionHandler:{ (response: URLResponse?, data: Data?, error: Error?) -> Void in
                
                if ((error) != nil) {
                    print(error!)
                    return
                }
                
                //   The string above is in JSON format, we specifically need the serverAddress value
                var json: [String: AnyObject]
                do{
                    json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions()) as! [String: AnyObject]
                }catch{
                    print(error)
                    return
                }
                
                if let ip = json["serverAddress"] as? String {
                    resolve(ip)
                }
                else if let errorMessage = json["errorMessage"] as? String {
                    print(AccessError.error(message: errorMessage))
                }
                
        })
    }
    
    func delayCallForList() {
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(callForStreamList), userInfo: nil, repeats: false)
    }
    
    func callForStreamList(){
        
        let domain = Testbed.getParameter(param: "host") as! String
        let url = "http://" + domain + ":5080/streammanager/api/2.0/event/list"
        let request = URLRequest.init(url: URL.init(string: url)!)
        
        NSURLConnection.sendAsynchronousRequest(request, queue: OperationQueue.init(), completionHandler: { (response: URLResponse?, data: Data?, error: Error?) -> Void in
            
            //parse the response
            if (error != nil) {
                NSLog("Error, %@", error!.localizedDescription)
            } else {
                
                do{
                    let list = try JSONSerialization.jsonObject(with: data!) as! Array<Dictionary<String, String>>;
                    
                    for dict:Dictionary<String, String> in list {
                        if(dict["name"] == (Testbed.getParameter(param: "stream2") as! String)){
                            self.requestServer(Testbed.getParameter(param: "stream2") as! String, action: "subscribe", resolve: { (url) in
                                self.subscribeTo(url: url)
                            })
                            return
                        }
                    }
                    
                    
                }catch let error as NSError {
                    print(error)
                }
            }
            
            self.delayCallForList()
        })
    }
    
    func publishTo( url: String ){
        let config = getConfig()
        config.host = url
        
        //   Create a new connection using the configuration above
        let connection = R5Connection(config: config)
        
        //   UI updates must be on the main queue
        DispatchQueue.main.async(execute: {
            //   Create our new stream that will utilize that connection
            self.setupPublisher(connection: connection!)
            
            // show preview and debug info
            self.publishView!.attach(self.publishStream!)
            
            self.publishStream!.publish(Testbed.getParameter(param: "stream1") as! String, type: R5RecordTypeLive)
            
            let label = UILabel(frame: CGRect(x: 0, y: self.view.frame.height-24, width: self.view.frame.width, height: 24))
            label.textAlignment = NSTextAlignment.left
            label.backgroundColor = UIColor.lightGray
            label.text = "Pub Connected to: " + url
            self.view.addSubview(label)
        })
    }
    
    func subscribeTo( url: String ) {
        let config = getConfig()
        config.host = url
        
        //   Create a new connection using the configuration above
        let connection = R5Connection(config: config)
        
        //   UI updates must be on the main queue
        DispatchQueue.main.async(execute: {
            //   Create our new stream that will utilize that connection
            self.subscribeStream = R5Stream(connection: connection)
            
            // show preview and debug info
            self.currentView?.attach(self.subscribeStream!)
            
            self.subscribeStream!.play(Testbed.getParameter(param: "stream2") as! String)
            
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 24))
            label.textAlignment = NSTextAlignment.left
            label.backgroundColor = UIColor.lightGray
            label.text = "Sub Connected to: " + url
            self.view.addSubview(label)
        })
    }
    
    override func closeTest() {
        
        if( self.timer != nil ){
            self.timer!.invalidate();
        }
        
        super.closeTest()
    }
}
