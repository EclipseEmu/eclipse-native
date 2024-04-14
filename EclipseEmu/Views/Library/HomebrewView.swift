import SwiftUI

struct HomebrewSection: Decodable, Identifiable {
    var id = UUID()
    var system: String
    var games: [HomebrewGame]
    
    private enum CodingKeys: String, CodingKey {
        case system, games
    }
}

struct HomebrewGame: Decodable, Identifiable {
    var id = UUID()
    var name: String
    var link: URL?
    var boxart: URL?
    var system: String
    
    private enum CodingKeys: String, CodingKey {
        case name, link, boxart, system
    }
}

enum HomebrewResponse {
    case loading
    case success([HomebrewSection])
    case failure(Error)
}

struct HomebrewView: View {
    @State var response: HomebrewResponse = .loading
    
    var body: some View {
        ZStack {
            switch response {
            case .loading:
                ProgressView()
            case .success(let sections):
                List {
                    ForEach(sections) { section in
                        Section(section.system) {
                            ForEach(section.games) { game in
                                HStack(alignment: .center) {
                                    AsyncImage(url: game.boxart) { phase in
                                        if let image = phase.image {
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                        } else if phase.error != nil {
                                            Image(systemName: "questionmark.diamond")
                                                .imageScale(.large)
                                        } else {
                                            ProgressView()
                                        }
                                    }
                                    .frame(width: 44, height: 44)
                                    
                                    VStack(alignment: .leading) {
                                        Text(game.name)
                                        Text(game.system)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Button {
                                        print("add", game)
                                    } label: {
                                        Label("Add Game", systemImage: "plus")
                                    }
                                    .disabled(game.link == nil)
                                    .labelStyle(.iconOnly)
                                    .buttonStyle(.bordered)
                                    .modify {
                                        if #available(iOS 17.0, macOS 14.0, *) {
                                            $0.buttonBorderShape(.circle)
                                        } else {
                                            $0
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            case .failure(let error):
                VStack {
                    Text("Failed to load homebrew games")
                    Text(error.localizedDescription)
                }
            }
        }
        .navigationTitle("Homebrew")
        .task {
            await self.loadGames()
        }
        .refreshable {
            await self.loadGames()
        }
    }
    
    func loadGames() async {
        do {
            guard let homebrewUrl = URL(string: "https://eclipseemu.me/homebrew.json") else {
                preconditionFailure("failed to create homebrew URL")
            }
            let (data, _) = try await URLSession.shared.data(from: homebrewUrl)
            let sections = try JSONDecoder().decode([HomebrewSection].self, from: data)
            self.response = .success(sections)
        } catch {
            print(error)
            self.response = .failure(error)
        }
    }
}

#Preview {
    HomebrewView()
}
