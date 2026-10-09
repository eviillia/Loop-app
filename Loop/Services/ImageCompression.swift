import UIKit

func compressedImageData(from image: UIImage, maxBytes: Int = 500_000) -> Data? {
    var compression: CGFloat = 1.0
    guard var data = image.jpegData(compressionQuality: compression) else { return nil }
    while data.count > maxBytes && compression > 0.1 {
        compression -= 0.1
        if let newData = image.jpegData(compressionQuality: compression) {
            data = newData
        }
    }
    return data
}
