//
//  SYVideoPlayerController.swift
//  SYVideoPlayerDemo
//
//  Created by Quang Ha on 5/14/16.
//  Copyright © 2016 soyo. All rights reserved.
//

import Foundation
import UIKit
import MobilePlayer

enum PresentingState {
    case StateNotDetermine
    case StateFullScreen
    case StateNormal
    case StateMinimal
    case StateHidding
}

protocol SYVideoPlayerDelegate {
    
}

var screenWidth: CGFloat = UIScreen.mainScreen().bounds.width
var screenHeight: CGFloat = UIScreen.mainScreen().bounds.height

let videoSizeRatio: CGFloat = 16.0/9.0
let minimalPadding: CGFloat = 3.0
let minimalSize: CGSize = CGSizeMake(190, 190 / videoSizeRatio)

public class SYVideoPlayerController: UIViewController {
    
    public static let currentVideoPlayer = SYVideoPlayerController()

    let videoContainer: UIView = UIView(frame: CGRectZero)
    let otherContainer: UIView = UIView(frame: CGRectZero)
    var moviePlayer: MobilePlayerViewController?
    
    var isAnimating = false
    var isSwiping = false
    
    //configable
    let backgroundWhite: CGFloat = 0.3
    var backgroundAlpha: CGFloat = 0.7
    
    let maxVideoCornerRadius: CGFloat = 4
    let maxVideoShadowOpacity: Float = 0.5
    
    var currentCornerRadius: CGFloat = 0.0
    var currentShadowOpacity: Float = 0.0
    
    
    //frame and position
    var startX: CGFloat = 0.0
    var startY: CGFloat = 0.0
    var previousX: CGFloat = 0.0
    var previousY: CGFloat = 0.0
    
    var minimizeFrame: CGRect = CGRectZero
    
    //gesture
    var swipeDownGesture: UIPanGestureRecognizer?
    var swipeLeftRightGesture: UIPanGestureRecognizer?
    var tapToNormalGesture: UITapGestureRecognizer?
    
    //controlling state
    var presentingState: PresentingState = .StateNormal
    var nextState: PresentingState = .StateMinimal
    
    
    //dismiss controll
    var isReadyToDismiss: Bool = false
    var beginX: CGFloat = 0.0
    
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setNeedsStatusBarAppearanceUpdate()
    }
    
    public override func loadView() {
        super.loadView()
        
        videoContainer.layer.masksToBounds = false
        videoContainer.layer.shadowRadius = 4.0
        videoContainer.layer.shadowOffset = CGSizeMake(0, 0)
        
        videoContainer.layer.shadowOpacity = currentShadowOpacity
        videoContainer.layer.cornerRadius = currentCornerRadius
        
        minimizeFrame = CGRectMake(screenWidth - minimalSize.width - minimalPadding, screenHeight - minimalSize.height - minimalPadding, minimalSize.width, minimalSize.height)
        
        self.view = PassThroughView(frame: self.view.bounds)
        
        view.addSubview(videoContainer)
        view.addSubview(otherContainer)
        
        view.backgroundColor = UIColor(white: backgroundWhite, alpha: backgroundAlpha)
        
        otherContainer.backgroundColor = UIColor.greenColor()
        videoContainer.backgroundColor = UIColor.redColor()
        
        addGestures()
        
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        NSLog("self frame %@", NSStringFromCGRect(self.view.frame))
    }
    
    func updateContainerLayout (presentState: PresentingState) {
        
        let screenBounds = UIScreen.mainScreen().bounds
        
        var videoFrame = videoContainer.frame
        var otherFrame = otherContainer.frame
        
        switch presentState {
            
        case .StateNormal:
            
            videoFrame.origin.x = 0
            videoFrame.origin.y = 0
            videoFrame.size.width = screenBounds.size.width
            videoFrame.size.height = screenBounds.size.width / videoSizeRatio
            
            videoContainer.layer.shadowOpacity = 0.0
            videoContainer.layer.cornerRadius = 0.0
        
            view.backgroundColor = UIColor(white: backgroundWhite, alpha: backgroundAlpha)
            otherContainer.alpha = 1.0
            
            moviePlayer?.controlsHidden = false
            moviePlayer?.view.userInteractionEnabled = true
            
            
            if let btnSize = moviePlayer?.getViewForElementWithIdentifier("size_control") as? UIButton {
                btnSize.setImage(UIImage(named: "full_screen"), forState: .Normal)
            }
            
            break
        case .StateFullScreen :
            videoFrame.origin.x = 0
            videoFrame.origin.y = 0
            
            //ngược ??
            videoFrame.size.width = screenBounds.size.width
            videoFrame.size.height = screenBounds.size.height
            
            videoContainer.layer.shadowOpacity = 0.0
            videoContainer.layer.cornerRadius = 0.0
            
            view.backgroundColor = UIColor(white: backgroundWhite, alpha: 0.0)
            otherContainer.alpha = 0.0
            
            moviePlayer?.controlsHidden = false
            moviePlayer?.view.userInteractionEnabled = true
            
            if let btnSize = moviePlayer?.getViewForElementWithIdentifier("size_control") as? UIButton {
                btnSize.setImage(UIImage(named: "normal_screen"), forState: .Normal)
            }
            
            break
        case .StateMinimal:
            videoFrame = minimizeFrame
            videoContainer.layer
            
            videoContainer.layer.shadowOpacity = maxVideoShadowOpacity
            videoContainer.layer.cornerRadius = maxVideoCornerRadius
            
            view.backgroundColor = UIColor(white: backgroundWhite, alpha: 0.0)
            otherContainer.alpha = 0.0
            
            moviePlayer?.controlsHidden = true
            moviePlayer?.view.userInteractionEnabled = false
            
            if let btnSize = moviePlayer?.getViewForElementWithIdentifier("size_control") as? UIButton {
                btnSize.setImage(UIImage(named: "full_screen"), forState: .Normal)
            }
            
            break
        default:
            break
        }
        
        otherFrame.origin.x = videoFrame.origin.x
        otherFrame.origin.y = videoFrame.size.height + videoFrame.origin.y
        
        otherFrame.size.width = screenBounds.size.width
        otherFrame.size.height = screenBounds.size.height - videoFrame.size.height
        
        videoContainer.alpha = 1.0
        
        videoContainer.frame = videoFrame
        moviePlayer?.view.frame = videoContainer.bounds
        
        otherContainer.frame = otherFrame

    }
    
    public override func prefersStatusBarHidden() -> Bool {
        return true
    }
}

//MARK: Gesture
extension SYVideoPlayerController {
    func addGestures() {
        //all state control
        swipeDownGesture = UIPanGestureRecognizer(target: self, action: #selector(SYVideoPlayerController.doPan))
        swipeDownGesture?.delegate = self
        
        //minimal control
        tapToNormalGesture = UITapGestureRecognizer(target: self, action: #selector(SYVideoPlayerController.doTapInMinimal))
        tapToNormalGesture?.delegate = self;
        
        swipeLeftRightGesture = UIPanGestureRecognizer(target: self, action: #selector(SYVideoPlayerController.doHorizontalPan))
        swipeLeftRightGesture?.delegate = self
        
        videoContainer.addGestureRecognizer(swipeDownGesture!)
        videoContainer.addGestureRecognizer(tapToNormalGesture!)
        videoContainer.addGestureRecognizer(swipeLeftRightGesture!)
    }
    
    func doTapInMinimal (gesture: UITapGestureRecognizer) {
        if presentingState == .StateMinimal {
            nextState = .StateNormal
            animateToNextState()
        }
    }
    
    func doHorizontalPan(gesture: UIPanGestureRecognizer) {
        if presentingState == .StateMinimal {
            let translatedPoint = gesture.translationInView(view)
            
            switch gesture.state {
            case .Began:
                beginX = videoContainer.frame.origin.x
                break
            case .Changed:
                
                isSwiping = true
                
                let nextX = beginX + translatedPoint.x
                
                if (translatedPoint.x > minimizeFrame.size.width / 3) || (translatedPoint.x < -minimizeFrame.size.width / 2)  {
                    isReadyToDismiss = true
                    videoContainer.alpha = 0.6
                }else{
                    isReadyToDismiss = false
                    videoContainer.alpha = 1.0
                }
                
                var frame = videoContainer.frame
                frame.origin.x = nextX
                videoContainer.frame = frame
                
                break
            case .Ended:
                
                if isReadyToDismiss {
                    self.dismissPlayer()
                }else{
                    self.nextState = .StateMinimal
                    animateToNextState()
                }
                
                break
            default:
                return
            }
        }
    }
    
    func doPan(gesture: UIPanGestureRecognizer) {
        let translatedPoint = gesture.translationInView(view)
        
        NSLog("Translated \(translatedPoint)")
        
        switch gesture.state {
        case .Began:
            startX = videoContainer.frame.origin.x
            startY = videoContainer.frame.origin.y
            
            previousX = startX
            previousY = startY
            
            moviePlayer?.controlsHidden = true
            
            break
        case .Changed:
            
            isSwiping = true
            
            if translatedPoint.y != 0 {
                let nextY = startY + translatedPoint.y
                changeVideoContainerFrame(nextY - previousY)
                previousY = videoContainer.frame.origin.y
            }
            
            break
        case .Ended:
            
            if translatedPoint.y < 0 {
                if abs(translatedPoint.y) > view.bounds.size.height / 3 {
                    nextState = .StateNormal
                }else{
                    nextState = .StateMinimal
                }
            }else{
                if abs(translatedPoint.y) > view.bounds.size.height / 3 {
                    nextState = .StateMinimal
                }else{
                    nextState = .StateNormal
                }
            }
            
            animateToNextState()
            
            break
        default:
            return
        }
    }
    
    func changeVideoContainerFrame(translateY: CGFloat) {
        var containerFrame = videoContainer.frame
        var deltaY = translateY
        
        var targetY = containerFrame.origin.y + deltaY
        
        if translateY > 0 {
            if targetY > minimizeFrame.origin.y {
                targetY = minimizeFrame.origin.y
                deltaY = 0
            }
        }else{
            if targetY < 0 {
                targetY = 0
                deltaY = 0
            }
        }
        
        let rateChanged = deltaY / minimizeFrame.origin.y
        
        let targetWidth = containerFrame.size.width - (view.bounds.size.width - minimizeFrame.size.width) * rateChanged
        let targetHeight = targetWidth / videoSizeRatio
        let targetX = view.bounds.size.width - targetWidth
        
        containerFrame = CGRectMake(targetX, targetY, targetWidth, targetHeight)
        
        NSLog("Video Frame \(containerFrame)")
        videoContainer.frame = containerFrame
        
        var otherFrame = otherContainer.frame
        otherFrame.origin.x = containerFrame.origin.x
        otherFrame.origin.y = containerFrame.origin.y + containerFrame.size.height
        otherFrame.size.width = view.bounds.size.width
        
        NSLog("Other Frame \(containerFrame)")
        
        otherContainer.frame = otherFrame
        otherContainer.alpha = otherContainer.alpha - rateChanged
        
        backgroundAlpha = backgroundAlpha - rateChanged * 0.6
        if backgroundAlpha < 0 {
            backgroundAlpha = 0
        }
        
        view.backgroundColor = UIColor(white: backgroundWhite, alpha: backgroundAlpha)
    }
    
    func animateToNextState () {
        isAnimating = true
        UIView.animateWithDuration(0.3, animations: {
            self.updateContainerLayout(self.nextState)
        }, completion: { (completed) in
            self.completeChangeState()
        })
    }
    
    func completeChangeState () {
        self.presentingState = self.nextState
        
        if self.presentingState == .StateMinimal || self.presentingState == .StateFullScreen {
            self.updateStatusBarFrame(0)
        }else{
            self.updateStatusBarFrame(-20)
        }
        
        self.isSwiping = false
        self.isAnimating = false
        self.nextState = .StateNotDetermine
    }
    
    func updateStatusBarFrame(y: CGFloat) -> () {
        UIView.animateWithDuration(0.3) {
            let statusBarWindow = UIApplication.sharedApplication().valueForKey("statusBarWindow") as! UIWindow
            var frame = statusBarWindow.frame
            frame.origin.y = y
            statusBarWindow.frame = frame
        }
    }
    
    
    public override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        NSLog("Size to move: %@, self bound: %@", NSStringFromCGSize(size), NSStringFromCGRect(self.view.frame))
        
        if self.presentingState != .StateFullScreen {
            self.nextState = .StateFullScreen
        }else{
            self.nextState = .StateNormal
        }
        
        coordinator.animateAlongsideTransition({ (context) in
            self.updateContainerLayout(self.nextState)
        }) { (context) in
            self.completeChangeState()
        }
    }
}

extension SYVideoPlayerController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if self.presentingState == .StateMinimal {
            return false
        }
        return true
    }
    public func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if isAnimating {
            return false
        }
        
        if let panGesture = gestureRecognizer as? UIPanGestureRecognizer {
            if panGesture == swipeDownGesture {
                let translate = panGesture.translationInView(self.view)
                switch presentingState {
                case .StateNormal:
                    return translate.y > 0
                case .StateMinimal:
                    return translate.y < 0
                default:
                    return false
                }
            }
            if panGesture == swipeLeftRightGesture {
                let translate = panGesture.translationInView(self.view)
                if presentingState == .StateMinimal {
                    return translate.x != 0
                }else{
                    return false
                }
            }
            
        }
        if let _ = gestureRecognizer as? UITapGestureRecognizer {
            return presentingState == .StateMinimal
        }
        
        return true
    }
}

//MARK: API
extension SYVideoPlayerController {
    public func presentIn(controller: UIViewController) {
        
        controller.addChildViewController(self)
        controller.view.addSubview(self.view)

        self.view.frame = CGRectMake(0, controller.view.bounds.size.height, controller.view.bounds.size.width, controller.view.bounds.size.height)
        UIView.animateWithDuration(0.3, animations: {
            self.view.frame = controller.view.bounds
        }, completion: nil)
        
        let orientation = UIApplication.sharedApplication().statusBarOrientation
        if UIInterfaceOrientationIsLandscape(orientation) {
            presentingState = .StateFullScreen
        }else{
            presentingState = .StateNormal
        }
        
    }
    
    public func dismissPlayer () {
        if (presentingState != .StateNormal) {
            
            UIView.animateWithDuration(0.3, animations: {
                    self.videoContainer.alpha = 0.0
                }, completion: { (completed) in
                    self.removeFromParentViewController()
                    self.view.removeFromSuperview()
                    
                    self.updateStatusBarFrame(0)
            })
        }else{
            
            UIView.animateWithDuration(0.3, animations: {
                self.view.frame = CGRectMake(0, self.parentViewController!.view.bounds.size.height, self.parentViewController!.view.bounds.size.width, self.parentViewController!.view.bounds.size.height)
                }, completion: { (completed) in
                    self.removeFromParentViewController()
                    self.view.removeFromSuperview()
                    
                    self.updateStatusBarFrame(0)
            })
        }
        
    }
    
    
    public func playVideo(videoUrl: NSURL) {
        if let player = moviePlayer {
            player.view.removeFromSuperview()
            moviePlayer = nil
        }
        
        let bundle = NSBundle.mainBundle()
        let config = MobilePlayerConfig(fileURL: bundle.URLForResource(
            "VideoStyle",
            withExtension: "json")!)
        
        moviePlayer = MobilePlayerViewController(contentURL: videoUrl, config: config)
        moviePlayer?.view.frame = videoContainer.bounds
        
        videoContainer.addSubview(moviePlayer!.view)
        moviePlayer?.play()
        
        addActionsFromMoviePlayer()
        updateContainerLayout(presentingState)
    }
    
    func addActionsFromMoviePlayer (){
        let buttonClose = moviePlayer?.getViewForElementWithIdentifier("close") as? UIButton
        buttonClose?.removeTarget(self, action: nil, forControlEvents: UIControlEvents.AllEvents)
        buttonClose?.addTarget(self, action: #selector(SYVideoPlayerController.dismissPlayer), forControlEvents: .TouchUpInside)
        
        let btnSize = moviePlayer?.getViewForElementWithIdentifier("size_control") as? UIButton
        btnSize?.removeTarget(self, action: nil, forControlEvents: UIControlEvents.AllEvents)
        btnSize?.addTarget(self, action: #selector(SYVideoPlayerController.showFullScreen), forControlEvents: .TouchUpInside)
    }
    
    public func showFullScreen () {
        if presentingState != .StateFullScreen {
            let value = UIInterfaceOrientation.LandscapeRight.rawValue
            UIDevice.currentDevice().setValue(value, forKey: "orientation")
        }else{
            let value = UIInterfaceOrientation.Portrait.rawValue
            UIDevice.currentDevice().setValue(value, forKey: "orientation")
        }
        
    }
    
    
}

class PassThroughView: UIView {
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        for subview in subviews as [UIView] {
            if !subview.hidden && subview.alpha > 0 && subview.userInteractionEnabled && subview.pointInside(convertPoint(point, toView: subview), withEvent: event) {
                return true
            }
        }
        return false
    }
}
