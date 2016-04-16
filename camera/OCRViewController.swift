//
//  OCRViewController.swift
//  camera
//
//  Created by HayashiShinji on 2016/03/05.
//  Copyright © 2016年 Taiki. All rights reserved.
//

import UIKit
import TesseractOCR
import Alamofire
import SwiftyJSON
import SVProgressHUD

class OCRViewController: UIViewController, UITableViewDelegate ,UITableViewDataSource ,G8TesseractDelegate   {
    
    @IBOutlet var Imageview :UIImageView!
    @IBOutlet var OCRView :UIView!
    
    @IBOutlet var table : UITableView!
    var image :UIImage!
    var jsonDic : [String] = []
    
    let defaults = NSUserDefaults.standardUserDefaults()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.Imageview.image = self.image
        self.Imageview.contentMode = UIViewContentMode.ScaleAspectFit
        
        self.table.dataSource = self
        self.table.delegate = self
        SVProgressHUD.show()
        
        self.analyze()
        
        
    }
    
    func analyze() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
            let tesseract = G8Tesseract(language: "eng")
            tesseract.delegate = self
            tesseract.image = self.image
            tesseract.recognize()
            
            //            self.label.text = tesseract.recognizedText
            
            
            print(tesseract.recognizedText)
            
            
            //            if G8Tesseract.recognizedText.lowercaseString.containsString("\n") { // -> true
            //                print("swiftが含まれる")
            //            }
            
            let str = tesseract.recognizedText.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            
            if str.localizedLowercaseString.containsString("\n"){
                SVProgressHUD.showErrorWithStatus("失敗")
                self.dismissViewControllerAnimated(true, completion: nil)
                
            }else{
                self.defaults.setObject(str, forKey: "name")
                self.defaults.synchronize()
                self.getArticles(str)
            }
            
        })
    }
    
    
    func getArticles(phrase : String) {
        let httpUrl: String = "https://glosbe.com/gapi/translate?from=en&dest=ja&format=json&phrase="
        let pretty: String = "&pretty=true"
        let url: URLStringConvertible = httpUrl + phrase + pretty
        print(url)
        
        
        Alamofire.request(.GET, url).responseJSON { response in
            
            guard let object = response.result.value else {
                return
            }
            let json = JSON(object)
            
            
            let count = json["tuc"].count
            
            //            if json["tuc"].string != nil {
            for i in 0...count {
                //                print(json["tuc"][i]["phrase"]["text"].string)
                if json["tuc"][i]["phrase"]["text"].string == nil{
                    break
                }else{
                    self.jsonDic.append(json["tuc"][i]["phrase"]["text"].string!)
                }
            }
            //            }else{
            //                SVProgressHUD.showErrorWithStatus("失敗")
            //                self.dismissViewControllerAnimated(true, completion: nil)
            //
            //            }
            json.forEach { (_, json) in
            }
            let check = self.jsonDic.isEmpty
            
            if check {
                
            }else{
                self.defaults.setObject(self.jsonDic, forKey: "data")
                self.defaults.synchronize()
            }
            
            
            print(self.jsonDic)
            self.table.reloadData()
            SVProgressHUD.dismiss()
           
        }
    }
    
    //    Table Viewのセルの数を指定
    func tableView(table: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.jsonDic.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        //        let cellIdentifier = "cell"
        
        let cell = tableView.dequeueReusableCellWithIdentifier("cell")
        
        // Cellに値を設定する.
        cell!.textLabel!.text = String(self.jsonDic[indexPath.row])
        
        return cell!
        
    }
    
    func shouldCancelImageRecognitionForTesseract(tesseract: G8Tesseract!) -> Bool {
        return false; // return true if you need to interrupt tesseract before it finishes
    }
    
    
    
    
}
