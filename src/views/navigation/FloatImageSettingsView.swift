import Foundation
import PhotosUI
import SwiftUI
import UIKit

private let floatImageFilePath = "/var/mobile/Library/Preferences/com.leemin.helium.floatimage.png"

struct FloatImageSettingsSection: View {
    @State private var selectedImage: UIImage?
    @State private var imagePath: String = ""
    @State private var isEnabled = false
    @State private var imageSize = 180.0
    @State private var offsetX = 0.0
    @State private var offsetY = 0.0
    @State private var opacity = 0.85
    @State private var showingPicker = false
    @State private var statusText = NSLocalizedString("No image selected", comment: "")

    var body: some View {
        Section {
            Button(action: { showingPicker = true }) {
                Label(NSLocalizedString("Choose Image", comment: ""), systemImage: "photo")
            }

            if let image = selectedImage {
                ZStack {
                    Color.secondary.opacity(0.12)
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: CGFloat(min(imageSize, 220)), height: CGFloat(min(imageSize, 220)))
                        .opacity(opacity)
                        .offset(x: CGFloat(offsetX * 0.08), y: CGFloat(offsetY * 0.08))
                }
                .frame(height: 230)
                .frame(maxWidth: .infinity)
                .clipped()
                .cornerRadius(10)

                Text(statusText)
                    .font(.footnote)
                    .foregroundColor(.secondary)

                Toggle(NSLocalizedString("Enable Floating Image", comment: ""), isOn: Binding(
                    get: { isEnabled },
                    set: { value in
                        if value && selectedImage == nil {
                            statusText = NSLocalizedString("Choose an image first", comment: "")
                            return
                        }
                        isEnabled = value
                        saveAndNotify()
                    }
                ))

                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(NSLocalizedString("Image Size", comment: ""))
                        Spacer()
                        Text("\(Int(imageSize)) pt").foregroundColor(.secondary)
                    }
                    Slider(value: $imageSize, in: 50...600, onEditingChanged: { editing in
                        if !editing { saveAndNotify() }
                    })
                }

                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("X")
                        Spacer()
                        Text("\(Int(offsetX)) pt").foregroundColor(.secondary)
                    }
                    Slider(value: $offsetX, in: -2048...2048, onEditingChanged: { editing in
                        if !editing { saveAndNotify() }
                    })
                }

                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("Y")
                        Spacer()
                        Text("\(Int(offsetY)) pt").foregroundColor(.secondary)
                    }
                    Slider(value: $offsetY, in: -2048...2048, onEditingChanged: { editing in
                        if !editing { saveAndNotify() }
                    })
                }

                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(NSLocalizedString("Opacity", comment: ""))
                        Spacer()
                        Text("\(Int(opacity * 100))%").foregroundColor(.secondary)
                    }
                    Slider(value: $opacity, in: 0.05...1.0, onEditingChanged: { editing in
                        if !editing { saveAndNotify() }
                    })
                }

                Button(NSLocalizedString("Reset Image Parameters", comment: "")) {
                    imageSize = 180
                    offsetX = 0
                    offsetY = 0
                    opacity = 0.85
                    saveAndNotify()
                }
                .foregroundColor(.red)
            } else {
                Text(statusText)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Text(NSLocalizedString("Experimental: the image is rendered by Helium's system HUD window. Cross-app visibility depends on the current iOS/TrollStore environment.", comment: ""))
                .font(.caption)
                .foregroundColor(.secondary)
        } header: {
            Label(NSLocalizedString("Floating Image (Experimental)", comment: ""), systemImage: "photo.on.rectangle.angled")
        }
        .onAppear(perform: loadSettings)
        .sheet(isPresented: $showingPicker) {
            FloatImagePicker { image in
                importImage(image)
            }
        }
    }

    private func loadSettings() {
        let values = UserDefaults.standard.loadUserDefaults(forPath: USER_DEFAULTS_PATH)
        imagePath = values["floatImagePath"] as? String ?? floatImageFilePath
        isEnabled = values["floatImageEnabled"] as? Bool ?? false
        imageSize = values["floatImageSize"] as? Double ?? 180
        offsetX = values["floatImageX"] as? Double ?? 0
        offsetY = values["floatImageY"] as? Double ?? 0
        opacity = values["floatImageOpacity"] as? Double ?? 0.85

        if FileManager.default.fileExists(atPath: imagePath),
           let image = UIImage(contentsOfFile: imagePath) {
            selectedImage = image
            statusText = NSLocalizedString("Image loaded", comment: "")
        } else {
            isEnabled = false
            statusText = NSLocalizedString("No image selected", comment: "")
        }
    }

    private func importImage(_ sourceImage: UIImage) {
        let longestSide = max(sourceImage.size.width, sourceImage.size.height)
        let scale = min(1.0, 2048.0 / max(longestSide, 1))
        let targetSize = CGSize(width: max(1, sourceImage.size.width * scale),
                                height: max(1, sourceImage.size.height * scale))
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        let normalizedImage = renderer.image { _ in
            sourceImage.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        guard let data = normalizedImage.pngData() else {
            statusText = NSLocalizedString("Could not encode PNG image", comment: "")
            return
        }

        do {
            let directory = URL(fileURLWithPath: floatImageFilePath).deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: URL(fileURLWithPath: floatImageFilePath), options: .atomic)
            selectedImage = normalizedImage
            imagePath = floatImageFilePath
            isEnabled = true
            statusText = NSLocalizedString("Image saved", comment: "")
            saveAndNotify()
        } catch {
            statusText = error.localizedDescription
        }
    }

    private func saveAndNotify() {
        let defaults = UserDefaults.standard
        defaults.setValue(imagePath, forKey: "floatImagePath", forPath: USER_DEFAULTS_PATH)
        defaults.setValue(isEnabled, forKey: "floatImageEnabled", forPath: USER_DEFAULTS_PATH)
        defaults.setValue(imageSize, forKey: "floatImageSize", forPath: USER_DEFAULTS_PATH)
        defaults.setValue(offsetX, forKey: "floatImageX", forPath: USER_DEFAULTS_PATH)
        defaults.setValue(offsetY, forKey: "floatImageY", forPath: USER_DEFAULTS_PATH)
        defaults.setValue(opacity, forKey: "floatImageOpacity", forPath: USER_DEFAULTS_PATH)

        if isEnabled && !IsHUDEnabledBridger() {
            SetHUDEnabledBridger(true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                DarwinNotificationCenter.default.post(name: NOTIFY_RELOAD_HUD)
            }
        } else {
            DarwinNotificationCenter.default.post(name: NOTIFY_RELOAD_HUD)
        }
    }
}

private struct FloatImagePicker: UIViewControllerRepresentable {
    let onImagePicked: (UIImage) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 1
        configuration.preferredAssetRepresentationMode = .current
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: PHPickerViewController, context: Context) {}

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onImagePicked: (UIImage) -> Void

        init(onImagePicked: @escaping (UIImage) -> Void) {
            self.onImagePicked = onImagePicked
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }
            provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                guard let image = object as? UIImage, error == nil else { return }
                DispatchQueue.main.async {
                    self?.onImagePicked(image)
                }
            }
        }
    }
}
