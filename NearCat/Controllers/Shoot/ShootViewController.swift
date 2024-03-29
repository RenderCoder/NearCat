//
//  ShootViewController.swift
//  NearCat
//
//  Created by huchunbo on 16/1/9.
//  Copyright © 2016年 Bijiabo. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import ImageIO
import CoreGraphics
import Photos

class ShootViewController: UIViewController {
    
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var panelView: UIView!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var switchCameraButton: UIButton!
    @IBOutlet weak var takePhotoButton: UIButton!
    @IBOutlet weak var previewViewHeight: NSLayoutConstraint!
    @IBOutlet weak var galleryButton: UIButton!
    
    var session: AVCaptureSession!
    var savePath: String = String()
    var selectedImages: [UIImage] = [UIImage]()
    var delegate: MediaPickerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: UIStatusBarAnimation.Fade)
        
        previewViewHeight.constant = view.frame.width
        
        savePath = NSHomeDirectory().stringByAppendingString("/Documents")
        
        setupViews()
        addCaptrueObservers()
        addTapGestureRecognizerToPreview()
    }
    
    deinit {
        removeCaptureObservers()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        setupCaptureSession()
        setupPreview()
        updateGalleryPreviewPhoto()
        
        // check devices
        //checkDevices(devices)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.Fade)
    }
    
    private func setupViews() {
//        let captrueButtonLayer = captureButton.layer
//        captrueButtonLayer.cornerRadius = captrueButtonLayer.frame.size.width/2.0
    }
    
    private func setupCaptureSession() {
        session = AVCaptureSession()
        
        // configuring session
        session.beginConfiguration()
        
        if session.canSetSessionPreset(AVCaptureSessionPresetHigh) {
            session.sessionPreset = AVCaptureSessionPresetMedium
        } else {
            // Handle the failure.
            print("Device does not support set AVCaptureSession preset to be AVCaptureSessionPresetLow")
        }
        
        // add inputs
        var cameraInput: AVCaptureDeviceInput?
        if let camera = camera_back {
            if let input = try? AVCaptureDeviceInput(device: camera) {
                cameraInput = input
                currentCameraDevice = camera
            }
        } else if let camera = camera_font {
            if let input = try? AVCaptureDeviceInput(device: camera) {
                cameraInput = input
                currentCameraDevice = camera
            }
        }
        
        if let cameraInput = cameraInput {
            session.addInput(cameraInput)
        }
        
        // add outputs
        // add movie output
        let movieOutput: AVCaptureMovieFileOutput = AVCaptureMovieFileOutput()
        let maxDuration: CMTime = CMTimeMake(1000*15, 1000)
        movieOutput.maxRecordedDuration = maxDuration
        if session.canAddOutput(movieOutput) {
            session.addOutput(movieOutput)
        } else {
            print("capture session does not support add AVCaptureMoviceFileOutput.")
        }
        // add still image output
        let stillImageOutput: AVCaptureStillImageOutput = AVCaptureStillImageOutput()
        let outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
        stillImageOutput.outputSettings = outputSettings
        if session.canAddOutput(stillImageOutput) {
            session.addOutput(stillImageOutput)
        } else {
            print("capture session does not support add AVCaptureStillImageOutput.")
        }
        
        session.commitConfiguration()
        
        // start data flow by sending the session a startRunning message
        session.startRunning()
    }
    
    var capturePreviewLayer: AVCaptureVideoPreviewLayer!
    private func setupPreview() {
        previewViewHeight.constant = previewView.frame.size.width
        
        capturePreviewLayer = AVCaptureVideoPreviewLayer(session: session)
        capturePreviewLayer.frame = view.bounds
        capturePreviewLayer.frame.origin.y =  -(capturePreviewLayer.frame.height - previewViewHeight.constant)/2.0
        previewView.layer.addSublayer(capturePreviewLayer)
        previewView.clipsToBounds = true
    }
    
    private func _fadeInPreviewView() {
        let opacityAnim: CABasicAnimation = CABasicAnimation(keyPath: "alpha")
        opacityAnim.fromValue = 0
        opacityAnim.toValue = 1
        opacityAnim.removedOnCompletion = true
        let animGroup: CAAnimationGroup = CAAnimationGroup()
        animGroup.animations = [opacityAnim]
        animGroup.duration = 1
        capturePreviewLayer.addAnimation(animGroup, forKey: nil)
    }
    
    // MARK: - session observers
    private func addCaptrueObservers() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        // capture session observers
        notificationCenter.addObserver(
            self,
            selector: Selector("captureSessionRunTimeError:"),
            name: AVCaptureSessionRuntimeErrorNotification,
            object: nil)
        notificationCenter.addObserver(
            self,
            selector: Selector("captureSessionInterrupted:"),
            name: AVCaptureSessionWasInterruptedNotification,
            object: nil)
        // capture device observers
        notificationCenter.addObserver(
            self,
            selector: Selector("captureDeviceWasConnected:"),
            name: AVCaptureDeviceWasConnectedNotification,
            object: nil)
        notificationCenter.addObserver(
            self,
            selector: Selector("captureDeviceWasDisConnected:"),
            name: AVCaptureDeviceWasDisconnectedNotification,
            object: nil)
    }
    
    private func removeCaptureObservers() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        
        func removeObserverByName(name: String) {
            notificationCenter.removeObserver(self, name: name, object: nil)
        }
        func removeObserverByNames(names: [String]) {
            for name in names {
                removeObserverByName(name)
            }
        }
        
        // capture session observers
        removeObserverByNames([
            AVCaptureSessionRuntimeErrorNotification,
            AVCaptureSessionWasInterruptedNotification
            ])
        // capture device observers
        removeObserverByNames([
            AVCaptureDeviceWasConnectedNotification,
            AVCaptureDeviceWasDisconnectedNotification
            ])
    }
    
    func captureSessionRunTimeError(notification: NSNotification) {
        
    }
    
    func captureSessionInterrupted(notification: NSNotification) {
        
    }
    
    func captureDeviceWasConnected(notification: NSNotification) {
        
    }
    
    func captureDeviceWasDisConnected(notification: NSNotification) {
        
    }
    
    // MARK: - device functions
    var devices: [AnyObject]! {
        return AVCaptureDevice.devices()
    }
    
    var cameraDevices: [AVCaptureDevice] {
        guard let deivceList = devices as? [AVCaptureDevice] else {return [AVCaptureDevice]()}
        
        var cameras = [AVCaptureDevice]()
        
        for device in deivceList {
            if device.hasMediaType(AVMediaTypeVideo) {
                cameras.append(device)
            }
        }
        return cameras
    }
    
    var currentCameraDevice: AVCaptureDevice?
    
    func checkDevices(devices: [AnyObject]) {
        guard let deivceList = devices as? [AVCaptureDevice] else {return}
        
        for device in deivceList {
            print("\nDevice name: \(device.localizedName)")
            print("modelID: \(device.modelID)")
            print("uniqueID: \(device.uniqueID)")
            
            if device.hasMediaType(AVMediaTypeVideo) {
                // show if has torch
                if device.hasTorch {
                    print("has torch")
                } else {
                    print("don't has torch")
                }
                
                // show position
                if device.position == AVCaptureDevicePosition.Back {
                    print("Device position : back")
                } else {
                    print("Device position : front")
                }
            } else if device.hasMediaType(AVMediaTypeAudio) {
                print(device.localizedName)
            }
        }
    }
    
    
    var camera_back: AVCaptureDevice? {
        return cameraByPosition(AVCaptureDevicePosition.Back)
    }
    var camera_font: AVCaptureDevice? {
        return cameraByPosition(AVCaptureDevicePosition.Front)
    }
    
    private func cameraByPosition(position: AVCaptureDevicePosition) -> AVCaptureDevice? {
        guard let deivceList = devices as? [AVCaptureDevice] else {return nil}
        
        for device in deivceList {
            if device.hasMediaType(AVMediaTypeVideo) {
                if device.position == position {
                    return device
                }
            }
        }
        return nil
    }
    
    // MARK: - user actions
    private func addTapGestureRecognizerToPreview() {
        let tapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: Selector("userTappedPreview:")
        )
        previewView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    func userTappedPreview(gesture: UITapGestureRecognizer) {
        guard let gestureView = gesture.view else {return}
        
        let locationInView = gesture.locationInView(gestureView)
        let focusPoint: CGPoint = CGPoint(
            x: locationInView.x/gestureView.frame.size.width , y:
            locationInView.y/gestureView.frame.size.width
        )
        setDeviceFocusPoint(pointInPercentage: focusPoint, pointInCGFlot: locationInView)
    }
    
    @IBAction func tapGalleryButton(sender: AnyObject) {
        if Helper.Ability.Photo.hasAuthorization {
            let mediaPickerNavigationVC = Helper.Controller.MediaPicker
            mediaPickerNavigationVC.mediaPickerDelegate = self
            self.presentViewController(mediaPickerNavigationVC, animated: true, completion: nil)
        } else {
            Helper.Ability.Photo.requestAuthorization(block: { (success) -> Void in
                if success {
                    let mediaPickerNavigationVC = Helper.Controller.MediaPicker
                    self.presentViewController(mediaPickerNavigationVC, animated: true, completion: nil)
                } else {
                    Helper.Alert.show(title: "未开启照片访问权限", message: "请打开［设置］-> ［猫邻］-> ［照片］选择开启", animated: true)
                }
            })
        }
    }
    
    
    private func setDeviceFocusPoint(pointInPercentage pointInPercentage: CGPoint, pointInCGFlot: CGPoint) {
        guard let currentDevice = currentCameraDevice else {return}
        
        if currentDevice.focusPointOfInterestSupported == true {
            do {
                try currentDevice.lockForConfiguration()
                currentDevice.focusPointOfInterest = pointInPercentage
                currentDevice.focusMode = AVCaptureFocusMode.ContinuousAutoFocus
                currentDevice.unlockForConfiguration()
            } catch {
                return
            }
            // remove previous focus vision tipc
            previewView.viewWithTag(2048)?.removeFromSuperview()
            // add focus vision tip
            let visionTipViewWidth_half: CGFloat = 60.0/2.0
            let visionTipView: UIView = UIView(frame:
                CGRect(
                    x: pointInCGFlot.x-visionTipViewWidth_half,
                    y: pointInCGFlot.y-visionTipViewWidth_half,
                    width: visionTipViewWidth_half*2.0,
                    height: visionTipViewWidth_half*2.0
                )
            )
            visionTipView.tag = 2048
            // setup visionTipView's style
            visionTipView.backgroundColor = UIColor.clearColor()
            visionTipView.layer.borderColor = UIColor(red:0.2, green:0.66, blue:0.9, alpha:1).CGColor
            visionTipView.layer.borderWidth = 1.0
            visionTipView.alpha = 0
            // disable user tap visionTipView
            visionTipView.userInteractionEnabled = false
            previewView.addSubview(visionTipView)
            // setup visionTipView's animation
            UIView.animateWithDuration(0.5,
                animations: { () -> Void in
                    visionTipView.alpha = 1.0
                },
                completion: { (finished) -> Void in
                    if finished {
                        UIView.animateWithDuration(0.5,
                            animations: { () -> Void in
                                visionTipView.alpha = 0
                            },
                            completion: { (finished) -> Void in
                                if finished {
                                    visionTipView.removeFromSuperview()
                                }
                        })
                    }
                }
            )
        }
    }
    
    @IBAction func tapSwitchCameraButton(sender: AnyObject) {
        if cameraDevices.count < 2 {return}
        
        var previousCameraInput: AVCaptureDeviceInput?
        
        for input in session.inputs {
            guard let input = input as? AVCaptureDeviceInput else {continue}
            if input.device == currentCameraDevice {
                previousCameraInput = input
                break
            }
        }
        
        for camera in cameraDevices {
            if currentCameraDevice != camera {
                if let newInput = try? AVCaptureDeviceInput(device: camera)
                {
                    session.beginConfiguration()
                    
                    if let previousCameraInput = previousCameraInput {
                        session.removeInput(previousCameraInput)
                    }
                    
                    if session.canAddInput(newInput) {
                        session.addInput(newInput)
                        currentCameraDevice = camera
                    } else {
                        session.addInput(previousCameraInput)
                    }
                    
                    session.commitConfiguration()
                    break
                }
            }
        }
    }
    
    var currentMovieOutput: AVCaptureMovieFileOutput? {
        for output in session.outputs {
            if let output = output as? AVCaptureMovieFileOutput {
                return output
            }
        }
        return nil
    }
    
    var currentStillImageOutput: AVCaptureStillImageOutput? {
        for output in session.outputs {
            if let output = output as? AVCaptureStillImageOutput {
                return output
            }
        }
        return nil
    }
    
    private var recording: Bool = false
    /*
    @IBAction func tapCaptureButton(sender: AnyObject) {
        let saveFileURL: NSURL = NSURL(fileURLWithPath: savePath).URLByAppendingPathComponent("\(currentShortDate()).mp4")
        
        struct buttonColor {
            static let normal: UIColor = UIColor(red:0.21, green:0.67, blue:0.91, alpha:1)
            static let active: UIColor = UIColor(red:0.97, green:0.34, blue:0.24, alpha:1)
        }
        
        guard let moviewOutput = currentMovieOutput else {return}
        
        if !recording {
            moviewOutput.startRecordingToOutputFileURL(saveFileURL, recordingDelegate: self)
            captureButton.backgroundColor = buttonColor.active
        } else {
            moviewOutput.stopRecording()
            captureButton.backgroundColor = buttonColor.normal
        }
        
        recording = !recording
    }
    */
    @IBAction func tapTakePhotoButton(sender: AnyObject) {
        guard let stillImageOutput = currentStillImageOutput else {return} //TODO: tip user error
        var videoConnection: AVCaptureConnection? = nil
        for connection in stillImageOutput.connections as! [AVCaptureConnection] {
            for port in connection.inputPorts as! [AVCaptureInputPort] {
                if port.mediaType == AVMediaTypeVideo {
                    videoConnection = connection
                    break
                }
            }
            if videoConnection != nil {break}
        }
        
        stillImageOutput.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler: {
            (imageSampleBuffer: CMSampleBuffer!, error: NSError!) -> Void in
            
            var image = UIImage(data: AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageSampleBuffer))!
            
            //crop photo to square
            let size = image.size
            let hasAlpha = false
            let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
            let targetWidthSize: CGFloat = size.width < size.height ? size.width : size.height
            let targetSize = CGSize(width: targetWidthSize, height: targetWidthSize)
            UIGraphicsBeginImageContextWithOptions(targetSize, !hasAlpha, scale)
            let drawOrigin = CGPoint(x: 0, y: -abs(size.height - size.width)/2.0)
            image.drawInRect(CGRect(origin: drawOrigin, size: size))
            
            image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            // save image to user's photo album
            UIImageWriteToSavedPhotosAlbum(image, self, Selector("savePhotoToAlbumComplete:didFinishSavingWithError:contextInfo:"), nil)
            
            // add photo to selected image array
            self.selectedImages.append(image)
            
            let cropVC = ALConfirmViewController(image: image, allowsCropping: true)
            cropVC.onComplete = { (image) in
                guard let image = image else {
                    self.navigationController?.popToViewController(self, animated: true)
                    return
                }
                
                self.delegate?.newImage(image, fromMediaPicker: self)
            }
            
            self.navigationController?.pushViewController(cropVC, animated: true)
            
        })
    }
    
    func savePhotoToAlbumComplete(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: AnyObject) {
        galleryButton.setBackgroundImage(image, forState: UIControlState.Normal)
    }
    
    @IBAction func tapCloseButton(sender: AnyObject) {
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    // MARK: - date function
    
    func currentShortDate() -> String {
        let todaysDate = NSDate()
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy_HH-mm-ss"
        let DateInFormat = dateFormatter.stringFromDate(todaysDate)
        
        return DateInFormat
    }
}

extension ShootViewController: AVCaptureFileOutputRecordingDelegate {
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAtURL fileURL: NSURL!, fromConnections connections: [AnyObject]!) {
        
    }
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        
        var recordedSuccessfully: Bool = true
        
        if let error = error {
            if Int32(error.code) != noErr {
                // A problem occurred: Find out if the recording was successful.
                if let value = error.userInfo[AVErrorRecordingSuccessfullyFinishedKey] {
                    if let value_boolValue = value.boolValue {
                        recordedSuccessfully = value_boolValue
                    }
                }
            }
        }
        
        if !recordedSuccessfully {
            print("record unsuccessful.")
        } else {
            saveMovieWithUrl(outputFileURL)
        }
    }
    
    func saveMovieWithUrl(url: NSURL) {
        
        PHPhotoLibrary.sharedPhotoLibrary().performChanges({ () -> Void in
            // let createAssetRequest: PHAssetChangeRequest = PHAssetChangeRequest.creationRequestForAssetFromVideoAtFileURL(url)!
            // let placeholder = createAssetRequest.placeholderForCreatedAsset!
            
            }) { (success, error) -> Void in
                if success {
                    print("success")
                } else {
                    print(error)
                }
        }
    }
}

// MARK: - load gallery photo
extension ShootViewController {
    
    func updateGalleryPreviewPhoto() {
        
        let workingQueue = dispatch_queue_create("nc_queue", nil)
        
        dispatch_async(workingQueue) { () -> Void in
            let userAlbumsOptions: PHFetchOptions = PHFetchOptions()
            userAlbumsOptions.predicate = NSPredicate(format: "estimatedAssetCount > 0", argumentArray: nil)
            
            var endDate: NSDate?
            var latestAsset: PHAsset?
            
            let userAlbums: PHFetchResult = PHAssetCollection.fetchAssetCollectionsWithType(PHAssetCollectionType.Moment, subtype: PHAssetCollectionSubtype.AlbumMyPhotoStream, options: userAlbumsOptions)
            userAlbums.enumerateObjectsUsingBlock { (collection, index, stop) -> Void in
                
                let assetsFetchResult: PHFetchResult = PHAsset.fetchAssetsInAssetCollection(collection as! PHAssetCollection, options: nil)
                
                let asset: PHAsset = assetsFetchResult.lastObject as! PHAsset
                
                if endDate == nil {
                    endDate = asset.creationDate
                    latestAsset = asset
                } else {
                    if asset.creationDate > endDate {
                        endDate = asset.creationDate
                        latestAsset = asset
                    }
                }
            }
            
            if latestAsset != nil {
                let targetSize = CGSize(width: 120.0, height: 120.0)
                PHImageManager.defaultManager().requestImageForAsset(latestAsset!, targetSize: targetSize, contentMode: PHImageContentMode.AspectFill, options: nil, resultHandler: { (image, info: [NSObject : AnyObject]?) -> Void in
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.galleryButton.setBackgroundImage(image, forState: UIControlState.Normal)
                    })
                    
                })
            }
        }
    }
    
}

// MARK: - navigator
extension ShootViewController {
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let segueIdentifier = segue.identifier else {return}
        switch segueIdentifier {
        case "linkToPostEditor":
            guard let targetVC = segue.destinationViewController as? PostEditorTableViewController else {return}
            if !selectedImages.isEmpty {
                targetVC.previewImage = selectedImages.last!
                targetVC.selectedImages = selectedImages
            }
            
        default:
            break
        }
    }
    
}

// MARK: - extension: MediaPickerDelegate

extension ShootViewController: MediaPickerDelegate {
    
    func newImage(image: UIImage, fromMediaPicker: UIViewController) {
        self.selectedImages.append(image)
        
        let vc = storyboard?.instantiateViewControllerWithIdentifier("PostEditorTableViewController") as! PostEditorTableViewController
        if !selectedImages.isEmpty {
            vc.previewImage = selectedImages.last!
            vc.selectedImages = selectedImages
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
}
