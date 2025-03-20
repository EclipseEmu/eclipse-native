import SwiftUI

struct ContentUnavailableLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack {
            configuration.icon
                .font(.system(size: 48.0, weight: .bold))
                .foregroundStyle(.secondary)
                .padding(.bottom, 8.0)
            configuration.title
                .font(.title2.weight(.bold))
        }
    }
}

struct ContentUnavailableMessage<Label: View, Description: View, Action: View>: View {
    private let label: () -> Label
    private let description: () -> Description
    private let actions: () -> Action

    @ViewBuilder
    static func search(text: String) -> some View {
        if #available(iOS 17.0, macOS 14.0, *) {
            ContentUnavailableView.search(text: text)
        } else {
            ContentUnavailableMessage<SwiftUI.Label, Text, EmptyView> {
                SwiftUI.Label("No Results for \"\(text)\"", systemImage: "magnifyingglass")
            } description: {
                Text("Check the spelling or try a new search.")
            } actions: {
                EmptyView()
            }
        }
    }

    init(
        @ViewBuilder label: @escaping () -> Label,
        @ViewBuilder description: @escaping () -> Description = { EmptyView() },
        @ViewBuilder actions: @escaping () -> Action = { EmptyView() }
    ) {
        self.label = label
        self.description = description
        self.actions = actions
    }

    var body: some View {
        if #available(iOS 17.0, macOS 14.0, *) {
            ContentUnavailableView(
                label: label,
                description: description,
                actions: actions
            )
        } else {
            VStack(alignment: .center) {
                Spacer()
                self.label()
                    .labelStyle(ContentUnavailableLabelStyle())
                self.description()
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                self.actions()
                Spacer()
            }
        }
    }
}

#Preview {
    ContentUnavailableMessage {
        Label("Warning", systemImage: "exclamationmark.triangle.fill")
    } description: {
        Text("Something went wrong loading that data.")
    }
}
