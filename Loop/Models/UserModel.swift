import Foundation
import SwiftData

@Model
final class User {
    @Attribute(.unique) var firebaseID: String
    var email: String
    var username: String
    var avatarData: Data?
    var aboutMe: String?
    var createdAt: Date

    @Relationship(deleteRule: .cascade) var projects: [Project] = []

    init(firebaseID: String, email: String, username: String,
         avatarData: Data? = nil,
         aboutMe: String? = nil, createdAt: Date = Date()) {
        self.firebaseID = firebaseID
        self.email = email
        self.username = username
        self.avatarData = avatarData
        self.aboutMe = aboutMe
        self.createdAt = createdAt
    }
}
