//
//  ViewController.swift
//  camera
//
//  Created by 大氣 on 2016/01/23.
//  Copyright © 2016年 Taiki. All rights reserved.
//

import UIKit
import AVFoundation
import PhotoTweaks
import KYShutterButton

class ViewController: UIViewController, PhotoTweaksViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    //カメラセッション
    var captureSession: AVCaptureSession!
    //デバイス
    var cameraDevices: AVCaptureDevice!
    //画像のアウトプット
    var imageOutput: AVCaptureStillImageOutput!
    
    var Image :UIImage!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        //セッションの作成
        self.captureSession = AVCaptureSession()
        
        //デバイス一覧の取得
        let devices = AVCaptureDevice.devices()
        
        //バックカメラをcameraDevicesに格納
        for device in devices {
            if device.position == AVCaptureDevicePosition.Back {
                cameraDevices = device as! AVCaptureDevice
            }
        }
        
        //バックカメラからVideoInputを取得
        let videoInput: AVCaptureInput!
        do {
            videoInput = try AVCaptureDeviceInput.init(device: cameraDevices)
        } catch {
            videoInput = nil
        }
        
        
        //セッションに追加
        captureSession.addInput(videoInput)
        
        //出力先を生成
        imageOutput = AVCaptureStillImageOutput()
        //セッションに追加
        captureSession.addOutput(imageOutput)
        //画像を表示するレイヤーを生成
        let captureVideoLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer.init(session: captureSession)
        captureVideoLayer.frame = self.view.bounds
        captureVideoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        
        //Viewに追加
        self.view.layer.addSublayer(captureVideoLayer)
        //セッション開始
        captureSession.startRunning()
        
        let label = UILabel(frame: CGRectMake(0,self.view.bounds.height-100,2000,150))
        label.backgroundColor = UIColor.blackColor()
        self.view.addSubview(label)
        
        
        // カメラのボタン
        let myButton = KYShutterButton(frame: CGRectMake(self.view.bounds.width/2 - 40,self.view.bounds.height-90,80,80),
                                       shutterType: .Normal,
                                       buttonColor: UIColor.redColor())
        
        buttonsData(myButton, color:UIColor.redColor(),str: "",
                    cornerRadius: myButton.frame.size.width / 2,selector: #selector(ViewController.onClickMyButton(_:)))
        myButton.addTarget(self,
                           action:#selector(ViewController.onClickMyButton(_:)),
                           forControlEvents: .TouchUpInside)
        
        //ライブラリへのボタン
        let libraryButton = UIButton(frame:CGRectMake(0, self.view.bounds.height-70, 120, 50))
        buttonsData(libraryButton,color: UIColor.clearColor(),  str: "ライブラリ",
                    cornerRadius: 0, selector: #selector(ViewController.onClickLibraryButton(_:)))
        
        //履歴へのボタン
        let goLogButton = UIButton(frame: CGRectMake(self.view.bounds.width-60,self.view.bounds.height-70,120,50))
        buttonsData(goLogButton, color: UIColor.clearColor(), str: "履歴", cornerRadius: 0, selector: #selector(ViewController.resultLogs(_:)))
        
    }
    
    func buttonsData(button: UIButton ,color:UIColor, str:String ,cornerRadius :CGFloat ,selector:Selector){
        
        button.backgroundColor =  color
        button.layer.masksToBounds = true
        button.setTitle(str, forState: .Normal)
        button.layer.cornerRadius = cornerRadius
        button.addTarget(self, action:selector, forControlEvents: .TouchUpInside)
        self.view.addSubview(button)
        
    }
    
    // ボタンイベント.
    func onClickMyButton(sender: UIButton){
        let captureVideoConnection = imageOutput.connectionWithMediaType(AVMediaTypeVideo)
        
        self.imageOutput.captureStillImageAsynchronouslyFromConnection(captureVideoConnection) { (imageDataBuffer, error) -> Void in
            let capturedImageData: NSData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataBuffer)
            self.Image = UIImage(data: capturedImageData)!
            //            self.performSegueWithIdentifier("sugue", sender: self)
            let photoTweaksViewController: PhotoTweaksViewController = PhotoTweaksViewController(image: self.Image)
            photoTweaksViewController.delegate = self
            //            photoTweaksViewController.autoSaveToLibray = true
            
            self.navigationController?.pushViewController(photoTweaksViewController, animated: true)
            
        }
        
        //        UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    
    func resultLogs(sender: UIButton)  {
        
    }
    
    /*タッチしたところにフォーカス*/
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let screenSize = view.bounds.size
        if let touchPoint = touches.first {
            let x = touchPoint.locationInView(view).y / screenSize.height
            let y = 1.0 - touchPoint.locationInView(view).x / screenSize.width
            let focusPoint = CGPoint(x: x, y: y)
            
            if let device = cameraDevices {
                do {
                    try device.lockForConfiguration()
                    
                    device.focusPointOfInterest = focusPoint
                    //device.focusMode = .ContinuousAutoFocus
                    device.focusMode = .AutoFocus
                    //device.focusMode = .Locked
                    device.exposurePointOfInterest = focusPoint
                    device.exposureMode = AVCaptureExposureMode.ContinuousAutoExposure
                    device.unlockForConfiguration()
                }
                catch {
                    // just ignore
                }
            }
        }
    }
    
    func onClickLibraryButton(sender:UIButton){
        // フォトライブラリを使用できるか確認
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary){
            // フォトライブラリの画像・写真選択画面を表示
            let imagePickerController = UIImagePickerController()
            imagePickerController.sourceType = .PhotoLibrary
            imagePickerController.allowsEditing = true
            imagePickerController.delegate = self
            presentViewController(imagePickerController, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        
        // 選択した画像・写真を取得し、imageViewに表示
        if let info = editingInfo, let editedImage = info[UIImagePickerControllerEditedImage] as? UIImage{
            //            imageView.image = editedImage
            self.Image = editedImage
        }else{
            //            imageView.image = image
            self.Image = image
        }
        // フォトライブラリの画像・写真選択画面を閉じる
        picker.dismissViewControllerAnimated(true, completion: nil)
        
        let photoTweaksViewController: PhotoTweaksViewController = PhotoTweaksViewController(image: self.Image)
        photoTweaksViewController.delegate = self
        //photoTweaksViewController.autoSaveToLibray = true
        
        self.navigationController?.pushViewController(photoTweaksViewController, animated: true)
        
    }
    
    func photoTweaksController(controller: PhotoTweaksViewController!, didFinishWithCroppedImage croppedImage: UIImage!) {
        let targetViewController = self.storyboard!.instantiateViewControllerWithIdentifier( "OCRViewController" ) as! OCRViewController
        targetViewController.image = croppedImage
        self.presentViewController( targetViewController, animated: true, completion: nil)
        
        //        controller.navigationController?.popViewControllerAnimated(true)
    }
    func photoTweaksControllerDidCancel(controller: PhotoTweaksViewController!) {
        controller.navigationController?.popViewControllerAnimated(true)
    }
    
    
//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        //        let viewController2 = segue.destinationViewController as! ImageEditingViewController
//        
//        if segue.identifier == "segue"{
//            //遷移先のインスタンスをsegueから取り出す
//            let viewController2 = segue.destinationViewController as! OCRViewController
//            
//            //ここでいろいろ処理みたいなことをする
//            viewController2.image = self.Image
//            
//        }
//    }
    
}



