import SwiftUI
import FirebaseFirestore


struct PublicProjectDetailView: View {
    
    let project: PublicProject

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            Color("backgroundColor")
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {

                    if let userId = project.userId,
                       !userId.isEmpty {

                        NavigationLink {
                            UserProfileView(
                                userId: userId,
                                username: project.username
                            )
                        } label: {
                            Text("Автор: \(project.username)")
                                .font(.headline)
                                .foregroundColor(Color("textColor"))
                                .frame(
                                    maxWidth: .infinity,
                                    alignment: .leading
                                )
                                .padding(.horizontal)
                        }
                        .buttonStyle(.plain)
                    }

                    if let base64 = project.mainImageBase64,
                       let data = Data(base64Encoded: base64),
                       let uiImage = UIImage(data: data) {

                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .clipShape(
                                RoundedRectangle(cornerRadius: 15)
                            )
                            .padding(.horizontal)

                    } else {

                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 200)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.white)
                            )
                            .padding(.horizontal)
                    }

                    VStack(alignment: .leading, spacing: 10) {

                        Text(project.title)
                            .font(.largeTitle.bold())

                        if let category = project.category,
                           !category.isEmpty {

                            Text("Категория: \(category)")
                                .font(.subheadline)
                        }

                        if let desc = project.projectDescription,
                           !desc.isEmpty {

                            VStack(alignment: .leading, spacing: 6) {

                                Text("Описание")
                                    .font(.headline)
                                    .foregroundColor(Color("textColor"))

                                Text(desc)
                                    .font(.body)
                                    .foregroundColor(
                                        Color("textColor")
                                            .opacity(0.8)
                                    )
                            }
                            .padding()
                            .frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(
                                        Color("backgroundColor")
                                            .opacity(0.15)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(
                                                Color("textColor")
                                                    .opacity(0.5),
                                                lineWidth: 1
                                            )
                                    )
                            )
                            .padding(.horizontal)
                        }

                        Text(
                            "Создан: \(project.createdAt.formatted(date: .long, time: .shortened))"
                        )
                        .font(.caption)

                    }
                    .foregroundColor(Color("textColor"))
                    .padding(.horizontal)
                    
                    if let patterns = project.patterns,
                       !patterns.isEmpty {

                        VStack(alignment: .leading, spacing: 12) {

                            Text("Детали")
                                .font(.title2.bold())
                                .padding(.horizontal)

                            ForEach(
                                Array(patterns.enumerated()),
                                id: \.offset
                            ) { index, patternInfo in

                                patternNavigationLink(
                                    index: index,
                                    patternInfo: patternInfo,
                                    patterns: patterns
                                )
                            }
                        }
                    }

                    Spacer(minLength: 20)
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Проект")
    }

    private func patternRowContent(
        index: Int,
        patternInfo: PatternInfo
    ) -> some View {

        VStack(alignment: .leading, spacing: 4) {

            Text("\(index + 1). \(patternInfo.title)")
                .font(.headline)

            Text(patternInfo.type)

            if let text = patternInfo.textPattern {

                Text(text)
                    .font(.caption)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    Color("textColor").opacity(0.5),
                    lineWidth: 1
                )
        )
    }

    private func patternNavigationLink(
        index: Int,
        patternInfo: PatternInfo,
        patterns: [PatternInfo]
    ) -> some View {

        NavigationLink(
            destination: PublicPatternDetailView(
                patternInfo: patternInfo,
                allPatterns: patterns,
                currentIndex: index,
                projectTitle: project.title
            )
        ) {
            patternRowContent(
                index: index,
                patternInfo: patternInfo
            )
        }
        .foregroundColor(Color("textColor"))
        .padding(.horizontal)
    }
}
