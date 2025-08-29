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

@available(iOS, deprecated: 17.0, renamed: "ContentUnavailableView", message: "This is a polyfill of ContentUnavailableView.")
@available(macOS, deprecated: 15.0, renamed: "ContentUnavailableView", message: "This is a polyfill of ContentUnavailableView.")
struct ContentUnavailableMessage<Label: View, Description: View, Action: View>: View {
    private let label: () -> Label
    private let description: () -> Description
    private let actions: () -> Action

    init(
        @ViewBuilder label: @escaping () -> Label,
        @ViewBuilder description: @escaping () -> Description = { EmptyView() },
        @ViewBuilder actions: @escaping () -> Action = { EmptyView() }
    ) {
        self.label = label
        self.description = description
        self.actions = actions
    }
    
    init(
        _ titleKey: LocalizedStringKey,
        systemImage: String,
        @ViewBuilder description: @escaping () -> Description
    ) where Label == SwiftUI.Label<Text, Image>, Action == EmptyView {
        self.label = { Label(titleKey, systemImage: systemImage) }
        self.description = description
        self.actions = { EmptyView() }
    }
    
    init(_ titleKey: LocalizedStringKey, systemImage: String)
    where Label == SwiftUI.Label<Text, Image>, Description == EmptyView, Action == EmptyView
    {
        self.label = { Label(titleKey, systemImage: systemImage) }
        self.description = { EmptyView() }
        self.actions = { EmptyView() }
    }
    
    init(
        _ titleKey: LocalizedStringKey,
        systemImage: String,
        description: LocalizedStringKey
    ) where Label == SwiftUI.Label<Text, Image>, Description == Text, Action == EmptyView {
        self.label = { Label(titleKey, systemImage: systemImage) }
        self.description = { Text(description) }
        self.actions = { EmptyView() }
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

extension ContentUnavailableMessage
where
    Label == SwiftUI.Label<Text, Image>,
    Description == Text,
    Action == EmptyView
{

    @ViewBuilder
    static func search(text: String) -> some View {
        if #available(iOS 17.0, macOS 14.0, *) {
            ContentUnavailableView.search(text: text)
        } else {
            Self("NO_RESULTS_TITLE \"\(text)\"", systemImage: "magnifyingglass", description: "NO_RESULTS_MESSAGE")
        }
    }

    static func error(error: some LocalizedError) -> ContentUnavailableMessage {
        ContentUnavailableMessage("GENERIC_ERROR_MESSAGE_TITLE", systemImage: "exclamationmark.triangle") {
            Text(verbatim: error.errorDescription, fallback: "GENERIC_ERROR_MESSAGE_UNKNOWN_ERROR")
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
