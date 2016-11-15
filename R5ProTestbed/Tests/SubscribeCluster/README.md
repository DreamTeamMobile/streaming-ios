#Subscribing To a Cluster Server

#Publishing and subscribing with Red5 Pro clusters

###Example Code

- ***[SubscribeCluster.swift](SubscribeCluster.swift)***

##Configuration of the server.


```Swift
let urlString = "http://" + (Testbed.getParameter("host") as! String) + ":5080/cluster"

NSURLConnection.sendAsynchronousRequest(
	NSURLRequest( URL: NSURL(fileURLWithPath: urlString) ),
	queue: NSOperationQueue(),
	completionHandler:{ (response: NSURLResponse?, data: NSData?, error: NSError?) -> Void in
		
		if ((error) != nil) {
			NSLog("%@", error!);
			return;
		}
		 
		//   Convert our response to a usable NSString
		let dataAsString = NSString( data: data!, encoding: NSUTF8StringEncoding)

		//   The string above is formatted like 99.98.97.96:1234, but we won't need the port portion
		let ip = dataAsString?.substringToIndex((dataAsString?.rangeOfString(":").location)!)
		NSLog("Retrieved %@ from %@, of which the usable IP is %@", dataAsString!, urlString, ip!);
```
<sup>
[SubscribeCluster.swift #19](SubscribeCluster.swift#L19)
</sup>