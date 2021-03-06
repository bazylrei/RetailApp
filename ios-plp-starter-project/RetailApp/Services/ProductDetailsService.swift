import Foundation

protocol ProductDetailsService {
  func getProduct(id: String, completion: @escaping (Result<ProductDetails, Error>) -> Void)
}

class ProductDetailsServiceImplementation: ProductDetailsService {
  private let api: API

  init(api: API = API()) {
    self.api = api
  }

  func getProduct(id: String, completion: @escaping (Result<ProductDetails, Error>) -> Void) {
    let resource = Resource<ProductDetails>(path: Path.productURLString(for: id))
    api.load(resource, completion: completion)
  }
}
