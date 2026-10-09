import SwiftUI
import FirebaseAuth

struct SignInView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.modelContext) private var modelContext

    @State private var email = ""
    @State private var password = ""
    @State private var nickname = ""
    @State private var isPasswordVisible = false

    var body: some View {
        NavigationView {
            ZStack {
                Color("backgroundColor").ignoresSafeArea()

                VStack(spacing: 25) {
                    VStack {
                        Image(systemName: "person.fill.badge.plus")
                            .resizable()
                            .frame(width: 115, height: 80)
                            .foregroundColor(Color("textColor"))
                            .padding(20)
                        Text("Добро пожаловать!")
                            .foregroundStyle(Color("textColor"))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                    }
                    .offset(y: -30)

                    VStack(spacing: 15) {
                        TextField("Ник", text: $nickname)
                            .textContentType(.nickname)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color("backgroundColor").opacity(0.15))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(Color("textColor").opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .foregroundStyle(Color("textColor"))

                        TextField("Электронная почта", text: $email)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color("backgroundColor").opacity(0.15))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(Color("textColor").opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .foregroundStyle(Color("textColor"))

                        HStack {
                            if isPasswordVisible {
                                TextField("Пароль", text: $password)
                            } else {
                                SecureField("Пароль", text: $password)
                            }
                            Button(action: { isPasswordVisible.toggle() }) {
                                Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(Color("textColor").opacity(0.7))
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color("backgroundColor").opacity(0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color("textColor").opacity(0.3), lineWidth: 1)
                                )
                        )
                        .foregroundStyle(Color("textColor"))
                    }
                    .padding(.horizontal)

                    Button(action: {
                        authVM.signUp(email: email, password: password, username: nickname)
                    }) {
                        Text("Зарегистрироваться")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(Color("textColor"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color("backgroundColor").opacity(0.15))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(Color("textColor").opacity(0.5), lineWidth: 1)
                                    )
                            )
                    }
                    .padding(.horizontal)

                    NavigationLink(destination: LoginView()) {
                        Text("Уже есть аккаунт? Войти")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color("textColor").opacity(0.8))
                    }
                    .padding(.top, 20)

                    if let error = authVM.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.top, 10)
                    }
                }
                .padding()
            }
            .onAppear {
                authVM.configure(with: modelContext)
            }
        }
        .navigationViewStyle(.stack)
    }
}

