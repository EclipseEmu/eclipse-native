import SwiftUI
import EclipseKit

struct SaveFileExportTarget {
    var document: SaveFileDocument?
    var callback: ((Result<URL, any Error>) -> Void)?
}

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var filteredTags: Set<TagObject> = []
    @Published var filteredSystems: Set<System> = Set(System.concreteCases)

    @Published var selection: Set<GameObject> = []
    @Published var isSelecting: Bool = false

    @Published var gameCheatsTarget: GameObject?
    @Published var gameSettingsTarget: GameObject?
    @Published var gameSaveStatesTarget: GameObject?
    @Published var manageTagsTarget: TagsPickerTarget?
    @Published var coverPickerMethod: CoverPickerMethod?

    @Published var fileImportRequest: FileImportRequest?
    @Published var fileExportRequest: SaveFileExportTarget = .init()

    @Published var isTagsViewOpen: Bool = false
    @Published var isFiltersViewOpen: Bool = false
    @Published var isDeleteGamesConfirmationOpen: Bool = false

    var areSystemsFiltered: Bool {
        filteredSystems.count != System.concreteCases.count
    }

    func predicate(for query: String) -> NSPredicate? {
        var predicates: [NSPredicate] = []

        if !query.isEmpty {
            predicates.append(NSPredicate(format: "name CONTAINS[d] %@", query))
        }

        predicates.append(
            NSCompoundPredicate(orPredicateWithSubpredicates: filteredSystems.map {
                NSPredicate(format: "rawSystem = %d", $0.rawValue)
            })
        )

        for tag in filteredTags {
            predicates.append(NSPredicate(format: "ANY tags == %@", tag))
        }

        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    @inlinable
    static func getSortDescriptors(settings: Settings) -> [NSSortDescriptor] {
        Self.getSortDescriptors(for: settings.listSortDirection, method: settings.listSortMethod)
    }
    
    @inlinable
    static func getSortDescriptors() -> [NSSortDescriptor] {
        LibraryViewModel.getSortDescriptors(for: Settings.getSortDirection(), method: Settings.getSortMethod())
    }

    static func getSortDescriptors(for direction: GameListSortingDirection, method: GameListSortingMethod) -> [NSSortDescriptor] {
        let isAscending = direction == .ascending
        return switch method {
        case .name: [NSSortDescriptor(keyPath: \GameObject.name, ascending: isAscending)]
        case .dateAdded: [NSSortDescriptor(keyPath: \GameObject.dateAdded, ascending: isAscending)]
        }
    }
    
    func handleFileExport(_ result: Result<URL, any Error>) -> Void {
        fileExportRequest.callback?(result)
        fileExportRequest.callback = nil
    }
}
