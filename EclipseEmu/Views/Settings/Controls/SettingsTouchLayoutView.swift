#if os(iOS)
import SwiftUI

fileprivate final class ControlModel: Identifiable, ObservableObject {
    var id: UUID = .init()
    @Published var width: Double
    @Published var height: Double
    @Published var location: CGPoint
    @Published var xOrigin: Double = 0
    @Published var yOrigin: Double = 0
    @Published var label: String

    init(label: String, location: CGPoint, width: Double, height: Double) {
        self.location = location
        self.label = label
        self.width = width
        self.height = height
    }
}

fileprivate struct Line: Shape {
    var axis: Axis

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: .init(x: 0, y: 0))
        path.addLine(to: axis == .vertical ? .init(x: 0, y: rect.height) : .init(x: rect.width, y: 0))
        return path
    }
}

fileprivate struct Grabber: View {
    enum Side: Equatable {
        case top
        case bottom
        case left
        case right
    }

    let side: Side
    let xOffset: CGFloat
    let yOffset: CGFloat

    init(side: Side) {
        self.side = side

        self.xOffset = if side == .right {
            6
        } else if side == .left {
            -6
        } else {
            0
        }

        self.yOffset = if side == .bottom {
            6
        } else if side == .top {
            -6
        } else {
            0
        }
    }

    var drag: some Gesture {
        DragGesture()
            .onChanged { _ in
                switch self.side {
                case .top:
                    break
                case .bottom:
                    break
                case .right:
                    break
                case .left:
                    break
                }
            }
    }

    var body: some View {
        Circle()
            .stroke(.white)
            .background(Circle().foregroundStyle(.tint))
            .frame(width: 12, height: 12)
            .offset(x: xOffset, y: yOffset)
            .gesture(drag)
            .hoverEffect(.highlight)
    }
}

fileprivate struct ControlView: View {
    @ObservedObject var model: ControlModel
    @Binding var selection: ControlModel?
    @Binding var editorSelection: ControlModel?
    @GestureState private var fingerLocation: CGPoint?
    @GestureState private var startLocation: CGPoint?

    var simpleDrag: some Gesture {
        DragGesture()
            .onChanged { value in
                var newLocation = self.startLocation ?? self.model.location
                newLocation.x += value.translation.width
                newLocation.y += value.translation.height
                self.model.location = newLocation
            }
            .updating($startLocation) { _, startLocation, _ in
                self.selection = self.model
                startLocation = startLocation ?? model.location
            }
    }

    var fingerDrag: some Gesture {
        DragGesture()
            .updating($fingerLocation) { value, fingerLocation, _ in
                fingerLocation = value.location
            }
    }

    var body: some View {
        ZStack {
            Rectangle()
                .foregroundStyle(.black)
            Text(model.label)
                .fontWeight(.semibold)
                .modify {
                    if #available(iOS 16.1, *) {
                        $0.fontDesign(.rounded)
                    } else {
                        $0
                    }
                }
            Rectangle()
                .stroke(lineWidth: 2)
        }
        .compositingGroup()
        .frame(width: model.width, height: model.height)
        .overlay {
            if selection?.id == self.model.id {
                ZStack {
                    HStack {
                        Grabber(side: .left)
                        Spacer()
                        Grabber(side: .right)
                    }
                    VStack {
                        Grabber(side: .top)
                        Spacer()
                        Grabber(side: .bottom)
                    }
                }
            }
        }
        .position(model.location)
        .gesture(
            simpleDrag.simultaneously(with: fingerDrag)
        )
        .onTapGesture {
            self.selection = self.model
        }
        .onLongPressGesture {
            self.selection = self.model
            self.editorSelection = self.model
        }
    }
}

fileprivate struct ControlEditView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var control: ControlModel

    var body: some View {
        NavigationStack {
            Form {
                Text("\(control.label)")
                Text("\(control.location.debugDescription)")
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SettingsTouchLayoutView: View {
    @Environment(\.dismiss) var dismiss
    @State private var editorSelection: ControlModel?
    @State private var selection: ControlModel?
    @State private var controls: [ControlModel] = [
        .init(label: "A", location: CGPoint(x: 100, y: 50), width: 50, height: 50),
        .init(label: "B", location: CGPoint(x: 50, y: 100), width: 50, height: 50)
    ]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ZStack {
                    Line(axis: .vertical)
                        .stroke(style: .init(lineWidth: 1, dash: [8]))
                        .frame(width: 1)
                    Line(axis: .horizontal)
                        .stroke(style: .init(lineWidth: 1, dash: [8]))
                        .frame(height: 1)
                }
                .compositingGroup()
                .foregroundStyle(.gray)
                .opacity(0.5)

                ForEach(self.controls) { control in
                    ControlView(model: control, selection: $selection, editorSelection: $editorSelection)
                }

                HStack(spacing: 16.0) {
                    Button {
                        dismiss()
                    } label: {
                        Label("Cancel", systemImage: "xmark")
                    }
                    .padding(8.0)
                    .imageScale(.small)
                    .labelStyle(.iconOnly)
                    .background(.quaternary)
                    .tint(.secondary)
                    .font(.body.weight(.semibold))
                    .clipShape(Circle())

                    Button {} label: {
                        Label("Add", systemImage: "plus")
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                }
                .padding(8.0)
                .background(Material.thick)
                .clipShape(RoundedRectangle(cornerRadius: .infinity))
                .position(.init(x: proxy.size.width / 2, y: proxy.size.height - proxy.safeAreaInsets.bottom - 16.0))
            }
        }
        .contentShape(Rectangle())
        .padding()
        .onTapGesture {
            self.selection = nil
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .background(.black, ignoresSafeAreaEdges: .all)
        .preferredColorScheme(.dark)
        .tabBarHidden()
        .sheet(item: $editorSelection) { control in
            ControlEditView(control: control)
                .presentationDetents([.medium])
        }
    }
}

#Preview {
    SettingsTouchLayoutView()
}
#endif
