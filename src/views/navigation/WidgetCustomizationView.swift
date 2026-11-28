//
//  WidgetCustomizationView.swift
//
//
//  Created by lemin on 10/13/23.
//

import Foundation
import SwiftUI

// MARK: Widget Customization View
struct WidgetCustomizationView: View {
    @StateObject var widgetManager: WidgetManager = .init()
    @State private var pendingDeleteIDs: Set<UUID> = []
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        NavigationView {
            VStack {
                // List of Widget Sets
                List {
                    ForEach($widgetManager.widgetSets) { widgetSet in
                        NavigationLink(destination: EditWidgetSetView(widgetManager: widgetManager, widgetSet: widgetSet.wrappedValue)) {
                            Text(widgetSet.title.wrappedValue)
                        }
                    }
                    .onDelete { indexSet in
                        pendingDeleteIDs = Set(indexSet.compactMap { index in
                            widgetManager.widgetSets.indices.contains(index) ? widgetManager.widgetSets[index].id : nil
                        })
                        showingDeleteConfirmation = !pendingDeleteIDs.isEmpty
                    }
                }
                .toolbar {
                    HStack {
                        // create a new widget set
                        Button(action: {
                            UIApplication.shared.inputAlert(title: NSLocalizedString("Enter Name", comment:""), body: NSLocalizedString("Choose a name for the widget set.", comment:""), confirmTitle: NSLocalizedString("Confirm", comment:""), placeholder: NSLocalizedString("Name", comment:""), onOK: { title in
                                // make selection for anchor
                                UIApplication.shared.optionsAlert(title: NSLocalizedString("Choose Side", comment:""), body: NSLocalizedString("Choose a side for the widget set to anchor to. This can be changed later.", comment:""), options: [NSLocalizedString("Left", comment:""), NSLocalizedString("Center", comment:""), NSLocalizedString("Right", comment:"")]) { anchorSide in
                                    var anchor: Int
                                    switch (anchorSide) {
                                    case NSLocalizedString("Left", comment:""):
                                        anchor = 0
                                        break
                                    case NSLocalizedString("Center", comment:""):
                                        anchor = 1
                                        break
                                    case NSLocalizedString("Right", comment:""):
                                        anchor = 2
                                        break
                                    default:
                                        anchor = 0
                                        break
                                    }
                                    widgetManager.createWidgetSet(title: title == "" ? NSLocalizedString("Untitled", comment:"") : title, anchor: anchor)
                                }
                            }, noCancel: false)
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .navigationTitle(Text(NSLocalizedString("Customize", comment:"")))
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .alert(isPresented: $showingDeleteConfirmation) {
            Alert(
                title: Text(NSLocalizedString("Delete Widget Set", comment: "")),
                message: Text(NSLocalizedString("Are you sure you want to delete the selected widget set(s)?", comment: "")),
                primaryButton: .destructive(Text(NSLocalizedString("Delete", comment: ""))) {
                    widgetManager.widgetSets.removeAll { pendingDeleteIDs.contains($0.id) }
                    widgetManager.saveWidgetSets()
                    pendingDeleteIDs.removeAll()
                },
                secondaryButton: .cancel {
                    pendingDeleteIDs.removeAll()
                }
            )
        }
    }
}

// MARK: Widget Modify View
//struct WidgetModifyView: View {
//    @StateObject var widgetManager: WidgetManager
//    @Binding var widgetIndex: Int
//    
//    var dismiss: () -> Void
//    
//    var body: some View {
//        return VStack {
//            if widgetIndex >= 0 && widgetIndex < widgetManager.widgetStructs.count {
//                // Widget Preferences
//                WidgetPreferencesView(widgetStruct: $widgetManager.widgetStructs[widgetIndex])
//                VStack {
//                    Spacer()
//                    // Save Button
//                    Button("Save") {
//                        widgetManager.saveWidgetStructs()
//                        dismiss()
//                    }
//                    .buttonStyle(TintedButton(color: .blue, fullWidth: true))
//                    .padding(.horizontal, 7)
//                    // Delete Button
//                    Button("Delete") {
//                        widgetManager.removeWidget(id: widgetIndex)
//                        dismiss()
//                    }
//                    .buttonStyle(TintedButton(color: .red, fullWidth: true))
//                    .padding(.horizontal, 7)
//                }
//                .padding(10)
//            }
//        }
//    }
//}

// MARK: Widget Add View
struct WidgetAddView: View {
    @Binding var isOpen: Bool
    @State private var showingFloatImageSettings = false
    
    var onChoice: (WidgetModule) -> ()
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(WidgetModule.allCases, id: \.self) { id in
                        Button(action: {
                            isOpen = false
                            onChoice(id)
                        }) {
                            WidgetChoiceView(widgetName: WidgetDetails.getWidgetName(id), exampleText: WidgetDetails.getWidgetExample(id))
                        }
                    }
                } header: {
                    Text(NSLocalizedString("Widgets", comment: ""))
                }
                
                Section {
                    NavigationLink(destination: FloatImageSettingsView()) {
                        WidgetChoiceView(
                            widgetName: NSLocalizedString("Floating Image", comment: ""),
                            exampleText: "🖼️"
                        )
                    }
                } header: {
                    Text(NSLocalizedString("Additional Features", comment: ""))
                }
            }
            .navigationTitle(Text(NSLocalizedString("Add Widget", comment: "")))
            .navigationBarItems(trailing: Button(NSLocalizedString("Done", comment: "")) {
                isOpen = false
            })
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: Widget Choice View
struct WidgetChoiceView: View {
    var widgetName: String
    var exampleText: String

    var body: some View {
        HStack {
            ZStack {
                if let wallpaper = UIImage(named: "wallpaper") {
                    Image(uiImage: wallpaper)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .scaleEffect(1.5)
                        .frame(width: 125, height: 50)
                        .cornerRadius(12)
                        .clipped()
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color.gray.opacity(0.12), Color.gray.opacity(0.24)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 125, height: 50)
                }
                ZStack {
                    Text(exampleText)
                        .padding(.vertical, 5)
                        .foregroundColor(.white)
                }
                .frame(width: 125, height: 50)
            }
            .padding(.trailing, 5)
            Text(widgetName)
                .foregroundColor(.primary)
                .bold()
        }
    }
}

struct WidgetCustomizationView_Previews: PreviewProvider {
    static var previews: some View {
        WidgetCustomizationView()
    }
}
