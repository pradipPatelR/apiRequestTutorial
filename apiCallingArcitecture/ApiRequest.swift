

import UIKit

public enum methodType:String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}


class ApiRequest : NSObject {
    
    class var baseUrl: String {
        return ""
    }
    
    fileprivate class var customsHeader: [String:String] {
        return["Content-Type":"application/json","Accept":"application/json"]
    }
    
    typealias complation = ((Any?,String?) -> Swift.Void)
    
    
    class func doRequest(_ urlQuery:String, methodType:methodType, _ requestParameter:Any?,headers:[String:String]? = ApiRequest.customsHeader,complation: @escaping complation) -> Swift.Void
    {
        
        
        var urlString = ApiRequest.baseUrl.appending(urlQuery.trimmingCharacters(in: .whitespacesAndNewlines))
        urlString = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let appendingPersantage = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            urlString = appendingPersantage
        }
        else {
            urlString = urlString.replacingOccurrences(of: " ", with: "")
        }
        
        
        guard let url = URL(string: urlString) else {
            complation(nil,"url making problem")
            return
        }
        
        print("URL: ", url.absoluteString)
        
        var request = URLRequest(url: url)
        
        let httpMethod = methodType.rawValue
        print("Request Type: ", httpMethod)
        
        request.httpMethod = httpMethod
        
        
        if let getRequestParameter = requestParameter {
            do {
                let httpBody = try JSONSerialization.data(withJSONObject: getRequestParameter, options: .prettyPrinted)
                request.httpBody = httpBody
                
                let requestString = NSString.init(data: httpBody, encoding: String.Encoding.utf8.rawValue)
                
                if let getRequestString = requestString {
                    print("Request Parameter: \n", getRequestString)
                }
            }
            catch let parameterErr {
                print(parameterErr)
                complation(nil,"Parameter is not valid, check parameter")
                return
            }
        }
        
        
        request.timeoutInterval = 25
        
        if let getHeader = headers {
            for item in getHeader {
                request.addValue(item.value, forHTTPHeaderField: item.key)
            }
        }
        
        
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (resData, resResponse, resError) in
            DispatchQueue.main.async {
                
                if let getResponse = resResponse as? HTTPURLResponse {
                    print("Response Code :", getResponse.statusCode)
                }
                
                if resResponse == nil {
                    print(" Network is off or please check your wifi/internet activity.")
                }
                
                if let getResError  = resError {
                    print(getResError)
                    complation(nil,getResError.localizedDescription)
                    return
                }
                
                if let getResData = resData {
                    do {
                        let json = try JSONSerialization.jsonObject(with: getResData, options: .mutableContainers)
                        print("Response :\n",json)
                        
                        complation(json, nil)
                    }
                    catch let convertError {
                        print(convertError)
                        complation(nil,convertError.localizedDescription)
                    }
                }
                
            }
        })
        
        task.priority = 1.0
        task.resume()
        
    }
    
}
