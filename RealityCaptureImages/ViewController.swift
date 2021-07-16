//
//  ViewController.swift
//  RealityCaptureImages
//
//  Created by sytz on 2021/7/6.
//

import UIKit
import AVFoundation
import CoreLocation
import Photos
import CoreBluetooth
import os

class ViewController: UIViewController {
    
    // MARK: Session Management
    
    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    
    private enum LivePhotoMode {
        case on
        case off
    }
    
    private enum DepthDataDeliveryMode {
        case on
        case off
    }
    
    private enum PortraitEffectsMatteDeliveryMode {
        case on
        case off
    }

    var captureImgName: String?
    var laseringImgName:String?
    var btnCapture: LeafButton!
    var imagesCounter = 0
    var isLasering = false
    var infoDict:NSMutableDictionary!
    
    @IBOutlet weak var previewView: PreviewView!
    @IBOutlet weak var btnPreView: UIButton!
    @IBOutlet weak var labImageNum: UILabel!
    @IBOutlet weak var btnLaserFlag: UIButton!
    @IBOutlet weak var pinLaserCenter: UIButton!
    
    private let photoOutput = AVCapturePhotoOutput()
    private var selectedSemanticSegmentationMatteTypes = [AVSemanticSegmentationMatte.MatteType]()

    private let session = AVCaptureSession()
    
    var windowOrientation: UIInterfaceOrientation {
        return view.window?.windowScene?.interfaceOrientation ?? .unknown
    }
    private var inProgressPhotoCaptureDelegates = [Int64: PhotoCaptureProcessor]()

    // Communicate with the session and other session objects on this queue.
    private let sessionQueue = DispatchQueue(label: "session queue")
    
    private var setupResult: SessionSetupResult = .success
    
    @objc dynamic var videoDeviceInput: AVCaptureDeviceInput!
    private var isSessionRunning = false

    let locationManager = CLLocationManager()
    
    private var livePhotoMode: LivePhotoMode = .off
    
    private var depthDataDeliveryMode: DepthDataDeliveryMode = .off
    private var portraitEffectsMatteDeliveryMode: PortraitEffectsMatteDeliveryMode = .off
    private var photoQualityPrioritizationMode: AVCapturePhotoOutput.QualityPrioritization = .balanced
    
    //core bluetooth part.
    var centralManager: CBCentralManager!
    var discoveredPeripheral: CBPeripheral?
    var transferCharacteristic: CBCharacteristic?
    let serviceUUID = CBUUID(string: "0000FFF0-0000-1000-8000-00805F9B34FB")
    let characteristicUUID = CBUUID(string: "0000FFF2-0000-1000-8000-00805F9B34FB")
    let characteristicUUID_Notify = CBUUID(string: "0000FFF1-0000-1000-8000-00805F9B34FB")
    var writeIterationsComplete = 0
    var connectionIterationsComplete = 0
    let defaultIterations = 5     // change this value based on test usecase

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // Set up the video preview view.
        previewView.session = session
        
        // Request location authorization so photos and videos can be tagged with their location.
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        
        /*
         Check the video authorization status. Video access is required and audio
         access is optional. If the user denies audio access, AVCam won't
         record audio during movie recording.
         */
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // The user has previously granted access to the camera.
            break
            
        case .notDetermined:
            /*
             The user has not yet been presented with the option to grant
             video access. Suspend the session queue to delay session
             setup until the access request has completed.
             
             Note that audio access will be implicitly requested when we
             create an AVCaptureDeviceInput for audio during session setup.
             */
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if !granted {
                    self.setupResult = .notAuthorized
                }
                self.sessionQueue.resume()
            })
            
        default:
            // The user has previously denied access.
            setupResult = .notAuthorized
        }
        
        /*
         Setup the capture session.
         In general, it's not safe to mutate an AVCaptureSession or any of its
         inputs, outputs, or connections from multiple threads at the same time.
         
         Don't perform these tasks on the main queue because
         AVCaptureSession.startRunning() is a blocking call, which can
         take a long time. Dispatch session setup to the sessionQueue, so
         that the main queue isn't blocked, which keeps the UI responsive.
         */
        sessionQueue.async {
            self.configureSession()
        }
        
        DispatchQueue.main.async {
            self.btnCapture = LeafButton.init(frame: CGRect.init(origin: CGPoint.zero, size: CGSize.init(width: 80, height: 80)))
            self.btnCapture.center = CGPoint.init(x: self.view.frame.size.width - 75, y: self.view.frame.size.height/2);
            self.btnCapture.type = .init(LeafButtonTypeCamera.rawValue)
            self.btnCapture.clickedBlock = { [unowned self](btn) in
                self.captureSession()
            }
            self.view.addSubview(self.btnCapture);
        }
        
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
        
        
        
        let dictPath = NSHomeDirectory() + "/Documents/infoDict.plist"
        if FileManager.default.fileExists(atPath: dictPath) {
            infoDict = NSMutableDictionary.init(contentsOfFile: dictPath)
        }
        else {
            infoDict = NSMutableDictionary.init()
        }
    }
    
    
    // Call this on the session queue.
    /// - Tag: ConfigureSession
    private func configureSession() {
        if setupResult != .success {
            return
        }
        
        session.beginConfiguration()
        
        /*
         Do not create an AVCaptureMovieFileOutput when setting up the session because
         Live Photo is not supported when AVCaptureMovieFileOutput is added to the session.
         */
        session.sessionPreset = .photo
        
        // Add video input.
        do {
            var defaultVideoDevice: AVCaptureDevice?
            
            // Choose the back dual camera, if available, otherwise default to a wide angle camera.
            
            if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
                defaultVideoDevice = dualCameraDevice
            } else if let dualWideCameraDevice = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) {
                // If a rear dual camera is not available, default to the rear dual wide camera.
                defaultVideoDevice = dualWideCameraDevice
            } else if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                // If a rear dual wide camera is not available, default to the rear wide angle camera.
                defaultVideoDevice = backCameraDevice
            } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                // If the rear wide angle camera isn't available, default to the front wide angle camera.
                defaultVideoDevice = frontCameraDevice
            }
            guard let videoDevice = defaultVideoDevice else {
                print("Default video device is unavailable.")
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
                DispatchQueue.main.async {
                    /*
                     Dispatch video streaming to the main queue because AVCaptureVideoPreviewLayer is the backing layer for PreviewView.
                     You can manipulate UIView only on the main thread.
                     Note: As an exception to the above rule, it's not necessary to serialize video orientation changes
                     on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
                     
                     Use the window scene's orientation as the initial video orientation. Subsequent orientation changes are
                     handled by CameraViewController.viewWillTransition(to:with:).
                     */
                    var initialVideoOrientation: AVCaptureVideoOrientation = .landscapeRight
                    if self.windowOrientation != .unknown {
                        if let videoOrientation = AVCaptureVideoOrientation(rawValue: self.windowOrientation.rawValue) {
                            initialVideoOrientation = videoOrientation
                        }
                    }
                    
                    self.previewView.videoPreviewLayer.connection?.videoOrientation = initialVideoOrientation
                }
            } else {
                print("Couldn't add video device input to the session.")
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
        } catch {
            print("Couldn't create video device input: \(error)")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        // Add an audio input device.
        do {
            let audioDevice = AVCaptureDevice.default(for: .audio)
            let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice!)
            
            if session.canAddInput(audioDeviceInput) {
                session.addInput(audioDeviceInput)
            } else {
                print("Could not add audio device input to the session")
            }
        } catch {
            print("Could not create audio device input: \(error)")
        }
        
        // Add the photo output.
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            
            photoOutput.isHighResolutionCaptureEnabled = true
            photoOutput.isLivePhotoCaptureEnabled = photoOutput.isLivePhotoCaptureSupported
            photoOutput.isDepthDataDeliveryEnabled = photoOutput.isDepthDataDeliverySupported
            photoOutput.isPortraitEffectsMatteDeliveryEnabled = photoOutput.isPortraitEffectsMatteDeliverySupported
            photoOutput.enabledSemanticSegmentationMatteTypes = photoOutput.availableSemanticSegmentationMatteTypes
            selectedSemanticSegmentationMatteTypes = photoOutput.availableSemanticSegmentationMatteTypes
            photoOutput.maxPhotoQualityPrioritization = .quality
            livePhotoMode = photoOutput.isLivePhotoCaptureSupported ? .on : .off
            depthDataDeliveryMode = photoOutput.isDepthDataDeliverySupported ? .on : .off
            portraitEffectsMatteDeliveryMode = photoOutput.isPortraitEffectsMatteDeliverySupported ? .on : .off
            photoQualityPrioritizationMode = .quality
            
        } else {
            print("Could not add photo output to the session")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        session.commitConfiguration()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        sessionQueue.async {
            switch self.setupResult {
            case .success:
                self.session.startRunning()
                self.isSessionRunning = self.session.isRunning
                
            case .notAuthorized:
                DispatchQueue.main.async {
                    let changePrivacySetting = "AVCam doesn't have permission to use the camera, please change privacy settings"
                    let message = NSLocalizedString(changePrivacySetting, comment: "Alert message when the user has denied access to the camera")
                    let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
                    
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                            style: .cancel,
                                                            handler: nil))
                    
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("Settings", comment: "Alert button to open Settings"),
                                                            style: .`default`,
                                                            handler: { _ in
                                                                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
                                                                                          options: [:],
                                                                                          completionHandler: nil)
                    }))
                    
                    self.present(alertController, animated: true, completion: nil)
                }
                
            case .configurationFailed:
                DispatchQueue.main.async {
                    let alertMsg = "Alert message when something goes wrong during capture session configuration"
                    let message = NSLocalizedString("Unable to capture media", comment: alertMsg)
                    let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
                    
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                            style: .cancel,
                                                            handler: nil))
                    
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
        
        if let names = try? FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Documents/Thumb/") {
            self.imagesCounter = names.filter({
                $0.contains(".jpg")
            }).count
            
            if self.imagesCounter > 0 {
                let imagePath = generateFilePath(names[self.imagesCounter - 1], "Thumb")!
                let image = UIImage.init(contentsOfFile: imagePath)!
                self.refreshPreImgWnd(image.reSizeImage(reSize: CGSize.init(width: 50, height: 50)))
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        sessionQueue.async {
            if self.setupResult == .success {
                self.session.stopRunning()
                self.isSessionRunning = self.session.isRunning
            }
        }
        
        // Don't keep it going while we're not showing.
        centralManager.stopScan()
        os_log("Scanning stopped")
        
        super.viewWillDisappear(animated)
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if let videoPreviewLayerConnection = previewView.videoPreviewLayer.connection {
            let deviceOrientation = UIDevice.current.orientation
            guard let newVideoOrientation = AVCaptureVideoOrientation(rawValue: deviceOrientation.rawValue),
                deviceOrientation.isPortrait || deviceOrientation.isLandscape else {
                    return
            }
            
            videoPreviewLayerConnection.videoOrientation = newVideoOrientation
        }
    }
    
    func getCurrentTime() -> String {
        let now = Date()
         
        // 创建一个日期格式器
        let dformatter = DateFormatter()
        dformatter.dateFormat = "yyyy_MM_dd_HH_mm_ss_SSS"

        return dformatter.string(from: now)
    }
    
    @IBAction func doLaserDist(_ sender: UIButton) {
        if !self.isLasering {
            sender.setImage(UIImage.init(systemName: "flag"), for: .normal)
            sender.tintColor = UIColor.red
            applyCommand(cmd: .turnon)
            self.pinLaserCenter.isHidden = false
        }
        else {
            sender.setImage(UIImage.init(systemName: "flag.slash"), for: .normal)
            sender.tintColor = UIColor.black
            applyCommand(cmd: .turnoff)
            self.pinLaserCenter.isHidden = true
        }
        
        self.isLasering = !self.isLasering
    }
    @IBAction func focusAndExposeTap(_ gestureRecognizer: UITapGestureRecognizer) {
        let devicePoint = previewView.videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: gestureRecognizer.location(in: gestureRecognizer.view))
        focus(with: .autoFocus, exposureMode: .autoExpose, at: devicePoint, monitorSubjectAreaChange: true)
    }
    
    private func focus(with focusMode: AVCaptureDevice.FocusMode,
                       exposureMode: AVCaptureDevice.ExposureMode,
                       at devicePoint: CGPoint,
                       monitorSubjectAreaChange: Bool) {
        
        sessionQueue.async {
            let device = self.videoDeviceInput.device
            do {
                try device.lockForConfiguration()
                
                /*
                 Setting (focus/exposure)PointOfInterest alone does not initiate a (focus/exposure) operation.
                 Call set(Focus/Exposure)Mode() to apply the new point of interest.
                 */
                if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode) {
                    device.focusPointOfInterest = devicePoint
                    device.focusMode = focusMode
                }
                
                if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) {
                    device.exposurePointOfInterest = devicePoint
                    device.exposureMode = exposureMode
                }
                
                device.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                device.unlockForConfiguration()
            } catch {
                print("Could not lock device for configuration: \(error)")
            }
        }
    }
    
    func captureSession() {
        /*
         Retrieve the video preview layer's video orientation on the main queue before
         entering the session queue. Do this to ensure that UI elements are accessed on
         the main thread and session configuration is done on the session queue.
         */
        let videoPreviewLayerOrientation = previewView.videoPreviewLayer.connection?.videoOrientation
        
        sessionQueue.async {
            if let photoOutputConnection = self.photoOutput.connection(with: .video) {
                photoOutputConnection.videoOrientation = videoPreviewLayerOrientation!
            }
            var photoSettings = AVCapturePhotoSettings()
            
            // Capture HEIF photos when supported. Enable auto-flash and high-resolution photos.
            photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
            
            if self.videoDeviceInput.device.isFlashAvailable {
                photoSettings.flashMode = .auto
            }
            
            photoSettings.isHighResolutionPhotoEnabled = true
            if let previewPhotoPixelFormatType = photoSettings.availablePreviewPhotoPixelFormatTypes.first {
                photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPhotoPixelFormatType]
            }
            
            photoSettings.isPortraitEffectsMatteDeliveryEnabled = (self.portraitEffectsMatteDeliveryMode == .on
                && self.photoOutput.isPortraitEffectsMatteDeliveryEnabled)
            
            photoSettings.photoQualityPrioritization = self.photoQualityPrioritizationMode
            
            self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
        }
        
        //获取当前时间

        self.captureImgName = self.getCurrentTime()
                
        if self.isLasering {
            //设置读取距离时的按钮状态:提示按钮变图标，瞄准框隐藏
            self.isLasering = false
            pinLaserCenter.isHidden = true
            btnLaserFlag.setImage(UIImage.init(systemName: "flag.fill"), for: .normal)
            btnLaserFlag.isEnabled = false
            btnPreView.isEnabled = false

            self.laseringImgName = self.captureImgName
            applyCommand(cmd: .measure)
        }
    }
    
    func updateCaseInfoIfNeeds() {
        if infoDict.object(forKey: "preview") != nil {
            return
        }
        
        infoDict.setValue( self.captureImgName, forKey: "preview")
        infoDict.write(toFile: NSHomeDirectory() + "/Documents/infoDict.plist", atomically: true)
    }
    
    func updateLaserDataIfNeeds(_ dist:String?) {
        guard let imgName = self.laseringImgName else { return }
        
        guard let dist = dist else {
            self.laseringImgName = nil
            btnLaserFlag.setImage(UIImage.init(systemName: "flag.slash"), for: .normal)
            btnLaserFlag.tintColor = UIColor.black
            btnLaserFlag.isEnabled = true
            let alertController = UIAlertController(title: "警告", message: "获取激光距离失败，请重试!", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            present(alertController, animated: true, completion: nil)
            return
        }
        
        var arr = infoDict.object(forKey: "arr") as? NSMutableArray
        if arr == nil {
            arr = NSMutableArray.init()
            infoDict.setValue(arr, forKey: "arr")
        }
        
        let obj = NSMutableDictionary.init()
        obj.setValue(imgName, forKey: "imgName")
        obj.setValue(dist, forKey: "dist")
        
        arr!.add(obj)
        
        infoDict.write(toFile: NSHomeDirectory() + "/Documents/infoDict.plist", atomically: true)

        self.laseringImgName = nil
        btnLaserFlag.setImage(UIImage.init(systemName: "flag.slash"), for: .normal)
        btnLaserFlag.tintColor = UIColor.black
        btnLaserFlag.isEnabled = true
        btnPreView.isEnabled = true
    }

    @IBAction func btnPreViewAction(_ sender: Any) {
        if self.imagesCounter < 4 {
            let alertController = UIAlertController(title: "警告", message: "照片数量不能低于4张!", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            present(alertController, animated: true, completion: nil)
            return
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier:"PreView")
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true, completion: nil)
    }
    
    func refreshPreImgWnd(_ img:UIImage) {
        self.btnPreView.isHidden = false
        self.btnPreView.setImage(img, for: .normal)
        self.labImageNum.isHidden = false
        self.labImageNum.text = String.init(format: "共%d张", self.imagesCounter)
    }
}

extension ViewController: AVCapturePhotoCaptureDelegate {
    /// - Tag: WillCapturePhoto
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        self.previewView.videoPreviewLayer.opacity = 0
        UIView.animate(withDuration: 0.25) {
            self.previewView.videoPreviewLayer.opacity = 1
        }
    }
    
    /// - Tag: DidFinishProcessingPhoto
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error)")
            return
        }
        
        guard let imgTime = self.captureImgName, let data = photo.fileDataRepresentation(), let image =  UIImage(data: data)  else {
            return
        }
        
        self.imagesCounter += 1

        let imgName = imgTime + ".jpg"
        try? image.jpegData(compressionQuality: 1)?.write(to: URL.init(fileURLWithPath: generateFilePath(imgName, "Cache")))
        
        DispatchQueue.main.async {
            self.refreshPreImgWnd(image.reSizeImage(reSize: CGSize.init(width: 50, height: 50)))
        }
        
        try? image.reSizeImage(reSize: CGSize.init(width: 140, height: 105)).jpegData(compressionQuality: 0.1)?.write(to: URL.init(fileURLWithPath: generateFilePath(imgName, "Thumb")))
                
        updateCaseInfoIfNeeds()
    
        self.captureImgName = nil;
    }
}

extension UIImage {
    /**
     *  重设图片大小
     */
    func reSizeImage(reSize:CGSize)->UIImage {
        UIGraphicsBeginImageContextWithOptions(reSize, false, UIScreen.main.scale);
        self.draw(in: CGRect.init(x: 0, y: 0, width: reSize.width, height: reSize.height))
        let reSizeImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext();
        return reSizeImage;
    }
     
    /**
     *  等比率缩放
     */
    func scaleImage(scaleSize:CGFloat)->UIImage {
        let reSize = CGSize.init(width: self.size.width * scaleSize, height: self.size.height * scaleSize)
        return reSizeImage(reSize: reSize)
    }
}
