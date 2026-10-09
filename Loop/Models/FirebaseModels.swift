import FirebaseFirestore

struct PublicProject: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var mainImageURL: String?
    var mainImageBase64: String?
    var status: String
    var difficultyLevel: String
    var category: String?
    var totalCost: Double?
    var username: String
    var userId: String?
    var createdAt: Date
    var patterns: [PatternInfo]?
    var projectDescription: String?
}

struct YarnInfo: Codable {
    var name: String
    var color: String
    var consumption: String?
    var brand: String?
    var material: String?
}

struct PatternInfo: Codable {
    var title: String
    var type: String
    var difficulty: String?
    var hookSize: Double?
    var textPattern: String?
    var numberOfRings: Int?
    var gridWidth: Int?
    var gridHeight: Int?
    var yarns: [YarnInfo]?
    var graphicPatternBase64: String?
    var pinnedNote: String?
}
