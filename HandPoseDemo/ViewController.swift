//
//  ViewController.swift
//  HandPoseDemo
//
//  Created by Wei-Cheng Ling on 2020/12/12.
//

import Cocoa
import Vision
import AVFoundation


class ViewController: NSViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet var previewView : NSView!
    @IBOutlet var videoMirrorSwitch : NSSwitch!
    @IBOutlet var videoMirrorLabel : NSTextField!
    @IBOutlet var camerasPopUpButton : NSPopUpButton!
    @IBOutlet var numberOfHandsPopUpButton : NSPopUpButton!
    @IBOutlet var numberLabel : NSTextField!
    
    
    var hasCameraDevice = false
    var cameraDevices : [AVCaptureDevice]!
    var currentCameraDevice : AVCaptureDevice!
    var previewLayer : AVCaptureVideoPreviewLayer!
    var videoSession : AVCaptureSession!
    
    var jointLayers = [CAShapeLayer]()
    
    var indexFingerJointPoints = [VNHumanHandPoseObservation.JointName : CGPoint]()
    var littleFingerJointPoints = [VNHumanHandPoseObservation.JointName : CGPoint]()
    var middleFingerJointPoints = [VNHumanHandPoseObservation.JointName : CGPoint]()
    var ringFingerJointPoints = [VNHumanHandPoseObservation.JointName : CGPoint]()
    var thumbJointPoints = [VNHumanHandPoseObservation.JointName : CGPoint]()

    var numberOfHands = 1
    var handPoseNumberArray = [Int?]()
    
    
    // MARK: - viewLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // hide videoMirrorComponents
        hideVideoMirrorComponents()
        
        // setup numberLabel
        setupNumberLabel()
        
        // setup numberOfHandsPopUpButton
        setupNumberOfHandsPopUpButton()
        
        // setup Camera
        cameraDevices = getCameraDevices()
        setupCamerasPopUpButton()
        setupDefaultCamera()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    
    // MARK: - Setup
    
    func hideVideoMirrorComponents() {
        videoMirrorSwitch.state = .off
        videoMirrorSwitch.isHidden = true
        videoMirrorLabel.isHidden = true
    }
    
    func setupCamerasPopUpButton() {
        camerasPopUpButton.removeAllItems()
        
        if cameraDevices.count <= 0 {
            camerasPopUpButton.addItem(withTitle: "- No Camera Device -")
            hasCameraDevice = false
            return
        }
        
        for device in cameraDevices {
            camerasPopUpButton.addItem(withTitle: "\(device.localizedName)")
        }
        hasCameraDevice = true
    }
    
    func setupDefaultCamera() {
        if cameraDevices.count > 0 {
            if let device = cameraDevices.first {
                startUpCameraDevice(device)
            }
        }
    }
    
    func setupNumberOfHandsPopUpButton() {
        numberOfHandsPopUpButton.removeAllItems()
        
        numberOfHandsPopUpButton.addItem(withTitle: "One hand")
        numberOfHandsPopUpButton.addItem(withTitle: "Two hands")
    }
    
    func setupNumberLabel() {
        numberLabel.stringValue = ""
        numberLabel.wantsLayer = true
        numberLabel.layer?.backgroundColor = NSColor.white.cgColor
        numberLabel.isHidden = true
    }
    
    
    // MARK: - Camera Devices
    
    func getCameraDevices() -> [AVCaptureDevice] {
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .externalUnknown],
                                                                mediaType: .video,
                                                                position: .unspecified)
        return discoverySession.devices
    }
    
    func startUpCameraDevice(_ device: AVCaptureDevice) {
        if prepareCamera(device) {
            startSession()
        }
    }
        
    func prepareCamera(_ device: AVCaptureDevice) -> Bool {
        currentCameraDevice = device
        
        videoSession = AVCaptureSession()
        videoSession.sessionPreset = AVCaptureSession.Preset.vga640x480
        previewLayer = AVCaptureVideoPreviewLayer(session: videoSession)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
        //AVLayerVideoGravity.resizeAspectFill
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            
            if videoSession.canAddInput(input) {
                videoSession.addInput(input)
            }
            
            if let previewLayer = self.previewLayer {
                if let isVideoMirroringSupported = previewLayer.connection?.isVideoMirroringSupported,
                   isVideoMirroringSupported == true
                {
                    previewLayer.connection?.automaticallyAdjustsVideoMirroring = false
                    previewLayer.connection?.isVideoMirrored = false
                    videoMirrorLabel.isHidden = false
                    videoMirrorLabel.textColor = NSColor.darkGray
                    videoMirrorSwitch.isHidden = false
                    videoMirrorSwitch.state = .off
                } else {
                    videoMirrorLabel.isHidden = true
                    videoMirrorSwitch.isHidden = true
                }
                previewLayer.frame = self.previewView.bounds
                previewView.layer = previewLayer
                previewView.wantsLayer = true
                previewView.layer?.backgroundColor = NSColor.black.cgColor
            }
        } catch {
            print(error.localizedDescription)
            return false
        }
            
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sample buffer delegate", attributes: []))
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
        
        if videoSession.canAddOutput(videoOutput) {
            videoSession.addOutput(videoOutput)
        }
        return true
    }
    
    
    // MARK: - Video Session
    
    func startSession() {
        if let videoSession = videoSession {
            if !videoSession.isRunning {
                videoSession.startRunning()
            }
        }
    }
        
    func stopSession() {
        if let videoSession = videoSession {
            if videoSession.isRunning {
                videoSession.stopRunning()
            }
        }
    }
    
    
    // MARK: - IBAction
    
    @IBAction func selectCamerasPopUpButton(_ sender: NSPopUpButton) {
        if !hasCameraDevice { return }
        print("\(sender.indexOfSelectedItem) : \(sender.titleOfSelectedItem ?? "")")
        
        if sender.indexOfSelectedItem < cameraDevices.count {
            let device = cameraDevices[sender.indexOfSelectedItem]
            startUpCameraDevice(device)
        }
    }
    
    @IBAction func changeVideoMirrorSwitch(_ sender: NSSwitch) {
        if previewLayer == nil { return }
        
        switch sender.state {
        case .off:
            previewLayer.connection?.isVideoMirrored = false
            videoMirrorLabel.textColor = NSColor.darkGray
        case .on:
            previewLayer.connection?.isVideoMirrored = true
            videoMirrorLabel.textColor = NSColor.systemBlue
        default:
            break
        }
    }
    
    @IBAction func selectNumberOfHandsPopUpButton(_ sender: NSPopUpButton) {
        numberOfHands = sender.indexOfSelectedItem + 1
    }
    
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    
    func captureOutput(_ output: AVCaptureOutput,
                      didOutput sampleBuffer: CMSampleBuffer,
                           from connection: AVCaptureConnection)
    {
        handPoseDetection(sampleBuffer: sampleBuffer)
    }
    
    
    // MARK: - Hand Pose Detection
    
    func handPoseDetection(sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Failed to obtain a CVPixelBuffer for the current output frame.")
            return
        }
        
        let request = VNDetectHumanHandPoseRequest()
        request.maximumHandCount = numberOfHands
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        try? handler.perform([request])
        
        guard let observations = request.results else { return }
        
        DispatchQueue.main.async {
            self.handPoseNumberArray.removeAll()
            self.removeAllJointLayers()
            self.drawHandPose(observations)
        }
    }
    
    func drawHandPose(_ handPoseObservations: [VNHumanHandPoseObservation]) {
        if handPoseObservations.count <= 0 {
            numberLabel.isHidden = true
            return
        }
        
        for handPose in handPoseObservations {
            do {
                let points = try handPose.recognizedPoints(.all)
                drawJointPointsAndLines(points)
            } catch {
                numberLabel.isHidden = true
                print("Error: \(error.localizedDescription)")
            }
        }
        
        showSumOfHandPoseNumber()
    }
    
    func showSumOfHandPoseNumber() {
        var hasNumber = false
        var sum = 0
        
        for num in handPoseNumberArray {
            if num != nil {
                hasNumber = true
                sum += num!
            }
        }
        
        if hasNumber {
            numberLabel.stringValue = "\(sum)"
            numberLabel.isHidden = false
        } else {
            numberLabel.stringValue = ""
            numberLabel.isHidden = true
        }
    }
    
    func drawJointPointsAndLines(_ points: [VNHumanHandPoseObservation.JointName : VNRecognizedPoint]) {
        for (joint, point) in points {
            let jointPoint = previewLayer.layerPointConverted(fromCaptureDevicePoint: CGPoint(x: point.x, y: point.y))
            addToJointPoints(joint: joint, point: jointPoint)
        }
        
        var wristPoint : CGPoint?
        if let wristRecognizedPoint = points[.wrist] {
            wristPoint = previewLayer.layerPointConverted(fromCaptureDevicePoint:
                                                            CGPoint(x: wristRecognizedPoint.x, y: wristRecognizedPoint.y))
        }
        
        drawJointLine(points: indexFingerJointPoints, color: jointColor(.indexTip), wristPoint: wristPoint)
        drawJointLine(points: littleFingerJointPoints, color: jointColor(.littleTip), wristPoint: wristPoint)
        drawJointLine(points: middleFingerJointPoints, color: jointColor(.middleTip), wristPoint: wristPoint)
        drawJointLine(points: ringFingerJointPoints, color: jointColor(.ringTip), wristPoint: wristPoint)
        drawJointLine(points: thumbJointPoints, color: jointColor(.thumbTip), wristPoint: wristPoint)
        
        drawJointPoints(indexFingerJointPoints)
        drawJointPoints(littleFingerJointPoints)
        drawJointPoints(middleFingerJointPoints)
        drawJointPoints(ringFingerJointPoints)
        drawJointPoints(thumbJointPoints)
        
        if let point = wristPoint {
            drawJointPoints([.wrist : point])
        }
        
        let number = analyzeHandPoseNumber(wristPoint: wristPoint)
        handPoseNumberArray.append(number)
        
        removeAllJointPoints()
    }
    
    func drawJointPoints(_ points: [VNHumanHandPoseObservation.JointName : CGPoint]) {
        for (joint, point) in points {
            let shapeLayer = CAShapeLayer()
            shapeLayer.frame = CGRect(x: (point.x - 5) , y: (point.y - 5), width: 10, height: 10)
            shapeLayer.backgroundColor = jointColor(joint).cgColor

            previewLayer.addSublayer(shapeLayer)
            jointLayers.append(shapeLayer)
        }
    }
    
    func drawJointLine(points: [VNHumanHandPoseObservation.JointName : CGPoint], color: NSColor, wristPoint: CGPoint?) {
        var array = jointPointsToPointArray(points)
        if wristPoint != nil {
            array.append(wristPoint!)
        }
        if array.count <= 0 { return }
        
        var firstPoint = array[0]
        for point in array.dropFirst() {
            let line = CAShapeLayer()
            let bezierPath = NSBezierPath()
            bezierPath.move(to: firstPoint)
            bezierPath.line(to: point)
            bezierPath.close()
            
            line.path = bezierPath.cgPath
            line.fillColor = nil
            line.opacity = 1.0
            line.strokeColor = color.cgColor
            line.lineWidth = 2
            
            previewLayer.addSublayer(line)
            jointLayers.append(line)
            
            firstPoint = point
        }
    }
    
    func jointPointsToPointArray(_ points: [VNHumanHandPoseObservation.JointName : CGPoint]) -> [CGPoint] {
        var array : [CGPoint?] = [nil, nil, nil, nil]
        
        for (joint, point) in points {
            switch joint {
            case .indexTip, .littleTip, .middleTip, .ringTip, .thumbTip:
                array[0] = point
            case .indexDIP, .littleDIP, .middleDIP, .ringDIP, .thumbIP:
                array[1] = point
            case .indexPIP, .littlePIP, .middlePIP, .ringPIP, .thumbMP:
                array[2] = point
            case .indexMCP, .littleMCP, .middleMCP, .ringMCP, .thumbCMC:
                array[3] = point
            default:
                break
            }
        }
        
        var results = [CGPoint]()
        for point in array {
            if point != nil {
                results.append(point!)
            }
        }
        return results
    }
    
    func addToJointPoints(joint: VNHumanHandPoseObservation.JointName, point: CGPoint) {
        switch joint {
        case .indexDIP, .indexMCP, .indexPIP, .indexTip:
            indexFingerJointPoints[joint] = point
        case .littleDIP, .littleMCP, .littlePIP, .littleTip:
            littleFingerJointPoints[joint] = point
        case .middleDIP, .middleMCP, .middlePIP, .middleTip:
            middleFingerJointPoints[joint] = point
        case .ringDIP, .ringMCP, .ringPIP, .ringTip:
            ringFingerJointPoints[joint] = point
        case .thumbCMC, .thumbIP, .thumbMP, .thumbTip:
            thumbJointPoints[joint] = point
        default:
            break
        }
    }
    
    func jointColor(_ jointName: VNHumanHandPoseObservation.JointName) -> NSColor {
        switch jointName {
        case .indexDIP, .indexMCP, .indexPIP, .indexTip:
            return NSColor.red
        case .littleDIP, .littleMCP, .littlePIP, .littleTip:
            return NSColor.blue
        case .middleDIP, .middleMCP, .middlePIP, .middleTip:
            return NSColor.yellow
        case .ringDIP, .ringMCP, .ringPIP, .ringTip:
            return NSColor.green
        case .thumbCMC, .thumbIP, .thumbMP, .thumbTip:
            return NSColor.magenta
        default:
            return NSColor.orange
        }
    }
    
    func removeAllJointLayers() {
        if jointLayers.count <= 0 { return }
        
        for view in jointLayers {
            view.removeFromSuperlayer()
        }
        jointLayers.removeAll()
    }
    
    func removeAllJointPoints() {
        indexFingerJointPoints.removeAll()
        littleFingerJointPoints.removeAll()
        middleFingerJointPoints.removeAll()
        ringFingerJointPoints.removeAll()
        thumbJointPoints.removeAll()
    }
    
    
    // MARK: - Hand Status
    
    func analyzeHandPoseNumber(wristPoint: CGPoint?) -> Int? {
        let indexFingerIsOutspread  = fingerJointIsOutspread(indexFingerJointPoints, wristPoint: wristPoint)
        let middleFingerIsOutspread = fingerJointIsOutspread(middleFingerJointPoints, wristPoint: wristPoint)
        let ringFingerIsOutspread   = fingerJointIsOutspread(ringFingerJointPoints, wristPoint: wristPoint)
        let littleFingerIsOutspread = fingerJointIsOutspread(littleFingerJointPoints, wristPoint: wristPoint)
        
        let thumbIsOutspread = thumbJointIsOutspread(thumbJointPoints,
                                                     indexMCPPoint: indexFingerJointPoints[.indexMCP],
                                                     middleMCPPoint: middleFingerJointPoints[.middleMCP],
                                                     wristPoint: wristPoint)
        
        //print("Thumb Is Outspread: \(String(describing: thumbIsOutspread))")
        
        let number = handPoseWithNumber([indexFingerIsOutspread, middleFingerIsOutspread,
                                         ringFingerIsOutspread, littleFingerIsOutspread, thumbIsOutspread])
        
        
        return number
        

    }
    
    func handPoseWithNumber(_ statusArray: [Bool?]) -> Int? {
        var array = [Bool]()
        for status in statusArray {
            if status == nil {
                return nil
            }
            array.append(status!)
        }
        
        if array.count < 5 {
            return nil
        }
        
        if array[0] == false && array[1] == false &&
            array[2] == false && array[3] == false &&
            array[4] == false {
            return 0
        }
        if array[0] == true && array[1] == false &&
            array[2] == false && array[3] == false &&
            array[4] == false {
            return 1
        }
        if array[0] == true && array[1] == true &&
            array[2] == false && array[3] == false &&
            array[4] == false {
            return 2
        }
        if array[0] == true && array[1] == true &&
            array[2] == true && array[3] == false &&
            array[4] == false {
            return 3
        }
        if array[0] == true && array[1] == true &&
            array[2] == true && array[3] == true &&
            array[4] == false {
            return 4
        }
        if array[0] == true && array[1] == true &&
            array[2] == true && array[3] == true &&
            array[4] == true {
            return 5
        }
        
        return nil
    }
    
    func thumbJointIsOutspread(_ points: [VNHumanHandPoseObservation.JointName : CGPoint],
                               indexMCPPoint: CGPoint?,
                               middleMCPPoint: CGPoint?,
                               wristPoint: CGPoint?) -> Bool?
    {
        guard let indexMCPPoint = indexMCPPoint,
              let middleMCPPoint = middleMCPPoint,
              let wristPoint = wristPoint else { return nil }
        
        guard let thumbTipPoint = points[.thumbTip],
              let thumbIPPoint = points[.thumbIP] else { return nil }
        
        let thumbTipToIndexMCPDistance = twoPointsDistance(point1: thumbTipPoint, point2: indexMCPPoint)
        let thumbTipToMiddleMCPDistance = twoPointsDistance(point1: thumbTipPoint, point2: middleMCPPoint)
        
        if thumbTipToMiddleMCPDistance < thumbTipToIndexMCPDistance {
            return false
        }
        
        let thumbTipToWristDistance = twoPointsDistance(point1: thumbTipPoint, point2: wristPoint)
        let thumbIPToWristDistance = twoPointsDistance(point1: thumbIPPoint, point2: wristPoint)
        
        if thumbTipToWristDistance < thumbIPToWristDistance {
            return false
        }
        return true
    }
    
    func fingerJointIsOutspread(_ points: [VNHumanHandPoseObservation.JointName : CGPoint], wristPoint: CGPoint?) -> Bool? {
        var tipPoint : CGPoint?
        var dipPoint : CGPoint?
        var pipPoint : CGPoint?
        var mcpPoint : CGPoint?
        
        for (joint, point) in points {
            switch joint {
            case .indexTip, .littleTip, .middleTip, .ringTip, .thumbTip:
                tipPoint = point
            case .indexDIP, .littleDIP, .middleDIP, .ringDIP, .thumbIP:
                dipPoint = point
            case .indexPIP, .littlePIP, .middlePIP, .ringPIP, .thumbMP:
                pipPoint = point
            case .indexMCP, .littleMCP, .middleMCP, .ringMCP, .thumbCMC:
                mcpPoint = point
            default:
                break
            }
        }
        
        if tipPoint == nil || dipPoint == nil ||
            pipPoint == nil || mcpPoint == nil || wristPoint == nil {
            return nil
        }
        
        let tipToWristDistance = twoPointsDistance(point1: tipPoint!, point2: wristPoint!)
        let dipToWristDistance = twoPointsDistance(point1: dipPoint!, point2: wristPoint!)
        let mcpToWristDistance = twoPointsDistance(point1: mcpPoint!, point2: wristPoint!)
        
        if tipToWristDistance > mcpToWristDistance &&
            dipToWristDistance > mcpToWristDistance {
            return true
        }
        return false
    }
    
    func twoPointsDistance(point1: CGPoint, point2: CGPoint) -> CGFloat {
        let a = point1.x - point2.x
        let b = point1.y - point2.y
        return hypot(a, b)
    }
    
}


extension NSBezierPath {
    
    // A `CGPath` object representing the current `NSBezierPath`.
    var cgPath: CGPath {
        let path = CGMutablePath()
        let points = UnsafeMutablePointer<NSPoint>.allocate(capacity: 3)
        let elementCount = self.elementCount
        
        if elementCount > 0 {
            var didClosePath = true
            
            for index in 0..<elementCount {
                let pathType = self.element(at: index, associatedPoints: points)
                
                switch pathType {
                case .moveTo:
                    path.move(to: CGPoint(x: points[0].x, y: points[0].y))
                case .lineTo:
                    path.addLine(to: CGPoint(x: points[0].x, y: points[0].y))
                    didClosePath = false
                case .curveTo:
                    let control1 = CGPoint(x: points[1].x, y: points[1].y)
                    let control2 = CGPoint(x: points[2].x, y: points[2].y)
                    path.addCurve(to: CGPoint(x: points[0].x, y: points[0].y), control1: control1, control2: control2)
                    didClosePath = false
                case .closePath:
                    path.closeSubpath()
                    didClosePath = true
                default:
                    break
                }
            }
            
            if !didClosePath { path.closeSubpath() }
        }
        
        points.deallocate()
        return path
    }
}
