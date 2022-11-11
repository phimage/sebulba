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

        removePodDirectory(url)
        try xcodeProj.write(to: url)
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
        print(" 🎯 Deintegrating target \(target.name)")

        _ = target.buildPhases.flatMap({$0.files}).compactMap({$0.fileRef}) // just force loading if issue with link

        manageShellScriptPhase(target, "Copy Pods Resources")
        manageShellScriptPhase(target, "Check Pods Manifest.lock")
        manageShellScriptPhase(target, "Embed Pods Frameworks")
        manageUserShellScriptPhase(target)

        managePodsLibraries(target)
        manageConfigurationFileReferences(target)
    }

    func removePodDirectory(_ url: URL) {
        if url.isDirectory {
            let podDirectory = url.deletingLastPathComponent().appendingPathComponent("Pods")
            try? FileManager.default.removeItem(at: podDirectory)
        } // else? maybe pbxproj passed? ignore?
    }

    func managePodsLibraries(_ target: PBXTarget) {
        let buildPhases = target.buildPhases
            .compactMap { $0 as? PBXFrameworksBuildPhase }

        var buildFiles = buildPhases.flatMap({$0.files})
        buildFiles = buildFiles.filter {
            (($0.fileRef?.name?.hasPrefix("libPods") ?? false) && ($0.fileRef?.name?.hasSuffix( ".a") ?? false))
            || (($0.fileRef?.name?.hasPrefix( "Pods") ?? false) && ($0.fileRef?.name?.hasSuffix(".framework") ?? false))
        }
        if buildFiles.isEmpty {
            return
        }
        print("Removing Pod libraries from build phase:")

        for file in buildFiles {
            file.fileRef?.remove()
            file.remove()
            print("  🗑 \(file.fileRef?.name ?? "")")
        }
        print("   ↳ Deleted \(buildFiles.count) build files.")
    }

    func manageUserShellScriptPhase(_ target: PBXTarget) {
        let buildPhases = target.buildPhases
            .compactMap { $0 as? PBXShellScriptBuildPhase }
            .filter { $0.name?.hasPrefix("[CP-User] ") ?? false}
        for phase in buildPhases {
            phase.remove()
            print("  🗑 \(phase.name ?? "")")
        }
        print("   ↳ Deleted \(buildPhases.count) user build phases.")
    }

    func manageShellScriptPhase(_ target: PBXTarget, _ phaseName: String) {
        let buildPhases = target.buildPhases
            .compactMap { $0 as? PBXShellScriptBuildPhase }
            .filter { $0.name?.contains(phaseName) ?? false}
        for phase in buildPhases {
            phase.remove()
            print("  🗑 \(phase.name ?? "")")
        }
        print("   ↳ Deleted \(buildPhases.count) user build phases \(phaseName).")
    }

    func deleteEmptyGroup(_ project: XcodeProj, _ groupName: String) {
        guard let mainGroup = project.project.mainGroup else { return }
        let groups = mainGroup.allSubGroups
            .filter { $0.name == groupName }
            .filter { $0.children.isEmpty }
        for group in groups {
            group.remove()
            print("  🗑 \(group.name ?? "")")
        }
        print("   ↳ Deleted \(groups.count) empty `\(groupName)` groups from project.")

    }

    func manageConfigurationFileReferences(_ target: PBXTarget) {
        let configFiles = target.buildConfigurationList?.buildConfigurations.compactMap { $0.baseConfigurationReference }
            .filter { ($0.name?.hasPrefix( "Pods.") ?? false) && ($0.name?.hasSuffix(".xcconfig") ?? false) } ?? []

        if configFiles.isEmpty { return }

        print("Deleting configuration file references")
        for file in configFiles {
            print("  🗑 \(file.name ?? "")")
            file.remove()
        }
    }

    func deletePodsFileReferences(_ project: XcodeProj) {
        guard let mainGroup = project.project.mainGroup else { return }
        let groups = mainGroup.allSubGroups + [mainGroup]
        let files = groups.flatMap({ $0.fileRefs})
            .filter { (($0.name?.hasPrefix("Pods") ?? false) && ($0.name?.hasSuffix( ".xcconfig") ?? false))
                || (($0.path?.hasPrefix("libPods") ?? false) && ($0.path?.hasSuffix( ".a") ?? false))
                || (($0.path?.hasPrefix( "Pods_") ?? false) && ($0.path?.hasSuffix(".framework") ?? false)) }

        if files.isEmpty { return }

        let buildFiles = project.objects.dict.values.compactMap { $0 as? PBXBuildFile }
        _ = project.objects.dict.values.compactMap { $0 as? PBXTarget }.map { $0.productReference } // force load ref

        print("📄 Deleting Pod file references from project")
        for fileRef in files {
            print("   🗑 \(fileRef.name ?? fileRef.path ?? "")")
            _ = buildFiles.filter { $0.fileRef?.ref == fileRef.ref }.map { $0.remove() }
            fileRef.remove()
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
}

Cmd.main()
