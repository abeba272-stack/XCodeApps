import SwiftUI

struct CopyButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: "doc.on.doc")
        }
        .buttonStyle(AppQuietButtonStyle())
    }
}
