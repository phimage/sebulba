import XcodeProjKit
import ArgumentParser
import Foundation

struct Cmd: ParsableCommand {

    @Option(name: .long, help: "option")
    var option: String?

    @Flag(help: "flag")
    var flag: Bool = false

    @Argument(help: "args")
    var args: String

    mutating func run() throws {
        let url = URL(fileURLWithPath: self.args)

    }

}

Cmd.main()
