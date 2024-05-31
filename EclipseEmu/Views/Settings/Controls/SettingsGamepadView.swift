import EclipseKit
import GameController
import SwiftUI

struct SettingsGamepadView: View {
    var controller: GCController

    var body: some View {
        Form {
            if controller.extendedGamepad != nil {
                Section("Misc") {
                    Label("Start Button", systemImage: "plus.circle")
                    Label("Select Button", systemImage: "minus.circle")
                    Label("Menu Button", systemImage: "line.3.horizontal.circle")
                }
                Section("Face Buttons") {
                    Label("A Button", systemImage: "a.circle")
                    Label("B Button", systemImage: "b.circle")
                }
                Section("Shoulder Buttons") {
                    Label("L Button", systemImage: "l.button.roundedbottom.horizontal")
                    Label("R Button", systemImage: "r.button.roundedbottom.horizontal")
                }
                Section("D-Pad") {
                    Label("Up", systemImage: "dpad.up.filled")
                    Label("Down", systemImage: "dpad.down.filled")
                    Label("Left", systemImage: "dpad.left.filled")
                    Label("Right", systemImage: "dpad.right.filled")
                }
            } else {
                Text("Controller does not support the extended gamepad profile.")
            }
        }.navigationTitle(controller.vendorName ?? "Controller")
    }
}
