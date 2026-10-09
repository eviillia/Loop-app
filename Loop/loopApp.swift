import SwiftUI
import Firebase
import FirebaseAuth
import SwiftData

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct loopApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    let container: ModelContainer

    init() {
        do {
            let storeURL = URL.documentsDirectory.appending(path: "default.store")
            let config = ModelConfiguration(url: storeURL)
            container = try ModelContainer(for: User.self, Project.self, Pattern.self, Yarn.self,
                                           configurations: config)
        } catch {
            fatalError("Не удалось создать ModelContainer: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(container)
        }
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var authVM = AuthViewModel()
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                SplashView()
            } else if authVM.isAuthenticated {
                MainView()
                    .environmentObject(authVM)
            } else {
                LoginView()
                    .environmentObject(authVM)
            }
        }
        .onAppear {
            authVM.configure(with: modelContext)
            checkAuthState()
            isLoading = false
        }
    }

    private func checkAuthState() {
        let fetchDescriptor = FetchDescriptor<User>()
        let localUsers = (try? modelContext.fetch(fetchDescriptor)) ?? []

        if Auth.auth().currentUser != nil, !localUsers.isEmpty {
            authVM.isAuthenticated = true
        } else {
            try? Auth.auth().signOut()
            authVM.isAuthenticated = false
        }
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            Color("backgroundColor").ignoresSafeArea()
            ProgressView()
                .scaleEffect(1.5)
        }
    }
}
