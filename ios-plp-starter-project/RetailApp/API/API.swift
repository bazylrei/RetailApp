import Foundation

protocol Resumable {
  func resume()
}
extension URLSessionDataTask: Resumable {}

protocol URLSessionProtocol {
  func resumableDataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> Resumable
}

extension URLSession: URLSessionProtocol {
  func resumableDataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> Resumable {
    return dataTask(with: request, completionHandler: completionHandler)
  }
}

class API {
  private let urlSession: URLSessionProtocol
  private let baseURL: URL

  init(urlSession: URLSessionProtocol = URLSession.shared, baseURL: URL = Path.baseURL) {
    self.urlSession = urlSession
    self.baseURL = baseURL
  }

  func load<Model>(_ resource: Resource<Model>, completion: @escaping (Result<Model, Error>) -> Void) {
    var urlRequest = URLRequest(url: baseURL.appendingPathComponent(resource.path))
    urlRequest.httpMethod = resource.method
    urlRequest.httpBody = resource.body
    urlRequest.setValue(base64LoginString, forHTTPHeaderField: "Authorization")
    urlSession.resumableDataTask(with: urlRequest) { data, urlResponse, error in
      func completionOnMain(_ result: Result<Model, Error>) {
        DispatchQueue.main.async {
          completion(result)
        }
      }
      guard let urlResponse = urlResponse else {
        completionOnMain(.error(HTTPError.noResponse))
        return
      }
      if let error = error {
        completionOnMain(.error(HTTPError.requestError(error)))
        return
      }
      guard let httpURLResponse = urlResponse as? HTTPURLResponse else {
        completionOnMain(.error(HTTPError.invalidResponse(urlResponse)))
        return
      }
      guard (200..<300).contains(httpURLResponse.statusCode) else {
        completionOnMain(.error(HTTPError.unsuccessful(statusCode: httpURLResponse.statusCode, urlResponse: httpURLResponse, error: error)))
        return
      }
      guard let data = data else {
        fatalError("Missing data when should always be present")
      }
      completionOnMain(resource.parse(data))
    }.resume()
  }
  
  private var base64LoginString: String {
    let username = "admin"
    let password = "password"
    let loginString = String(format: "%@:%@", username, password)
    let loginData = loginString.data(using: String.Encoding.utf8)!
    let base64LoginString = loginData.base64EncodedString()
    return "Basic \(base64LoginString)"
  }
}
