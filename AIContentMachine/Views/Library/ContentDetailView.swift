import SwiftUI
import SwiftData

struct ContentDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var project: ContentProject

    var body: some View {
        Form {
            Section("Project") {
                TextField("Title", text: $project.title)
                TextField("Topic", text: $project.topic)
                TextField("Category", text: $project.category)
                Picker("Status", selection: Binding(
                    get: { project.status },
                    set: { project.status = $0 }
                )) {
                    ForEach(ProjectStatus.allCases) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
            }

            Section("Core Copy") {
                TextField("Overview", text: $project.overview, axis: .vertical)
                TextField("Hook", text: $project.hook, axis: .vertical)
                TextField("Caption", text: $project.caption, axis: .vertical)
                TextField("CTA", text: $project.cta, axis: .vertical)
            }

            Section("Script") {
                TextEditor(text: $project.script)
                    .frame(minHeight: 180)
                TextEditor(text: $project.voiceover)
                    .frame(minHeight: 120)
            }

            Section("Lists") {
                TextEditor(text: Binding(
                    get: { project.hashtags.joined(separator: " ") },
                    set: { project.hashtags = $0.split(separator: " ").map(String.init) }
                ))
                .frame(minHeight: 100)

                TextEditor(text: Binding(
                    get: { project.shotList.joined(separator: "\n") },
                    set: { project.shotList = $0.split(separator: "\n").map(String.init) }
                ))
                .frame(minHeight: 120)
            }

            Section("Notes") {
                TextEditor(text: $project.notes)
                    .frame(minHeight: 120)
            }
        }
        .scrollContentBackground(.hidden)
        .background(PremiumBackground())
        .navigationTitle("Content Detail")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    project.updatedAt = .now
                    try? modelContext.save()
                }
            }
        }
    }
}
