import Foundation
class ApiManager {
    
    private init (){}
    public static let sharedInstance = ApiManager()
    
    public func requestServerAtPathURL(url: URL, httpBody: Data, httpMethodType: HttpMethod, httpHeaders : [String: String], onApiCallCompletion : @escaping (Error?,Int,Data?) -> Void) {
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = httpMethodType.rawValue
        urlRequest.httpBody = httpBody
        urlRequest.allHTTPHeaderFields = httpHeaders
        let session = URLSession.shared
        
        let task = session.dataTask(with: urlRequest) { (data, response, error) in
            
            if let apiResponse = response as? HTTPURLResponse{
                onApiCallCompletion(error,apiResponse.statusCode,data)
            }else{
                let error = NSError(domain:"", code:0, userInfo:[ NSLocalizedDescriptionKey: "Error occured while parsing URLResponse with HTTPURLResponse"])
                onApiCallCompletion(error,0,data)
            }
            
        }
        
        task.resume()
        
    }
    
    public func createFormBodyWithParameters(fileName: String, imageDataToBeUploaded: String, boundary: String) -> Data
    {
        
        let body = NSMutableData();
        
        let name = "photo"
        let mimetype = "image/jpeg"
        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"\r\n".utf8))
        body.append(Data("Content-Type: \(mimetype)\r\n\r\n".utf8))
        body.append(Data(imageDataToBeUploaded.utf8))
        body.append(Data("\r\n".utf8))
        body.append(Data("--\(boundary)--\r\n".utf8))
        
        return body as Data 
    }
    
}
