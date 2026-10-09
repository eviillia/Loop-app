import Foundation
import FirebaseFirestore
import FirebaseAuth

class FirebaseService {
    static let shared = FirebaseService()
    private let db = Firestore.firestore()


    func signUp(email: String, password: String, username: String,
                completion: @escaping (Result<FirebaseAuth.User, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let firebaseUser = result?.user else { return }
            let changeRequest = firebaseUser.createProfileChangeRequest()
            changeRequest.displayName = username
            changeRequest.commitChanges { _ in
                let userData: [String: Any] = [
                    "email": email,
                    "username": username,
                    "createdAt": Timestamp(date: Date())
                ]
                self.db.collection("users").document(firebaseUser.uid)
                    .setData(userData) { error in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            completion(.success(firebaseUser))
                        }
                    }
            }
        }
    }

    func signIn(email: String, password: String,
                completion: @escaping (Result<FirebaseAuth.User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error { completion(.failure(error)); return }
            guard let user = result?.user else {
                completion(.failure(NSError(domain: "Auth", code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "User not found"])))
                return
            }
            completion(.success(user))
        }
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }


    func savePublicProject(project: Project, username: String, completion: @escaping (Bool) -> Void) {
        performSavePublicProject(project: project, username: username, completion: completion)
    }

    private func performSavePublicProject(project: Project, username: String, completion: @escaping (Bool) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else { completion(false); return }
        let finalUsername = username.isEmpty ? (Auth.auth().currentUser?.displayName ?? "User") : username

        var patternsArray = [[String: Any]]()
        for pattern in project.patterns {
            var yarnsArray = [[String: Any]]()
            if let yarns = pattern.yarns {
                for yarn in yarns {
                    yarnsArray.append([
                        "name": yarn.name,
                        "color": yarn.color
                    ])
                }
            }
            patternsArray.append([
                "title": pattern.title,
                "type": pattern.type.rawValue,
                "difficulty": pattern.difficultyLevel.rawValue,
                "hookSize": pattern.hookSize ?? 0,
                "textPattern": pattern.textPattern ?? "",
                "numberOfRings": pattern.numberOfRings ?? 0,
                "gridWidth": pattern.gridWidth ?? 0,
                "gridHeight": pattern.gridHeight ?? 0,
                "graphicPatternBase64": pattern.graphicPatternData?.base64EncodedString() ?? "",
                "pinnedNote": pattern.pinnedNote ?? "",
                "yarns": yarnsArray
            ])
        }

        var data: [String: Any] = [
            "title": project.title,
            "status": project.status.rawValue,
            "difficultyLevel": project.difficultyLevel.rawValue,
            "category": project.category?.rawValue ?? "",
            "totalCost": project.totalCost ?? 0,
            "username": finalUsername,
            "userId": userId,
            "createdAt": Timestamp(date: project.createdAt),
            "projectDescription": project.projectDescription ?? "",
            "patterns": patternsArray
        ]
        if let imageData = project.mainImageData {
            data["mainImageBase64"] = imageData.base64EncodedString()
        }

        if let docID = project.firestoreDocumentID {
            db.collection("publicProjects").document(docID).setData(data, merge: true) { error in
                completion(error == nil)
            }
        } else {
            let ref = db.collection("publicProjects").document()
            ref.setData(data) { error in
                if error == nil { project.firestoreDocumentID = ref.documentID }
                completion(error == nil)
            }
        }
    }

    func updatePublicProject(project: Project, username: String, completion: @escaping (Bool) -> Void) {
        guard let docID = project.firestoreDocumentID else { completion(false); return }
        let finalUsername = username.isEmpty ? (Auth.auth().currentUser?.displayName ?? "User") : username

        var patternsArray = [[String: Any]]()
        for pattern in project.patterns {
            var yarnsArray = [[String: Any]]()
            if let yarns = pattern.yarns {
                for yarn in yarns {
                    yarnsArray.append([
                        "name": yarn.name,
                        "color": yarn.color
                    ])
                }
            }
            patternsArray.append([
                "title": pattern.title,
                "type": pattern.type.rawValue,
                "difficulty": pattern.difficultyLevel.rawValue,
                "hookSize": pattern.hookSize ?? 0,
                "textPattern": pattern.textPattern ?? "",
                "numberOfRings": pattern.numberOfRings ?? 0,
                "gridWidth": pattern.gridWidth ?? 0,
                "gridHeight": pattern.gridHeight ?? 0,
                "graphicPatternBase64": pattern.graphicPatternData?.base64EncodedString() ?? "",
                "pinnedNote": pattern.pinnedNote ?? "",
                "yarns": yarnsArray
            ])
        }

        var data: [String: Any] = [
            "username": finalUsername,
            "projectDescription": project.projectDescription ?? "",
            "patterns": patternsArray
        ]
        if let imageData = project.mainImageData {
            data["mainImageBase64"] = imageData.base64EncodedString()
        }

        db.collection("publicProjects").document(docID).updateData(data) { error in
            completion(error == nil)
        }
    }

    func deletePublicProject(project: Project, completion: @escaping (Bool) -> Void) {
        guard let docID = project.firestoreDocumentID else { completion(true); return }
        db.collection("publicProjects").document(docID).delete { error in
            if error == nil { project.firestoreDocumentID = nil }
            completion(error == nil)
        }
    }

    func updateUsernameInPublicProjects(newUsername: String, userId: String, completion: @escaping (Bool) -> Void) {
        db.collection("publicProjects").whereField("userId", isEqualTo: userId).getDocuments { snapshot, error in
            guard let docs = snapshot?.documents else { completion(false); return }
            let batch = self.db.batch()
            for doc in docs { batch.updateData(["username": newUsername], forDocument: doc.reference) }
            batch.commit { err in completion(err == nil) }
        }
    }

    func fetchPublicProjects(completion: @escaping ([PublicProject]) -> Void) {
        db.collection("publicProjects")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                guard let docs = snapshot?.documents else { completion([]); return }
                let projects: [PublicProject] = docs.compactMap { doc -> PublicProject? in
                    let data = doc.data()
                    guard let title = data["title"] as? String,
                          let username = data["username"] as? String,
                          let status = data["status"] as? String,
                          let difficulty = data["difficultyLevel"] as? String,
                          let timestamp = data["createdAt"] as? Timestamp else { return nil }
                    let mainImageBase64 = data["mainImageBase64"] as? String
                    let category = data["category"] as? String
                    let totalCost = data["totalCost"] as? Double
                    let userId = data["userId"] as? String
                    let projectDescription = data["projectDescription"] as? String

                    var patterns: [PatternInfo]? = nil
                    if let patternsData = data["patterns"] as? [[String: Any]] {
                        patterns = patternsData.compactMap { pdict in
                            guard let pt = pdict["title"] as? String,
                                  let tp = pdict["type"] as? String else { return nil }
                            var yarns: [YarnInfo]? = nil
                            if let ydata = pdict["yarns"] as? [[String: Any]] {
                                yarns = ydata.compactMap { yd in
                                    guard let nm = yd["name"] as? String,
                                          let cl = yd["color"] as? String else { return nil }
                                    return YarnInfo(name: nm, color: cl)
                                }
                            }
                            let graphicBase64 = pdict["graphicPatternBase64"] as? String
                            let pinnedNote = pdict["pinnedNote"] as? String
                            return PatternInfo(title: pt, type: tp,
                                               difficulty: pdict["difficulty"] as? String,
                                               hookSize: pdict["hookSize"] as? Double,
                                               textPattern: pdict["textPattern"] as? String,
                                               numberOfRings: pdict["numberOfRings"] as? Int,
                                               gridWidth: pdict["gridWidth"] as? Int,
                                               gridHeight: pdict["gridHeight"] as? Int,
                                               yarns: yarns,
                                               graphicPatternBase64: graphicBase64,
                                               pinnedNote: pinnedNote)
                        }
                    }
                    return PublicProject(id: doc.documentID,
                                         title: title,
                                         mainImageURL: nil,
                                         mainImageBase64: mainImageBase64,
                                         status: status,
                                         difficultyLevel: difficulty,
                                         category: category,
                                         totalCost: totalCost,
                                         username: username,
                                         userId: userId,
                                         createdAt: timestamp.dateValue(),
                                         patterns: patterns,
                                         projectDescription: projectDescription)
                }
                completion(projects)
            }
    }

    func fetchPublicProjectsForUser(userId: String, completion: @escaping ([PublicProject]) -> Void) {
        fetchPublicProjects { allProjects in
            let userProjects = allProjects.filter { $0.userId == userId }
            completion(userProjects)
        }
    }

    func fetchUserProfile(userId: String, completion: @escaping (String?, String?) -> Void) {
        db.collection("users").document(userId).getDocument { snapshot, error in
            let aboutMe = snapshot?.data()?["aboutMe"] as? String
            let avatarBase64 = snapshot?.data()?["avatarBase64"] as? String
            completion(avatarBase64, aboutMe)
        }
    }


    func savePrivateProject(_ project: Project) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        var data: [String: Any] = [
            "title": project.title,
            "status": project.status.rawValue,
            "difficultyLevel": project.difficultyLevel.rawValue,
            "category": project.category?.rawValue ?? "",
            "totalCost": project.totalCost ?? 0,
            "isPublic": project.isPublic,
            "createdAt": Timestamp(date: project.createdAt),
            "updatedAt": Timestamp(date: project.updatedAt),
            "totalTime": project.totalTime,
            "mainImageBase64": project.mainImageData?.base64EncodedString() ?? "",
            "firestoreDocumentID": project.firestoreDocumentID ?? "",
            "projectDescription": project.projectDescription ?? ""
        ]
        db.collection("users").document(userId).collection("projects").document(project.projectID.uuidString).setData(data, merge: true)
    }

    func deletePrivateProject(_ project: Project) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(userId).collection("projects").document(project.projectID.uuidString).delete()
    }

    func savePrivatePattern(_ pattern: Pattern) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        var data: [String: Any] = [
            "title": pattern.title,
            "type": pattern.type.rawValue,
            "difficultyLevel": pattern.difficultyLevel.rawValue,
            "hookSize": pattern.hookSize ?? 0,
            "textPattern": pattern.textPattern ?? "",
            "numberOfRings": pattern.numberOfRings ?? 0,
            "gridWidth": pattern.gridWidth ?? 0,
            "gridHeight": pattern.gridHeight ?? 0,
            "graphicPatternData": pattern.graphicPatternData?.base64EncodedString() ?? "",
            "createdAt": Timestamp(date: pattern.createdAt),
            "updatedAt": Timestamp(date: pattern.updatedAt),
            "currentRow": pattern.currentRow,
            "timerSeconds": pattern.timerSeconds,
            "pinnedNote": pattern.pinnedNote ?? ""
        ]
        db.collection("users").document(userId).collection("patterns").document(pattern.patternID.uuidString).setData(data, merge: true)
    }

    func deletePrivatePattern(_ pattern: Pattern) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(userId).collection("patterns").document(pattern.patternID.uuidString).delete()
    }

    func savePrivateYarn(_ yarn: Yarn) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        var data: [String: Any] = [
            "name": yarn.name,
            "color": yarn.color,
            "brand": yarn.brand ?? "",
            "material": yarn.material ?? "",
            "imageData": yarn.imageData?.base64EncodedString() ?? ""
        ]
        db.collection("users").document(userId).collection("yarns").document(yarn.yarnID.uuidString).setData(data, merge: true)
    }

    func deletePrivateYarn(_ yarn: Yarn) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(userId).collection("yarns").document(yarn.yarnID.uuidString).delete()
    }

    func fetchAllPrivateData(completion: @escaping ([Project], [Pattern], [Yarn]) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else { completion([], [], []); return }
        let group = DispatchGroup()
        var projects: [Project] = []
        var patterns: [Pattern] = []
        var yarns: [Yarn] = []

        group.enter()
        db.collection("users").document(userId).collection("projects").getDocuments { snapshot, error in
            defer { group.leave() }
            guard let docs = snapshot?.documents else { return }
            projects = docs.compactMap { doc in
                let data = doc.data()
                let project = Project(title: data["title"] as? String ?? "")
                project.projectID = UUID(uuidString: doc.documentID) ?? UUID()
                project.status = StatusType(rawValue: data["status"] as? String ?? "") ?? .inProgress
                project.difficultyLevel = DifficultyType(rawValue: data["difficultyLevel"] as? String ?? "") ?? .none
                project.category = CategoryType(rawValue: data["category"] as? String ?? "")
                project.totalCost = data["totalCost"] as? Double
                project.isPublic = data["isPublic"] as? Bool ?? false
                project.firestoreDocumentID = data["firestoreDocumentID"] as? String
                project.projectDescription = data["projectDescription"] as? String
                if let ts = data["createdAt"] as? Timestamp { project.createdAt = ts.dateValue() }
                if let ts = data["updatedAt"] as? Timestamp { project.updatedAt = ts.dateValue() }
                project.totalTime = data["totalTime"] as? TimeInterval ?? 0
                if let base64 = data["mainImageBase64"] as? String, let imgData = Data(base64Encoded: base64) {
                    project.mainImageData = imgData
                }
                return project
            }
        }

        group.enter()
        db.collection("users").document(userId).collection("patterns").getDocuments { snapshot, error in
            defer { group.leave() }
            guard let docs = snapshot?.documents else { return }
            patterns = docs.compactMap { doc in
                let data = doc.data()
                let pattern = Pattern(title: data["title"] as? String ?? "",
                                      type: PatternType(rawValue: data["type"] as? String ?? "") ?? .textEditor,
                                      difficultyLevel: DifficultyType(rawValue: data["difficultyLevel"] as? String ?? "") ?? .none)
                pattern.patternID = UUID(uuidString: doc.documentID) ?? UUID()
                pattern.hookSize = data["hookSize"] as? Double
                pattern.textPattern = data["textPattern"] as? String
                pattern.numberOfRings = data["numberOfRings"] as? Int
                pattern.gridWidth = data["gridWidth"] as? Int
                pattern.gridHeight = data["gridHeight"] as? Int
                pattern.pinnedNote = data["pinnedNote"] as? String
                if let base64 = data["graphicPatternData"] as? String, let d = Data(base64Encoded: base64) {
                    pattern.graphicPatternData = d
                }
                if let ts = data["createdAt"] as? Timestamp { pattern.createdAt = ts.dateValue() }
                if let ts = data["updatedAt"] as? Timestamp { pattern.updatedAt = ts.dateValue() }
                pattern.currentRow = data["currentRow"] as? Int ?? 0
                pattern.timerSeconds = data["timerSeconds"] as? TimeInterval ?? 0
                return pattern
            }
        }

        group.enter()
        db.collection("users").document(userId).collection("yarns").getDocuments { snapshot, error in
            defer { group.leave() }
            guard let docs = snapshot?.documents else { return }
            yarns = docs.compactMap { doc in
                let data = doc.data()
                let yarn = Yarn(name: data["name"] as? String ?? "", color: data["color"] as? String ?? "")
                yarn.yarnID = UUID(uuidString: doc.documentID) ?? UUID()
                yarn.brand = data["brand"] as? String
                yarn.material = data["material"] as? String
                if let base64 = data["imageData"] as? String, let imgData = Data(base64Encoded: base64) {
                    yarn.imageData = imgData
                }
                return yarn
            }
        }

        group.notify(queue: .main) {
            completion(projects, patterns, yarns)
        }
    }
}
