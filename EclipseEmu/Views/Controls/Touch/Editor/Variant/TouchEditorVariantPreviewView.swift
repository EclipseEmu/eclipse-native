#if canImport(UIKit)
import SwiftUI
import EclipseKit

struct TouchEditorVariantPreviewView: View {
	@ObservedObject private var viewModel: TouchEditorViewModel
	@Binding private var variant: TouchMappings.Variant
	private let namingConvention: ControlNamingConvention
	private let allInputs: [CoreInput]
	private let screenAspectRatio: CGFloat

	private var previewSize: CGSize {
		switch variant.sizing {
		case .any: .init(width: 390, height: 390)
		case .landscapeCompact: .init(width: 844, height: 390)
		case .landscapeRegular: .init(width: 1024, height: 768)
		case .portraitCompact: .init(width: 390, height: 844)
		case .portraitRegular: .init(width: 768, height: 1024)
		}
	}

	init(viewModel: TouchEditorViewModel, variant: Binding<TouchMappings.Variant>) {
		self.viewModel = viewModel
		self._variant = variant
		self.namingConvention = viewModel.namingConvention

		var allInputs: [CoreInput] = []
		for button in viewModel.mappings.buttons {
			allInputs.append(button.input)
		}
		self.allInputs = allInputs

		self.screenAspectRatio = CGFloat(viewModel.system.screenAspectRatio)
	}

	var body: some View {
		let previewSize = self.previewSize
		GeometryReader { proxy in
			let scale = Self.scaleToFit(previewSize, in: proxy.size)
			Color.clear
				.overlay {
					Canvas(renderer: renderer) {
						Image(systemName: "house.circle").foregroundStyle(.white).tag("house.circle")
						ForEach(allInputs, id: \.rawValue) { input in
							let (_, image) = input.label(for: namingConvention)
							Image(systemName: image).foregroundStyle(.white).tag(image)
						}
					}
					.background(.black)
					.foregroundStyle(.white)
					.frame(width: previewSize.width, height: previewSize.height)
					.clipShape(RoundedRectangle(cornerRadius: 8.0 * 1 / scale))
					.scaleEffect(scale)
				}
		}
	}

    private func renderer(context: inout GraphicsContext, size: CGSize) {
		let screenRect = getScreenRect(in: size)
		var screenPath = Path()
		screenPath.addRect(screenRect)
		context.fill(screenPath, with: .color(Color(uiColor: .darkGray)))

		for element in variant.elements {
			let rect = element.rect.resolve(in: size, padding: 16.0)
			switch element.control {
			case .button(let i):
				let (_, image) = viewModel.label(for: .button(i))
				guard let symbol = context.resolveSymbol(id: image) else { continue }
				let scale = Self.scaleToFit(symbol.size, in: rect.size) * 0.875
				context.draw(symbol, in: CGRect(
					x: rect.minX,
					y: rect.minY,
					width: symbol.size.width * scale,
					height: symbol.size.height * scale
				))
				break
			case .directional(let i):
				let directionalPad = viewModel.mappings.directionals[i]
				switch directionalPad.style {
				case .joystick:
					var foregroundRect = rect.applying(.init(scaleX: 0.5, y: 0.5))
					foregroundRect.origin = CGPoint(x: rect.minX + (rect.width / 4), y: rect.minY + (rect.height / 4))
					let background = Circle().path(in: rect)
					let foreground = Circle().path(in: foregroundRect)
					context.stroke(background, with: .foreground, style: .init(lineWidth: 4.0))
					context.stroke(foreground, with: .foreground, style: .init(lineWidth: 4.0))
					break
				case .dpad:
					var path = Path()

					let segmentWidth = rect.width / 3

					let segmentMinX = rect.minX
					let segmentMidX = segmentMinX + segmentWidth
					let segmentModX = segmentMidX + segmentWidth
					let segmentMaxX = rect.maxX

					let segmentMinY = rect.minY
					let segmentMidY = segmentMinY + segmentWidth
					let segmentModY = segmentMidY + segmentWidth
					let segmentMaxY = rect.maxY

					path.move(to: CGPoint(x: segmentMidX, y: segmentMinY))
					path.addLine(to: CGPoint(x: segmentModX, y: segmentMinY))
					path.addLine(to: CGPoint(x: segmentModX, y: segmentMidY))
					path.addLine(to: CGPoint(x: segmentMaxX, y: segmentMidY))
					path.addLine(to: CGPoint(x: segmentMaxX, y: segmentModY))
					path.addLine(to: CGPoint(x: segmentModX, y: segmentModY))
					path.addLine(to: CGPoint(x: segmentModX, y: segmentMaxY))
					path.addLine(to: CGPoint(x: segmentMidX, y: segmentMaxY))
					path.addLine(to: CGPoint(x: segmentMidX, y: segmentModY))
					path.addLine(to: CGPoint(x: segmentMinX, y: segmentModY))
					path.addLine(to: CGPoint(x: segmentMinX, y: segmentMidY))
					path.addLine(to: CGPoint(x: segmentMidX, y: segmentMidY))
					path.addLine(to: CGPoint(x: segmentMidX, y: segmentMinY))

					context.stroke(path, with: .foreground, style: .init(lineWidth: 4.0))
					break
				}
			}
		}

		let menuRect = variant.menu.resolve(in: size, padding: 16.0)
		if let symbol = context.resolveSymbol(id: "house.circle") {
			let scale = Self.scaleToFit(symbol.size, in: menuRect.size) * 0.875
			context.draw(symbol, in: CGRect(
				x: menuRect.minX,
				y: menuRect.minY,
				width: symbol.size.width * scale,
				height: symbol.size.height * scale
			))
		}
	}

	private func getScreenRect(in size: CGSize) -> CGRect {
		let center = CGPoint(x: size.width / 2, y: size.height / 2)

		let screenOffset = variant.screenOffset
		let screenSize = CGSize(width: 50 * screenAspectRatio, height: 50)

		let screenScale = Self.scaleToFit(screenSize, in: size)
		let scaledScreenSize = screenSize.applying(.init(scaleX: screenScale, y: screenScale))

		let screenCenter = center.applying(.init(translationX: CGFloat(screenOffset.x), y: CGFloat(screenOffset.y)))

		return CGRect(
			x: screenCenter.x - (scaledScreenSize.width / 2),
			y: screenCenter.y - (scaledScreenSize.height / 2),
			width: scaledScreenSize.width,
			height: scaledScreenSize.height
		)
	}

	private static func scaleToFit(_ size: CGSize, in container: CGSize) -> CGFloat {
		return min(container.width / size.width, container.height / size.height)
	}
}
#endif
