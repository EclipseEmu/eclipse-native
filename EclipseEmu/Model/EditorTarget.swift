import SwiftUI
import EclipseKit
import GameController

enum EditorTarget<Item: Hashable>: Hashable {
    case create
    case edit(Item)

    func hash(into hasher: inout Hasher) {
        switch self {
        case .create:
            true.hash(into: &hasher)
        case .edit(let item):
            item.hash(into: &hasher)
        }
    }

	static func == (lhs: Self, rhs: Self) -> Bool {
		switch (lhs, rhs) {
		case (.create, .create): true
		case (.edit(let lhs), .edit(let rhs)): lhs == rhs
		default: false
		}
	}
}

extension EditorTarget: Identifiable {
	var id: Item? {
		if case .edit(let item) = self {
			item
		} else {
			nil
		}
	}
}
