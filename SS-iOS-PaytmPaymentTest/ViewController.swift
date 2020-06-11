//
//  ViewController.swift
//  SS-iOS-PaytmPaymentTest
//
//  Created by Dipanwita on 10/06/20.
//  Copyright © 2020 Sastasundar. All rights reserved.
//

import UIKit
import AppInvokeSDK

class ViewController: UIViewController {
    
    @IBOutlet weak var btnProceedOutlet: UIButton!
    var transitiondata : [String : AnyObject] = [:]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        btnProceedOutlet.backgroundColor =  .gray
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
    }
    @IBAction func btnApiCall(_ sender: Any) {
        DispatchQueue.main.async(execute: {
            self.btnProceedOutlet.backgroundColor =  .gray
        })
        //transaction api call from backend
        self.callTransitionApi()
    }
    
    @IBAction func btnProceedAction(_ sender: Any) {
        print("MID===>\(transitiondata["mid"] ?? "" as AnyObject)")
        print("orderId===>\(transitiondata["orderId"] ?? "" as AnyObject)")
        print("txnToken===>\(transitiondata["txnToken"] ?? "" as AnyObject)")
        print("amount===>\(transitiondata["amount"] ?? "" as AnyObject)")
        print("callbackurl===>\(transitiondata["callbackurl"] ?? "" as AnyObject)")
        
        AIHandler().openPaytm(merchantId: (transitiondata["mid"] as? String) ?? "", orderId: (transitiondata["orderId"] as? String) ?? "", txnToken: (transitiondata["txnToken"] as? String) ?? "", amount: (transitiondata["amount"] as? String) ?? "", redirectionUrl : (transitiondata["callbackurl"] as? String) ?? "", delegate: self)
    }
    
    
    func callTransitionApi() {
        
        let parameters = [
            "RequestHeader": ["AppVersion": "3.8.1",
                              "AccessToken": "4993b8656b6c62202f0f76ada00614e6",
            ]
        ]
        
        print("Paramas=====>>>\(parameters)")
        
        //        let url = URL(string: "https://test-api.sastasundar.com/sastasundar/index.php/pay/pay/postData")!
        let url = URL(string: "https://api.sastasundar.com/sastasundar/index.php/pay/pay/postData")!
        var request = URLRequest(url: url)
        // request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = parameters.percentEncoded()
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                let response = response as? HTTPURLResponse,
                error == nil else {                                              // check for fundamental networking error
                    print("error", error ?? "Unknown error")
                    return
            }
            guard (200 ... 299) ~= response.statusCode else {                    // check for http errors
                print("statusCode should be 2xx, but is \(response.statusCode)")
                print("response = \(response)")
                return
            }
            
            let responseString = String(data: data, encoding: .utf8)
            do{
                if let json = responseString?.data(using: String.Encoding.utf8){
                    if let jsonData = try JSONSerialization.jsonObject(with: json, options: .allowFragments) as? [String:AnyObject]{
                        let jsonDic = jsonData["data"] as! [String : AnyObject]
                        self.transitiondata = jsonDic["PaytmPgMerchantDetails"] as! [String : AnyObject]
                        
                        DispatchQueue.main.async(execute: {
                            self.btnProceedOutlet.backgroundColor =  .blue
                        })
                        
                    }
                }
            }catch {
                print(error.localizedDescription)
            }
        }
        task.resume()
    }
    
}
extension ViewController : AIDelegate {
    func openPaymentWebVC(_ controller: UIViewController?) {
        
        if let vc = controller {
            DispatchQueue.main.async {[weak self] in
                // vc.modalPresentationStyle = .fullScreen
                print("callWebVc")
                self?.present(vc, animated: true, completion: nil)
            }
        }
    }
    
    func didFinish(with success: Bool, response: [String : Any]) {
        print("PayTm_Response======>>>>\(response)")
        print("PayTmSuccessOrNot=======>>>\(success)")
    }
    
    
}
extension Dictionary {
    func percentEncoded() -> Data? {
        return map { key, value in
            let escapedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            return escapedKey + "=" + escapedValue
        }
        .joined(separator: "&")
        .data(using: .utf8)
    }
}
extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="
        
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return allowed
    }()
}
