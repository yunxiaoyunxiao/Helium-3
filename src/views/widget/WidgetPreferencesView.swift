//
//  WidgetPreferencesView.swift
//  Helium UI
//
//  Created by lemin on 10/18/23.
//

import Foundation
import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import UIKit

struct WidgetPreferencesView: View {
    @ObservedObject var widgetManager: WidgetManager
    @State var widgetSet: WidgetSetStruct
    @Binding var widgetID: WidgetIDStruct
    
    @State var text: String = ""
    @State var weatherFormat: String = ""
    @State var intSelection: Int = 0
    @State var intSelection2: Int = 0
    @State var intSelection3: Int = 1
    @State var boolSelection: Bool = false
    
    @State var modified: Bool = false
    @State private var isPresented = false
    @State private var showingImagePicker = false
    @State private var imageSize = 180.0
    @State private var imageX = 0.0
    @State private var imageY = 0.0
    @State private var imageOpacity = 0.85
    @State private var imageEnabled = true
    @State private var imageStatus = NSLocalizedString("No image selected", comment: "")
    @State private var selectedFloatingImage: UIImage? = nil
    
    let timeFormats: [String] = [
        "hh:mm",
        "hh:mm a",
        "hh:mm:ss",
        "hh",
        
        "HH:mm",
        "HH:mm:ss",
        "HH",
        
        "mm",
        "ss"
    ]
    
    let dateFormatter = DateFormatter()
    let currentDate = Date()
    
    var body: some View {
        VStack {
            // MARK: Preview
            WidgetPreviewsView(widget: $widgetID, previewColor: .white)
            
            switch (widgetID.module) {
            case .dateWidget:
                // MARK: Date Format Textbox
                HStack {
                    Text(NSLocalizedString("Date Format", comment:""))
                        .foregroundColor(.primary)
                        .bold()
                    Spacer()
                    TextField(NSLocalizedString("E MMM dd", comment:""), text: $text)
                        .frame(maxWidth: 120)
                        .multilineTextAlignment(.trailing)
                        .onAppear {
                            if let format = widgetID.config["dateFormat"] as? String {
                                text = format
                            } else {
                                text = NSLocalizedString("E MMM dd", comment:"")
                            }
                        }
                }
            case .network:
                // MARK: Network Type Choice
                VStack {
                    HStack {
                        Text(NSLocalizedString("Network Type", comment:"")).foregroundColor(.primary).bold()
                        Spacer()
                        Picker(selection: $intSelection) {
                            Text(NSLocalizedString("Download", comment:"")).tag(0)
                            Text(NSLocalizedString("Upload", comment:"")).tag(1)
                        } label: {}
                        .pickerStyle(.menu)
                        .onAppear {
                            if let netUp = widgetID.config["isUp"] as? Bool {
                                intSelection = netUp ? 1 : 0
                            } else {
                                intSelection = 0
                            }
                        }
                    }
                    // MARK: Speed Icon Choice
                    HStack {
                        Text(NSLocalizedString("Speed Icon", comment:"")).foregroundColor(.primary).bold()
                        Spacer()
                        Picker(selection: $intSelection2) {
                            Text(intSelection == 0 ? "▼" : "▲").tag(0)
                            Text(intSelection == 0 ? "↓" : "↑").tag(1)
                        } label: {}
                        .pickerStyle(.menu)
                        .onAppear {
                            if let speedIcon = widgetID.config["speedIcon"] as? Int {
                                intSelection2 = speedIcon
                            } else {
                                intSelection2 = 0
                            }
                        }
                    }
                    // MARK: Minimum Unit Choice
                    HStack {
                        Text(NSLocalizedString("Minimum Unit", comment:"")).foregroundColor(.primary).bold()
                        Spacer()
                        Picker(selection: $intSelection3) {
                            Text("b").tag(0)
                            Text("Kb").tag(1)
                            Text("Mb").tag(2)
                            Text("Gb").tag(3)
                        } label: {}
                        .pickerStyle(.menu)
                        .onAppear {
                            if let minUnit = widgetID.config["minUnit"] as? Int {
                                intSelection3 = minUnit
                            } else {
                                intSelection3 = 1
                            }
                        }
                    }
                    // MARK: Hide Speed When Zero
                    Toggle(isOn: $boolSelection) {
                        Text(NSLocalizedString("Hide Speed When 0", comment:""))
                            .foregroundColor(.primary)
                            .bold()
                    }
                    .onAppear {
                        boolSelection = widgetID.config["hideSpeedWhenZero"] as? Bool ?? false
                    }
                }
            case .temperature:
                // MARK: Battery Temperature Value
                HStack {
                    Text(NSLocalizedString("Temperature Unit", comment:"")).foregroundColor(.primary).bold()
                    Spacer()
                    Picker(selection: $intSelection) {
                        Text(NSLocalizedString("Celcius", comment:"")).tag(0)
                        Text(NSLocalizedString("Fahrenheit", comment:"")).tag(1)
                    } label: {}
                        .pickerStyle(.menu)
                        .onAppear {
                            if widgetID.config["useFahrenheit"] as? Bool ?? false == true {
                                intSelection = 1
                            } else {
                                intSelection = 0
                            }
                        }
                }
            case .battery:
                // MARK: Battery Value Type
                HStack {
                    Text(NSLocalizedString("Battery Option", comment:"")).foregroundColor(.primary).bold()
                    Spacer()
                    Picker(selection: $intSelection) {
                        Text(NSLocalizedString("Watts", comment:"")).tag(0)
                        Text(NSLocalizedString("Charging Current", comment:"")).tag(1)
                        Text(NSLocalizedString("Amperage", comment:"")).tag(2)
                        Text(NSLocalizedString("Charge Cycles", comment:"")).tag(3)
                    } label: {}
                    .pickerStyle(.menu)
                    .onAppear {
                        if let batteryType = widgetID.config["batteryValueType"] as? Int {
                            intSelection = batteryType
                        } else {
                            intSelection = 0
                        }
                    }
                }
            case .timeWidget:
                // MARK: Time Format Selector
                HStack {
                    Picker(selection: $intSelection, label: Text(NSLocalizedString("Time Format", comment:"")).foregroundColor(.primary).bold()) {
                        ForEach(0..<timeFormats.count, id: \.self) { index in
                            Text("\(getFormattedDate(timeFormats[index]))\n(\(timeFormats[index]))").tag(index)
                        }
                    }
                    .onAppear {
                        if let timeFormat = widgetID.config["dateFormat"] as? String {
                            intSelection = timeFormats.firstIndex(of: timeFormat) ?? 0
                        } else {
                            intSelection = 0
                        }
                    }
                }
            case .textWidget:
                // MARK: Custom Text Label Textbox
                HStack {
                    Text(NSLocalizedString("Label Text", comment:""))
                        .foregroundColor(.primary)
                        .bold()
                    Spacer()
                    TextField(NSLocalizedString("Example", comment:""), text: $text)
                        .frame(maxWidth: 120)
                        .multilineTextAlignment(.trailing)
                        .onAppear {
                            if let format = widgetID.config["text"] as? String {
                                text = format
                            } else {
                                text = NSLocalizedString("Example", comment:"")
                            }
                        }
                }
            case .currentCapacity:
                // MARK: Current Capacity Choice
                HStack {
                    Toggle(isOn: $boolSelection) {
                        Text(NSLocalizedString("Show Percent (%) Symbol", comment:""))
                            .foregroundColor(.primary)
                            .bold()
                    }
                    .onAppear {
                        boolSelection = widgetID.config["showPercentage"] as? Bool ?? true
                    }
                }
            case .chargeSymbol:
                // MARK: Charge Symbol Fill Option
                HStack {
                    Toggle(isOn: $boolSelection) {
                        Text(NSLocalizedString("Fill Symbol", comment:""))
                            .foregroundColor(.primary)
                            .bold()
                    }
                    .onAppear {
                        boolSelection = widgetID.config["filled"] as? Bool ?? true
                    }
                }
            case .floatingImage:
                VStack(alignment: .leading, spacing: 14) {
                    Button(action: { showingImagePicker = true }) {
                        Label(NSLocalizedString("Choose Image", comment: ""), systemImage: "photo")
                    }
                    if let image = floatingImageForDisplay {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 220)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(imageStatus).foregroundColor(.secondary)
                    }
                    Toggle(NSLocalizedString("Enable Floating Image", comment: ""), isOn: $imageEnabled)
                    VStack(alignment: .leading) {
                        Text("\(NSLocalizedString("Image Size", comment: "")): \(Int(imageSize)) pt")
                        Slider(value: $imageSize, in: 40...700)
                    }
                    VStack(alignment: .leading) {
                        Text("X: \(Int(imageX)) pt")
                        Slider(value: $imageX, in: -2048...2048)
                    }
                    VStack(alignment: .leading) {
                        Text("Y: \(Int(imageY)) pt")
                        Slider(value: $imageY, in: -2048...2048)
                    }
                    VStack(alignment: .leading) {
                        Text("\(NSLocalizedString("Opacity", comment: "")): \(Int(imageOpacity * 100))%")
                        Slider(value: $imageOpacity, in: 0.05...1.0)
                    }
                    Text(NSLocalizedString("Each widget set stores its own image and display parameters.", comment: ""))
                        .font(.caption).foregroundColor(.secondary)
                }
                .onAppear {
                    imageSize = widgetID.config["imageSize"] as? Double ?? 180
                    imageX = widgetID.config["imageX"] as? Double ?? 0
                    imageY = widgetID.config["imageY"] as? Double ?? 0
                    imageOpacity = widgetID.config["imageOpacity"] as? Double ?? 0.85
                    imageEnabled = widgetID.config["imageEnabled"] as? Bool ?? true
                    selectedFloatingImage = nil
                    if let data = widgetID.config["imageData"] as? Data {
                        selectedFloatingImage = UIImage(data: data)
                        imageStatus = selectedFloatingImage == nil
                            ? NSLocalizedString("Saved image data could not be decoded", comment: "")
                            : NSLocalizedString("Image saved", comment: "")
                    } else if let path = widgetID.config["imagePath"] as? String {
                        selectedFloatingImage = UIImage(contentsOfFile: path)
                        imageStatus = selectedFloatingImage == nil
                            ? NSLocalizedString("Saved image could not be loaded", comment: "")
                            : NSLocalizedString("Image saved", comment: "")
                    } else {
                        imageStatus = NSLocalizedString("No image selected", comment: "")
                    }
                }
            case .weather:
                ScrollView(.vertical, showsIndicators: false) {
                    VStack {
                        HStack {
                            Text(NSLocalizedString("Location", comment:""))
                                .foregroundColor(.primary)
                                .bold()
                            Spacer()
                            TextField(NSLocalizedString("Input", comment:""), text: $text)
                                .frame(maxWidth: 240)
                                .multilineTextAlignment(.trailing)
                                .onAppear {
                                    if let format = widgetID.config["location"] as? String {
                                        text = format
                                    } else {
                                        text = "110000"
                                    }
                                }
                            Button(NSLocalizedString("Get", comment:"")) {
                                isPresented = true
                            }
                            .sheet(isPresented: $isPresented) {
                                WeatherLocationView(locationID: self.$text)
                            }
                        }

                        HStack {
                            Text(NSLocalizedString("Format", comment:""))
                                .foregroundColor(.primary)
                                .bold()
                            Spacer()
                            TextField("{i}{n} {nt}°~{dt}° ({t}°)💧{h}%", text: $weatherFormat)
                                .frame(maxWidth: 240)
                                .multilineTextAlignment(.trailing)
                                .onAppear {
                                    if let format = widgetID.config["format"] as? String {
                                        weatherFormat = format
                                    } else {
                                        weatherFormat = "{i}{n} {nt}°~{dt}° ({t}°)💧{h}%"
                                    }
                                }
                        }
                        HStack {
                            Text(NSLocalizedString("Weather Format Now", comment:""))
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }
                        Text("\n")
                        HStack {
                            Text(NSLocalizedString("Weather Format Today", comment:""))
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }
                    }
                }
            // default:
            //     Text(NSLocalizedString("No Configurable Aspects", comment:""))
            }
        }
        .padding(.horizontal, 15)
        .sheet(isPresented: $showingImagePicker) {
            FloatImagePicker(
                onImagePicked: { image in
                    let longestSide = max(image.size.width, image.size.height)
                    let factor = min(1.0, 2048.0 / max(longestSide, 1))
                    let size = CGSize(width: max(1, image.size.width * factor), height: max(1, image.size.height * factor))
                    let renderer = UIGraphicsImageRenderer(size: size)
                    let normalized = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
                    guard let data = normalized.pngData(),
                          let savedImage = UIImage(data: data) else {
                        imageStatus = NSLocalizedString("Could not encode the selected image", comment: "")
                        return
                    }
                    // Store image bytes inside this widget's own persisted config.
                    // This avoids sandbox-inaccessible absolute paths and keeps the image
                    // available to both the app UI and the injected HUD process.
                    widgetID.config["imageData"] = data
                    widgetID.config.removeValue(forKey: "imagePath")
                    selectedFloatingImage = savedImage
                    imageStatus = NSLocalizedString("Image saved", comment: "")
                    modified = true
                    saveChanges()
                    ensureFloatingImageHUDIsRunning()
                },
                onError: { imageStatus = $0 }
            )
        }
        .onChange(of: imageSize) { _ in persistFloatingImageSettings() }
        .onChange(of: imageX) { _ in persistFloatingImageSettings() }
        .onChange(of: imageY) { _ in persistFloatingImageSettings() }
        .onChange(of: imageOpacity) { _ in persistFloatingImageSettings() }
        .onChange(of: imageEnabled) { _ in persistFloatingImageSettings() }
        .toolbar {
            HStack {
                // MARK: Save Button
                // only shows up if something is changed
                if (modified) {
                    Button(action: {
                        saveChanges()
                    }) {
                        Image(systemName: "checkmark.circle")
                    }
                }
            }
        }
        .onDisappear {
            if modified {
                UIApplication.shared.confirmAlert(title: NSLocalizedString("Save Changes", comment:""), body: NSLocalizedString("Would you like to save changes to the widget?", comment:""), onOK: {
                    saveChanges()
                }, noCancel: false)
            }
        }
        .onChange(of: text) { _ in
            modified = true
        }
        .onChange(of: weatherFormat) { _ in
            modified = true
        }
        .onChange(of: intSelection) { _ in
            modified = true
        }
        .onChange(of: intSelection2) { _ in
            modified = true
        }
        .onChange(of: intSelection3) { _ in
            modified = true
        }
        .onChange(of: boolSelection) { _ in
            modified = true
        }
    }
    
    // Always resolve the preview from the live widget binding first.
    // SwiftUI may recreate this navigation destination and reset @State,
    // while the persisted image bytes remain in the widget's config.
    private var floatingImageForDisplay: UIImage? {
        if let image = selectedFloatingImage { return image }
        if let data = widgetID.config["imageData"] as? Data,
           let image = UIImage(data: data) {
            return image
        }
        if let path = widgetID.config["imagePath"] as? String {
            return UIImage(contentsOfFile: path)
        }
        return nil
    }

    private func persistFloatingImageSettings() {
        guard widgetID.module == .floatingImage else { return }
        widgetID.config["imageSize"] = imageSize
        widgetID.config["imageX"] = imageX
        widgetID.config["imageY"] = imageY
        widgetID.config["imageOpacity"] = imageOpacity
        widgetID.config["imageEnabled"] = imageEnabled
        widgetManager.updateWidgetConfig(widgetSet: widgetSet, id: widgetID, newID: widgetID)
        if imageEnabled {
            ensureFloatingImageHUDIsRunning()
        } else {
            DarwinNotificationCenter.default.post(name: NOTIFY_RELOAD_HUD)
        }
    }

    // Preserve the standalone feature's HUD startup behavior after migration.
    private func ensureFloatingImageHUDIsRunning() {
        guard imageEnabled else { return }
        if !IsHUDEnabledBridger() {
            SetHUDEnabledBridger(true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                DarwinNotificationCenter.default.post(name: NOTIFY_RELOAD_HUD)
            }
        } else {
            DarwinNotificationCenter.default.post(name: NOTIFY_RELOAD_HUD)
        }
    }

    func getFormattedDate(_ format: String) -> String {
        let locale = UserDefaults.standard.string(forKey: "dateLocale", forPath: USER_DEFAULTS_PATH) ?? "en_US"
        dateFormatter.locale = Locale(identifier: locale)
        dateFormatter.dateFormat = format
        // dateFormatter.locale = Locale(identifier: NSLocalizedString("en_US", comment:""))
        return dateFormatter.string(from: currentDate)
    }
    
    func saveChanges() {
        var widgetStruct: WidgetIDStruct = .init(module: widgetID.module, config: widgetID.config)
        
        switch(widgetStruct.module) {
        // MARK: Changing Text
        case .dateWidget:
            // MARK: Date Format Handling
            if text == "" {
                widgetStruct.config["dateFormat"] = nil
            } else {
                widgetStruct.config["dateFormat"] = text
            }
        case .textWidget:
            // MARK: Custom Text Handling
            if text == "" {
                widgetStruct.config["text"] = nil
            } else {
                widgetStruct.config["text"] = text
            }
        
        // MARK: Changing Integer
        case .network:
            // MARK: Network Choices Handling
            widgetStruct.config["isUp"] = intSelection == 1 ? true : false
            widgetStruct.config["speedIcon"] = intSelection2
            widgetStruct.config["minUnit"] = intSelection3
            widgetStruct.config["hideSpeedWhenZero"] = boolSelection
        case .temperature:
            // MARK: Temperature Unit Handling
            widgetStruct.config["useFahrenheit"] = intSelection == 1 ? true : false
        case .battery:
            // MARK: Battery Value Type Handling
            widgetStruct.config["batteryValueType"] = intSelection
        case .timeWidget:
            // MARK: Time Format Handling
            widgetStruct.config["dateFormat"] = timeFormats[intSelection]
        // MARK: Changing Boolean
        case .currentCapacity:
            // MARK: Current Capacity Handling
            widgetStruct.config["showPercentage"] = boolSelection
        case .chargeSymbol:
            // MARK: Charge Symbol Fill Handling
            widgetStruct.config["filled"] = boolSelection
        case .floatingImage:
            widgetStruct.config["imageSize"] = imageSize
            widgetStruct.config["imageX"] = imageX
            widgetStruct.config["imageY"] = imageY
            widgetStruct.config["imageOpacity"] = imageOpacity
            widgetStruct.config["imageEnabled"] = imageEnabled
        case .weather:
            // MARK: Weather Handling
            if text == "" {
                widgetStruct.config["location"] = nil
            } else {
                widgetStruct.config["location"] = text
            }
            if weatherFormat == "" {
                widgetStruct.config["format"] = nil
            } else {
                widgetStruct.config["format"] = weatherFormat
            }
        // default:
        //     return;
        }
        
        widgetManager.updateWidgetConfig(widgetSet: widgetSet, id: widgetID, newID: widgetStruct)
        widgetID.config = widgetStruct.config
        modified = false
    }
}

struct WeatherLocationView: View {
    @State var searchString = ""
    @Binding var locationID: String
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    @State var locations: [Location] = []
    
    var body: some View {
        NavigationView{
            VStack {
                SearchBarUIView(text: $searchString, search: search, placeHolder: NSLocalizedString("Input Location Name", comment:""))
                Spacer()
                List(locations) {location in
                    ListCell(item: location)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            locationID = location.id
                            presentationMode.wrappedValue.dismiss()
                        }
                }
                .listStyle(PlainListStyle())
                .padding(.vertical, 0)
                .navigationBarTitle(Text(NSLocalizedString("Get Location ID", comment:"")))
                .resignKeyboardOnDragGesture()
            }
        }
    }

    func search() {
        if !searchString.isEmpty {
            let dateLocale = UserDefaults.standard.string(forKey: "dateLocale", forPath: USER_DEFAULTS_PATH) ?? "en_US"
            let apiKey = UserDefaults.standard.string(forKey: "apiKey", forPath: USER_DEFAULTS_PATH) ?? ""
            let data = WeatherUtils.fetchLocationID(forName:searchString, apiKey:apiKey, dateLocale:dateLocale)
            let json = try! JSONSerialization.jsonObject(with: data!, options: []) as! Dictionary<String, Any>
            if json["code"] as? String == "200" {
                let array = json["location"] as! [Dictionary<String, Any>]
                for item in array {
                    let name = item["name"] as! String
                    let id = item["id"] as! String
                    let country = item["country"] as! String
                    let adm1 = item["adm1"] as! String
                    let adm2 = item["adm2"] as! String
                    let lat = item["lat"] as! String
                    let lon = item["lon"] as! String
                    locations.append(Location(id: id, name: name, country: country, adm1: adm1, adm2: adm2, lat: lat, lon: lon))
                }
            }
        }
    }
}

struct SearchBarUIView: UIViewRepresentable {
    @Binding var text: String
    let placeHolder: String?
    var search: () -> Void
    init(text: Binding<String>, search: @escaping () -> Void, placeHolder: String? = nil) {
        self._text = text
        self.placeHolder = placeHolder
        self.search = search
    }
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, searchAction: search)
    }
    
    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar()
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = context.coordinator
        if let placeHolder = self.placeHolder {
            searchBar.placeholder = placeHolder
        }
        return searchBar
    }
    func updateUIView(_ uiView: UISearchBar, context: Context) {
        
    }
    class Coordinator: NSObject, UISearchBarDelegate {
        @Binding var text: String
        var search: () -> Void
        public init(text: Binding<String>, searchAction: @escaping () -> Void) {
            self._text = text
            search = searchAction
        }
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            self.text = searchText
        }
        func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
            searchBar.showsCancelButton = false
        }
        func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
            searchBar.showsCancelButton = true
        }
        func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
            searchBar.showsCancelButton = false
            searchBar.searchTextField.endEditing(true)
            self.text = ""
            searchBar.searchTextField.text = ""
        }
        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            search()
            UIApplication.shared.endEditing(true)
        }
    }
}

struct ListCell: View {
    var item: Location
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(item.id),\(item.name)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
            }
            HStack {
                Text("\(item.adm1),\(item.adm2)")
                    .lineLimit(1)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
    }
}

// Update for iOS 15
// MARK: - UIApplication extension for resgning keyboard on pressing the cancel buttion of the search bar
extension UIApplication {
    /// Resigns the keyboard.
    ///
    /// Used for resigning the keyboard when pressing the cancel button in a searchbar based on [this](https://stackoverflow.com/a/58473985/3687284) solution.
    /// - Parameter force: set true to resign the keyboard.
    func endEditing(_ force: Bool) {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let window = windowScene?.windows.first
        window?.endEditing(force)
    }
}

struct ResignKeyboardOnDragGesture: ViewModifier {
    var gesture = DragGesture().onChanged{_ in
        UIApplication.shared.endEditing(true)
    }
    func body(content: Content) -> some View {
        content.gesture(gesture)
    }
}

extension View {
    func resignKeyboardOnDragGesture() -> some View {
        return modifier(ResignKeyboardOnDragGesture())
    }
}

struct Location: Identifiable {
    var id: String
    var name: String
    var country: String
    var adm1: String
    var adm2: String
    var lat: String
    var lon: String
}