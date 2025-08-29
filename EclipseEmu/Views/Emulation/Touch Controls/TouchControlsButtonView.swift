#if canImport(UIKit)
import UIKit

final class TouchControlsButtonView: UIView {
	let id: Int
	let button: TouchMappings.Button
	let image: UIImageView

	public var isActive: Bool = false {
		didSet {
			setActive(newValue: isActive)
		}
	}

	init(id: Int, button: TouchMappings.Button, namingConvention: ControlNamingConvention) {
		self.id = id
		self.button = button

		let (label, systemImage) = button.input.label(for: namingConvention)
		image = UIImageView(image: UIImage(systemName: systemImage) ?? UIImage(systemName: "circle.dashed"))
		image.accessibilityLabel = label
		image.tintColor = .white

        super.init(frame: .zero)

		if !button.visible {
			self.layer.opacity = 0.0
		}

		isUserInteractionEnabled = false
		clipsToBounds = true

		image.layer.shadowColor = UIColor.black.cgColor
		image.layer.shadowRadius = 3.0
		image.layer.shadowOpacity = 1.0
		image.layer.shadowOffset = CGSize(width: 0, height: 0)
		image.layer.masksToBounds = false

        addSubview(image)
        image.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            image.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            image.centerYAnchor.constraint(equalTo: self.centerYAnchor),
        ])
		setActive(newValue: false)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

	private func setActive(newValue: Bool) {
        let scale = isActive ? 0.9 : 1.0
		CATransaction.begin()
		self.backgroundColor = UIColor.white.withAlphaComponent(isActive ? 0.5 : 0)
		image.transform = .identity.scaledBy(x: scale, y: scale)
		CATransaction.commit()
	}

    override func layoutSubviews() {
        super.layoutSubviews()
		let size = self.frame.height * 0.625
		let config = UIImage.SymbolConfiguration(font: .systemFont(ofSize: size))
		image.preferredSymbolConfiguration = config
        self.layer.cornerRadius = self.frame.height / 2
    }
}
#endif
