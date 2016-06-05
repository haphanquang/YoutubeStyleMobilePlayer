//
//  ViewController.swift
//  SYVideoPlayerDemo
//
//  Created by Quang Ha on 5/14/16.
//  Copyright © 2016 soyo. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage
import XCDYouTubeKit
import Foundation

class ViewController: UIViewController {
    
    static let YoutubeAPIKey = "AIzaSyCFbGK0NBsOl39gbeRc9bv8EgJwe-U7R1A"
    static let Part = "snippet"
    static let MaxResults = "25"
    
    var searchUrl: String = "https://www.googleapis.com/youtube/v3/search?part=snippet&q=nhu%20quynh&type=video&maxResults=40&key=AIzaSyCFbGK0NBsOl39gbeRc9bv8EgJwe-U7R1A"
    
    var videoArray: [NSDictionary] = [NSDictionary]()

    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let top = self.topLayoutGuide.length
        let bottom = self.bottomLayoutGuide.length
        let newInsets = UIEdgeInsetsMake(top, 0, bottom, 0)
        collectionView.contentInset = newInsets
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = UIColor.whiteColor()
        
        searchBar.delegate = self
        loadSampleYoutubeVideo()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func presentPlayerController(sender: UIButton) {
        
    }

    
    func loadSampleYoutubeVideo (){
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        Alamofire.request(.GET, searchUrl, parameters: ["foo": "bar"])
            .responseJSON { response in
                print(response.request)  // original URL request
                print(response.response) // URL response
                print(response.data)     // server data
                print(response.result)   // result of response serialization
                
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                if let JSON = response.result.value {
                    print("JSON: \(JSON)")
                    if let array = JSON.objectForKey("items") as? [NSDictionary] {
                        self.videoArray.removeAll()
                        self.videoArray.appendContentsOf(array)
                        self.collectionView.reloadData()
                    }
                }
        }
    }
    
//    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
//        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
//        self.collectionView.reloadData()
//    }
    override func shouldAutorotate() -> Bool {
        return false
    }
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }
}

extension ViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        
        let characters = NSCharacterSet.URLQueryAllowedCharacterSet().mutableCopy() as! NSMutableCharacterSet
        
        characters.removeCharactersInString("&")
        
        guard let encodedString = searchBar.text?.stringByAddingPercentEncodingWithAllowedCharacters(characters) else {
            return
        }
        
        searchBar.resignFirstResponder()
        searchUrl = "https://www.googleapis.com/youtube/v3/search?part=snippet&q=\(encodedString)&type=video&maxResults=40&key=AIzaSyCFbGK0NBsOl39gbeRc9bv8EgJwe-U7R1A"
        loadSampleYoutubeVideo()
    }
}

extension ViewController : UICollectionViewDelegate {
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        

        let item = self.videoArray[indexPath.row]
        if let videoId = item["id"] as? NSDictionary {
            if let videoIDString = videoId["videoId"] as? String {
                
                let client = XCDYouTubeClient.defaultClient()
                client.getVideoWithIdentifier(videoIDString, completionHandler: { (video, error) in
                    let videoPlayer = SYVideoPlayerController.currentVideoPlayer
                    
                    videoPlayer.presentIn(self.navigationController!)
                    
                    // should improve - some video not have hd720
                    let key = NSNumber(integer: Int(XCDYouTubeVideoQuality.Medium360.rawValue)) as NSObject
                    
                    videoPlayer.playVideo(video!.streamURLs[key]!)
                })
            }
            
        }
        
        
    }
}
extension ViewController: UICollectionViewDataSource {
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videoArray.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("YoutubeVideoCell", forIndexPath: indexPath) as! YoutubeVideoCell
        
        let item = self.videoArray[indexPath.row]
        if let snippet = item["snippet"] as? NSDictionary {
            cell.lblTitle.text = snippet["title"] as? String
            
            if let thumbnails = snippet["thumbnails"] as? NSDictionary {
                if let defaultThumb = thumbnails["high"] as? NSDictionary {
                    if let url = defaultThumb["url"] as? String {
                        cell.imgThumb.af_setImageWithURL(NSURL(string: url)!)
                    }
                }
            }
        }
        
        
        cell.layer.masksToBounds = false
        cell.layer.borderColor = UIColor.whiteColor().CGColor
        cell.layer.borderWidth = 2.0
        cell.layer.shadowOpacity = 0.4
        cell.layer.shadowRadius = 1.0
        cell.layer.shadowOffset = CGSizeZero
        cell.layer.shadowPath = UIBezierPath(rect: cell.bounds).CGPath
        
        return cell
    }
}

extension ViewController : UICollectionViewDelegateFlowLayout {
    //1
    func collectionView(collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {

        return CGSize(width: UIScreen.mainScreen().bounds.size.width / 2 - 20, height: (UIScreen.mainScreen().bounds.size.width / 2 - 20) * 0.75)
    }
    
    func collectionView(collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                               insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(10, 10, 10, 10)
    }
}

//navigation
class MyNavigation: UINavigationController {
    override func shouldAutorotate() -> Bool {
        return true
    }
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return .AllButUpsideDown
    }
}

