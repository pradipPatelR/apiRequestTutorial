//
//  WShandler.swift
//  ShivTechnolabsDemo
//
//  Created by Pradip Patel on 11/09/21.
//

import UIKit
import Alamofire


public typealias WSBlock = (Result<WS_SuccessModel, WS_ErrorModel>) -> Void
public typealias WSDictionary = [String: Any]

public var wsErrorCode: Int { return -51515 }

public struct WS_SuccessModel {
    var dictionary: WSDictionary?
    var dictionaryOfArray: [WSDictionary]?
    var anyResponse: Any
    var anyResponseString: String
    var errorJSONSerialization: String?
    var urlString: String
    var statusCode: Int
    
    init(anyResponse: Data, urlString: String, statusCode: Int) {
        self.anyResponse = anyResponse
        self.urlString = urlString
        self.statusCode = statusCode
        
        self.anyResponseString = String(data: anyResponse, encoding: .utf8) ?? ""
        
        do {
            self.anyResponse = try JSONSerialization.jsonObject(with: anyResponse)
        } catch let err {
            self.errorJSONSerialization = err.localizedDescription
            self.anyResponse = self.anyResponseString
        }
        
        if let dictValue = self.anyResponse as? WSDictionary {
            self.dictionary = dictValue
        } else if let dictValue = self.anyResponse as? [WSDictionary] {
            self.dictionaryOfArray = dictValue
        }
        
    }
}

public struct WS_ErrorModel: Error {
    var error: Error
    var urlString: String
    var statusCode: Int
    
    init(error: Error?, urlString: String, statusCode: Int) {
        if let afError = error as? AFError {
            self.error = afError.underlyingError ?? NSError(domain: "Something went wrong happen", code: wsErrorCode)
        } else if let getError = error {
            self.error = getError
        } else {
            self.error = NSError(domain: "Something went wrong happen", code: wsErrorCode)
        }
        
        self.urlString = urlString
        self.statusCode = statusCode
    }
}

public enum WSMethod {
    case connect, delete, get, head, options, patch, post, put, trace
    
    fileprivate var toHTTPMethod: HTTPMethod {
        switch self {
        case .connect: return HTTPMethod.connect
        case .delete: return HTTPMethod.delete
        case .get: return HTTPMethod.get
        case .head: return HTTPMethod.head
        case .options: return HTTPMethod.options
        case .patch: return HTTPMethod.patch
        case .post: return HTTPMethod.post
        case .put: return HTTPMethod.put
        case .trace: return HTTPMethod.trace
        }
    }
}

protocol WSParametersProtocol {
    func toConvertWSParameters() -> WSParameters
}

extension WSDictionary: WSParametersProtocol {
    func toConvertWSParameters() -> WSParameters {
        return .dictionary(self)
    }
}

extension Array where Element == WSDictionary {
    func toConvertWSParameters() -> WSParameters {
        return .dictionaryArray(self)
    }
}

extension String: WSParametersProtocol {
    func toConvertWSParameters() -> WSParameters {
        return .string(self)
    }
}

public enum WSParameters {
    case dictionary(WSDictionary)
    case dictionaryArray([WSDictionary])
    case string(String)
    
    fileprivate var dictionary: (isValue: Bool, value: WSDictionary?) {
        switch self {
        case .dictionary(let value): return (true, value)
        default: return (false, nil)
        }
    }
    
    fileprivate var array: (isValue: Bool, value: [WSDictionary]?) {
        switch self {
        case .dictionaryArray(let value): return (true, value)
        default: return (false, nil)
        }
    }
    
    fileprivate var string: (isValue: Bool, value: String?) {
        switch self {
        case .string(let value): return (true, value)
        default: return (false, nil)
        }
    }
}

public enum WSURLEncoding {
    case `default`
    case queryString
    case httpBody
    case otherType(destination: URLEncoding.Destination, arrayEncoding: URLEncoding.ArrayEncoding, boolEncoding: URLEncoding.BoolEncoding)
}

public enum WSParameterEncoding {
    
    case jsonEncoding(writingOptionsType: JSONSerialization.WritingOptions!)
    case urlEncoding(urlEncodingType: WSURLEncoding)
    
    fileprivate var toParameterEncoding: ParameterEncoding {
        switch self {
        case .jsonEncoding(let writingOptionsType):
            return writingOptionsType != nil ? JSONEncoding.init(options: writingOptionsType!) : JSONEncoding.default
        case .urlEncoding(let urlEncodingType):
            switch urlEncodingType {
            case .default:
                return URLEncoding.default
            case .queryString:
                return URLEncoding.queryString
            case .httpBody:
                return URLEncoding.httpBody
            case .otherType(let destination, let arrayEncoding, let boolEncoding):
                return URLEncoding(destination: destination, arrayEncoding: arrayEncoding, boolEncoding: boolEncoding)
            }
        }
    }
}

//MARK:- Definition
public class WShandler: NSObject {
    
    private(set) var currentRequest : Request?
    private(set) var urlString: String
    private(set) var method: WSMethod
    private(set) var wsParameterEncoding: WSParameterEncoding
    private(set) var timeoutInterval: TimeInterval
    private(set) var isApiCalling : Bool = false
    
    init(urlString: String, method: WSMethod, wsParameterEncoding: WSParameterEncoding = .urlEncoding(urlEncodingType: .default), timeoutInterval: TimeInterval = 60) {
        self.urlString = urlString
        self.method = method
        self.wsParameterEncoding = wsParameterEncoding
        self.timeoutInterval = timeoutInterval
    }
    
    //MARK:- Post Request
    func webRequest(headers: [String: String]? = nil, parameters: WSParametersProtocol?, completionHandler: @escaping WSBlock) {
        
        var sendHeaders : HTTPHeaders?
        if let getHeaders = headers, getHeaders.count > 0 {
            sendHeaders = HTTPHeaders(getHeaders)
        }
        
        guard let url = URL(string: urlString) ?? URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!) else {
            let appName = Bundle.main.infoDictionary?[kCFBundleNameKey as String] ?? ""
            completionHandler(.failure(.init(error: NSError(domain: "invalid URL, Contact \(appName) Support", code: wsErrorCode), urlString: urlString, statusCode: wsErrorCode)))
            return
        }
        
        WShandlerApiLogs.default.simpleLog("URL => \(url.absoluteString)")
        
        if self.isApiCalling {
            return
        }
        
        self.isApiCalling = true
        
        self.currentRequest = AF.request(url, method: method.toHTTPMethod, parameters: parameters?.toConvertWSParameters().dictionary.value, encoding: wsParameterEncoding.toParameterEncoding, headers: sendHeaders, requestModifier: { [weak self] (urlSession) in
            
            if let parameter = parameters?.toConvertWSParameters(), parameter.array.isValue {
                urlSession.httpBody = try? JSONSerialization.data(withJSONObject: parameter.array.value!, options: .prettyPrinted)
            } else if let parameter = parameters?.toConvertWSParameters(), parameter.string.isValue {
                urlSession.httpBody = parameter.string.value?.data(using: .utf8)
            }
            
            guard let `self` = self else { return }
            urlSession.timeoutInterval = self.timeoutInterval
            
        }).responseJSON { [weak self] (dataResponse) in
            
            if let getData = dataResponse.data {
                
                let model: WS_SuccessModel = .init(anyResponse: getData, urlString: dataResponse.response?.url?.absoluteString ?? "", statusCode: dataResponse.response?.statusCode ?? wsErrorCode)
                
                WShandlerApiLogs.default.successLog(model: model, rqHeader: dataResponse.request?.headers.dictionary, rsHeader: dataResponse.response?.headers.dictionary, parameter: parameters?.toConvertWSParameters())
                
                completionHandler(.success(model))
            } else {
                
                let model: WS_ErrorModel = .init(error: dataResponse.error, urlString: dataResponse.response?.url?.absoluteString ?? "", statusCode: dataResponse.response?.statusCode ?? wsErrorCode)
                
                WShandlerApiLogs.default.failLog(model: model, rqHeader: dataResponse.request?.headers.dictionary, rsHeader: dataResponse.response?.headers.dictionary, parameter: parameters?.toConvertWSParameters())
                
                completionHandler(.failure(model))
            }
            
            self?.isApiCalling = false
            self?.currentRequest = nil
        }
    }
    
    
    //MARK:- Cancel Request
    func cancelRequest() {
        guard let isFinished = self.currentRequest?.isFinished, !isFinished else {
            WShandlerApiLogs.default.simpleLog("current Request is already finished.")
            return
        }
        
        currentRequest?.cancel()
    }
    
    class WShandlerApiLogs {
        
        enum PrintTypes {
            case url, requestHeaders, statusCode, response, error, responseHeaders
        }
        
        static var `default` : WShandlerApiLogs = .init()
        var isEnable: Bool = false
        var printTypes: [PrintTypes] = [.url, .requestHeaders, .statusCode, .response, .responseHeaders]
        
        func simpleLog(_ items: Any..., separator: String = " ", terminator: String = "\n") {
            guard self.isEnable else { return }
            debugPrint(items, separator: separator, terminator: terminator)
            
        }
        
        func successLog(model: WS_SuccessModel, rqHeader: [String: String]?, rsHeader: [String: String]?, parameter: WSParameters?) {
            guard self.isEnable else { return }
            
            self.printTypes.contains(where: { $0 == .url }) ? debugPrint("URL =>", model.urlString, separator: "\n", terminator: "\n\n") : ()
            self.printTypes.contains(where: { $0 == .requestHeaders }) ? headerParamLog(rqHeader: rqHeader, rsHeader: nil, parameter: parameter) : ()
            self.printTypes.contains(where: { $0 == .statusCode }) ? debugPrint("Status Code =>", model.statusCode, separator: "\n", terminator: "\n\n") : ()
            
            if self.printTypes.contains(where: { $0 == .responseHeaders }) {
                if let value: Any = model.dictionary ?? model.dictionaryOfArray,
                   let data = try? JSONSerialization.data(withJSONObject: value, options: .prettyPrinted) {
                    debugPrint("Response =>", NSString.init(data: data, encoding: String.Encoding.utf8.rawValue) ?? model.anyResponseString, separator: "\n", terminator: "\n\n")
                } else {
                    debugPrint("Response =>", model.anyResponseString, separator: "\n", terminator: "\n\n")
                }
            }
            
            self.printTypes.contains(where: { $0 == .responseHeaders }) ? headerParamLog(rqHeader: nil, rsHeader: rsHeader, parameter: nil) : ()
            
        }
        
        func failLog(model: WS_ErrorModel, rqHeader: [String: String]?, rsHeader: [String: String]?, parameter: WSParameters?) {
            guard self.isEnable else { return }
            self.printTypes.contains(where: { $0 == .url }) ? debugPrint("URL =>", model.urlString, separator: "\n", terminator: "\n\n") : ()
            self.printTypes.contains(where: { $0 == .requestHeaders }) ? headerParamLog(rqHeader: rqHeader, rsHeader: nil, parameter: parameter) : ()
            self.printTypes.contains(where: { $0 == .statusCode }) ? debugPrint("Status Code =>", model.statusCode, separator: "\n", terminator: "\n\n") : ()
            self.printTypes.contains(where: { $0 == .error }) ? debugPrint("Error =>\n", model.error, separator: "\n", terminator: "\n\n") : ()
            self.printTypes.contains(where: { $0 == .responseHeaders }) ? headerParamLog(rqHeader: nil, rsHeader: rsHeader, parameter: nil) : ()
                            
        }
        
        private func headerParamLog(rqHeader: [String: String]?, rsHeader: [String: String]?, parameter: WSParameters?) {
            if let _parameter = parameter {
                
                if _parameter.dictionary.isValue, let value = _parameter.dictionary.value {
                    
                    if let data = try? JSONSerialization.data(withJSONObject: value, options: .prettyPrinted) {
                        debugPrint("Parameter =>", NSString.init(data: data, encoding: String.Encoding.utf8.rawValue) ?? value, separator: "\n", terminator: "\n\n")
                    } else {
                        debugPrint("Parameter =>", value, separator: "\n", terminator: "\n\n")
                    }
                } else if _parameter.array.isValue, let value = _parameter.array.value {
                    
                    if let data = try? JSONSerialization.data(withJSONObject: value, options: .prettyPrinted) {
                        debugPrint("Parameter =>", NSString.init(data: data, encoding: String.Encoding.utf8.rawValue) ?? value, separator: "\n", terminator: "\n\n")
                    } else {
                        debugPrint("Parameter =>", value, separator: "\n", terminator: "\n\n")
                    }
                } else if _parameter.string.isValue, let value = _parameter.string.value {
                    
                    debugPrint("Parameter =>", value, separator: "\n", terminator: "\n\n")
                }
            }
            
            func printHeader(_ _header: [String: String], _ prefixString: String) {
                if _header.isEmpty {
                    debugPrint("\(prefixString) Header => {} (blank Value)", separator: "\n", terminator: "\n\n")
                } else if let data = try? JSONSerialization.data(withJSONObject: _header, options: .prettyPrinted) {
                    debugPrint("\(prefixString) Header =>", NSString.init(data: data, encoding: String.Encoding.utf8.rawValue) ?? _header, separator: "\n", terminator: "\n\n")
                } else {
                    debugPrint("\(prefixString) Header =>", _header, separator: "\n", terminator: "\n\n")
                }
            }
            
            if let _header = rqHeader {
                printHeader(_header, "Request")
            }
            
            if let _header = rsHeader {
                printHeader(_header, "Response")
            }
        }
    }
}
