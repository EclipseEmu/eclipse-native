struct OwnedCheat: Identifiable, Equatable, Hashable {
    let id: ObjectIdentifier
    let code: String?
    let enabled: Bool
    let label: String?
    let priority: Int16
    let type: String?

    init(cheat: CheatObject) {
        self.id = cheat.id
        self.code = cheat.code
        self.enabled = cheat.enabled
        self.label = cheat.label
        self.priority = cheat.priority
        self.type = cheat.type
    }
}
