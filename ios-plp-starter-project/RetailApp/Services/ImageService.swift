import UIKit

enum ImageDecodingError: Error {
  case badData
}

protocol ImageService {
  func downloadImage(key: String, completion: @escaping (Result<UIImage, Error>) -> Void)
  func downloadBadge(name: String, completion: @escaping (Result<UIImage, Error>) -> Void)
}

class ImageServiceImplementation: ImageService {
  private let api: API

  init(api: API = API()) {
    self.api = api
  }

  func downloadImage(key: String, completion: @escaping (Result<UIImage, Error>) -> Void) {
    let resource = Resource(path: Path.imageURLString(with: key), body: nil, method: "GET") { data -> Result<UIImage, Error> in
      guard let image = UIImage(data: data) else {
        return .error(ImageDecodingError.badData)
      }
      return .value(image)
    }
    api.load(resource, completion: completion)
  }
  
  func downloadBadge(name: String, completion: @escaping (Result<UIImage, Error>) -> Void) {
    let imageName = "\(name)_icon"
    downloadImage(key: imageName, completion: completion)
  }
}
