import SwiftUI
import EclipseKit

struct PlayerOrderChangeRequest: Identifiable {
    var id = UUID()
    var maxPlayers: UInt8
    var players: [GameInputCoordinator.Player]
    
    var finish: ([GameInputCoordinator.Player]) -> Void
    
    init(maxPlayers: UInt8, players: [GameInputCoordinator.Player], continuation: @escaping ([GameInputCoordinator.Player]) -> Void) {
        self.maxPlayers = maxPlayers
        self.players = players
        self.finish = continuation
    }
}

struct ReorderControllersView: View {
    @State var request: PlayerOrderChangeRequest

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(request.players.enumerated()), id: \.element.id) { (i, player) in
                    HStack(alignment: .center) {
                        Label(player.displayName, systemImage: player.sfSymbol)
                        Spacer()
                        if i < request.maxPlayers {
                            Text("Player \(i + 1)")
                        }
                    }
                }
                .onMove { fromOffset, toOffset in
                    request.players.move(fromOffsets: fromOffset, toOffset: toOffset)
                }
            }
            .navigationTitle("Reorder Controllers")
            #if os(iOS)
            .environment(\.editMode, .constant(EditMode.active))
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: DismissButton.placement) {
                    DismissButton()
                }
            }
        }
        .presentationDetents([.medium])
        .onDisappear {
            request.finish(request.players)
        }
    }
}

#Preview {
    VStack {}.sheet(isPresented: .constant(true)) {
        ReorderControllersView(request:
            PlayerOrderChangeRequest(maxPlayers: 4, players: [
                .init(kind: .keyboard(.init(.init()), .init())),
                .init(kind: .keyboard(.init(.init()), .init())),
                .init(kind: .keyboard(.init(.init()), .init())),
                .init(kind: .keyboard(.init(.init()), .init())),
                .init(kind: .gamepad(.init(.init()), .init()))
            ]) {
                print($0)
            }
        )
    }
}
