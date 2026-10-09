import Foundation
import SwiftData

@Model
final class Yarn {
    @Attribute(.unique) var yarnID: UUID
    var name: String
    var color: String
    var brand: String?
    var material: String?
    var imageData: Data?

    @Relationship var pattern: Pattern?
    var user: User?

    init(name: String, color: String, imageData: Data? = nil) {
        self.yarnID = UUID()
        self.name = name
        self.color = color
        self.imageData = imageData
    }
}
