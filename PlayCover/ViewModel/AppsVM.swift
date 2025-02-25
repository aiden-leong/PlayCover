//
//  AppViewModel.swift
//  PlayCover
//

import Cocoa
import Foundation

class AppsVM: ObservableObject {

    static let shared = AppsVM()

    private init() {
        PlayTools.installOnSystem()
        fetchApps()
    }

    @Published var apps: [PlayApp] = []
    @Published var updatingApps = false

    func fetchApps() {
        Task {
            var result: [PlayApp] = []
            do {
                let containers = try AppContainer.containers()
                let directoryContents = try FileManager.default
                    .contentsOfDirectory(at: PlayTools.playCoverContainer, includingPropertiesForKeys: nil, options: [])

                let subdirs = directoryContents.filter { $0.hasDirectoryPath }

                for sub in subdirs {
                    if sub.pathExtension.contains("app") &&
                        FileManager.default.fileExists(atPath: sub.appendingPathComponent("Info")
                                                                  .appendingPathExtension("plist")
                                                                  .path) {
                        let app = PlayApp(appUrl: sub)
                        if let container = containers[app.info.bundleIdentifier] {
                            app.container = container
                            print("Application installed under:", sub.path)
                        }
                        result.append(app)
                    }
                }

            } catch let error as NSError {
                print(error)
            }

            await updateApps(result)
        }
    }

    @MainActor func updateApps(_ newApps: [PlayApp]) {
        self.apps.removeAll()
        var filteredApps = newApps

        if !uif.searchText.isEmpty {
            filteredApps = newApps.filter({ $0.searchText.contains(uif.searchText.lowercased()) })
        }

        self.apps.append(contentsOf: filteredApps)
    }
}
