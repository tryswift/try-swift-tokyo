import Foundation

do {
  let arguments = Array(CommandLine.arguments.dropFirst())
  let options = try BuildOptions(arguments: arguments)
  try StaticSiteBuilder(options: options).build()
  print("Built CfPWeb static site at \(options.outputDirectory.path())")
} catch {
  let message = "CfPWeb build failed: \(error.localizedDescription)\n"
  FileHandle.standardError.write(Data(message.utf8))
  exit(1)
}
