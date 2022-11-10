import XcodeProjKit
import ArgumentParser
import Foundation

struct Cmd: ParsableCommand {

    @Flag(help: "Look recursively for proj file")
    var recursive: Bool = false

    @Argument(help: "File or folder to update")
    var path: String

    @Flag(help: "Show a pod art")
    var art: Bool = false

    mutating func run() throws {
        let url = URL(fileURLWithPath: self.path)

        if art {
            printPod()
        }

        if url.pathExtension == "xcodeproj" || url.pathExtension == "pbxproj" {
            try manageXcodeProj(url)
        } else {
            try manageFolder(url)
        }
    }

    fileprivate func manageFolder(_ url: URL) throws {
        guard url.isDirectory else { return }
        for url in try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: []) {
            if url.pathExtension == "xcodeproj" || url.pathExtension == "pbxproj" {
                try manageXcodeProj(url)
            } else  if recursive {
                try manageFolder(url)
            }
        }
    }

    fileprivate func manageXcodeProj(_ url: URL) throws {
        print("🧹 Deintegrating \(url)")
        let xcodeProj = try XcodeProj(url: url)
        manageProject(xcodeProj)

        removePodDirectory()
        print("🧹 Project has been deintegrated. No traces of CocoaPods left in project.")
    }

    func manageProject(_ project: XcodeProj) {
        print("🧹 Deintegrating project \(project.projectName)")
        for target in project.project.targets {
            manageTarget(target)
        }

        deletePodsFileReferences(project)
    }

    func manageTarget(_ target: PBXTarget) {
        print(" 🧹 Deintegrating target \(target.name)")
        manageShellScriptPhase(target, "Copy Pods Resources")
        manageShellScriptPhase(target, "Check Pods Manifest.lock")
        manageShellScriptPhase(target, "Embed Pods Frameworks")
        manageUserShellScriptPhase(target)
        managePodsLibraries(target)
        manageConfigurationFileReferences(target)
    }

    func removePodDirectory() {
        // TODO: remove pod directory
    }

    func managePodsLibraries(_ target: PBXTarget) {
        let buildPhases = target.buildPhases
            .compactMap { $0 as? PBXFrameworksBuildPhase }
        // TODO: filter on regex /^(libPods.*\.a)|(Pods.*\.framework)$/i

        // print("Removing Pod libraries from build phase:")
        // TODO: remove pod libraries
    }

    func manageUserShellScriptPhase(_ target: PBXTarget) {
        let buildPhases = target.buildPhases
            .compactMap { $0 as? PBXShellScriptBuildPhase }
            .filter { $0.name?.hasPrefix("[CP-User] ") ?? false}
        for phase in buildPhases {
            // TODO: remove phase
        }
        print("  🗑 Deleted \(buildPhases.count) user build phases.")
    }

    func manageShellScriptPhase(_ target: PBXTarget, _ phaseName: String) {
        let buildPhases = target.buildPhases
            .compactMap { $0 as? PBXShellScriptBuildPhase }
            .filter { $0.name?.contains(phaseName) ?? false}
        for phase in buildPhases {
            // TODO: remove phase
        }
        print("  🗑 Deleted \(buildPhases.count) user build phases \(phaseName).")
    }

    func deleteEmptyGroup(_ project: XcodeProj, _ groupName: String) {
        guard let mainGroup = project.project.mainGroup else { return }
        let groups = mainGroup.allSubGroups
            .filter { $0.name == groupName }
            .filter { $0.isEmpty }
        for group in groups {
            // TODO: remove group
        }
        print("  🗑 Deleted \(groups.count) empty `\(groupName)` groups from project.")

    }

    func manageConfigurationFileReferences(_ target: PBXTarget) {
        /* var configFiles = target.buildConfigurationList?.buildConfigurations.compactMap( { $0.buildSettings})
         // TODO: filter on config files with name /^Pods.*\.xcconfig$/i
         if (configFiles.isEmpty) { return }
         
         
        print("Deleting configuration file references")
        for file in configFiles {
            print("  🗑 \(file.name ?? "")")
           // TODO: remove config file
        }*/
    }

    func deletePodsFileReferences(_ project: XcodeProj) {
        guard let mainGroup = project.project.mainGroup else { return }
        let groups = mainGroup.allSubGroups + [mainGroup]
        let files = groups.flatMap({ $0.fileRefs})
        // TODO: file filter on files with name= /^Pods.*\.xcconfig$/i or path= /^(libPods.*\.a)|(Pods_.*\.framework)$/i

        if files.isEmpty { return }
        print("🗑 Deleting Pod file references from project")
        for file in files {
            print("   🗑 \(file.name ?? file.path ?? "")")
            // TODO: remove file
        }

        // Delete empty `Pods` group if exists
        deleteEmptyGroup(project, "Pods")
        deleteEmptyGroup(project, "Frameworks")
    }

    func printPod() { // swiftlint:disable:this function_body_length
        // source: https://www.joereiss.net/starwars/ascii/sebulba.txt
        let pod = """
                        /H\\                 /H\\
  ,--------__,----------)-(                 )-(----------.__--------.
  |  __,--'             | /                 \\ |             `--.__  |
  | /                   | |                 | |                   \\ |
  ||..          ,---._,-(/      _            \\)-._,---.          ,,||
  |/'':.        |ID ||   ,-  _ /     ,  \\   ,_   || dI|        .:''\\|
  |    `:.__    | | ||--K-- / Y _,-=X--._>-' _>=-|| | |    __,:'    |
  /    .({})`   | | ||_  `-'   V   '   /    ^   _|| | |   '({}),    \\
 |         `:.  |_|='|_)                       (_|`=|_|  ,:'         |
 /        __,``' |___  |                       |   \\___`''.__        \\
(   __.--' |_____  _|__|                       |____ |___ _| `--.__   )
 `-'      [______[]___]_]                     [_____[]___[__]      `-'
          ,;=| `----<__|                       |  |  |  |==.
          I  |________ {                       }-<   |_/   |I
          H  | |  ___} |                       |  `-------.|H
          H----'   __=-|                       |---O--.   | H
         _U===[=====]===]                     [=====[===]===U_
        |  / :    : :  \\                       / :..  :    \\  |
        | |  :    :'    \\                     /    :..:'':  | |
        | / .`..'':.   _|                     |_ .:'     :..\\ |
        |_|'  :     :  (                       ) :  .''':   |_|
          =======U======                       ======U=======
          \\ \\ |   8| / /                       \\ \\ |8   | / /
           \\ \\ \\  8 / /                         \\ \\ 8  / / /
            >-----8o-<                           >-o8-----<
            |:|:|:|8||                           ||8|:|:|:|
            |:|:|:|8||                           ||8|:|:|:|
            |:|:|:|8o|                           |o8|:|:|:|
            |:|:|:|:8|                           |8:|:|:|:|
                    8                             8
                    8o                           o8
                     8                           8
                     8             _             8
                     8o           |_|           o8
                      8         ,<| |>.         8
                      8o      ,' /   \\ `.      o8
                       8|.  ,'   | _ |   `.  ,|8
                       8o ;:.,'| |[X]| |`..;: o8
                        8' ,'`.| |[X]| |,'`. `8
                        8o'     /,'=`.\\     `o8
                         8oo)   || : ||   (oo8
                           |8o  || V ||  o8|
                           []8 _'|[_]|`_ 8[]
                           ==8[_)`---'(_]8==
                         ,'  `   )   (   '  `.
                        /       | ___ |       \\
                        |=====  ||   ||  =====|
                        |  HH   ||   ||   HH  |
                        |__HH__ ||___|| __HH__|
                        `------' | = | `------'
                           `'    |   |    `'
                                  \\_/
"""
        print(pod)
    }
}

extension URL {
    var isDirectory: Bool {
        (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
}

extension PBXGroup {
    var allSubGroups: [PBXGroup] {
        var result = self.subGroups
        for group in result {
            result += group.allSubGroups
        }
        return result
    }

    var isEmpty: Bool {
        return false
    }
}

Cmd.main()
