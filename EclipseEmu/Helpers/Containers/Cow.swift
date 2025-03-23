/// A copy-on-write container.
struct Cow<T> {
    private var ref: Box<T>

    var value: T {
        get { ref.value }
        set {
            if !isKnownUniquelyReferenced(&ref) {
                ref = Box(newValue)
                return
            }
            ref.value = newValue
        }
    }
}
