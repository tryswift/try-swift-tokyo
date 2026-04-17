import Foundation

do {
  let arguments = Array(CommandLine.arguments.dropFirst())
  let options = try BuildOptions(arguments: arguments)
  try StaticSiteBuilder(options: options).build()
  print("Built CfPWeb static site at \(options.outputDirectory.path())")
} catch {
  fputs("CfPWeb build failed: \(error.localizedDescription)\n", stderr)
  exit(1)
}
