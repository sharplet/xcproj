import Foundation
import Xcproj

func ancestors(of `class`: NSObject.Type) -> AnySequence<AnyObject> {
  var current: AnyObject? = `class`
  return AnySequence(AnyGenerator {
    if let next = current {
      current = next.performSelector(#selector(NSObject.superclass))?.takeUnretainedValue()
      return next
    } else {
      return nil
    }
  })
}

print(XCPProject())

let pwd = NSProcessInfo.processInfo().environment["PWD"]!
let path = "\(pwd)/xcproj.xcodeproj"
guard let project = XCPProject(file: path) else {
  fputs("no such project \(path)\n", stderr)
  exit(1)
}

for `class` in ancestors(of: project.dynamicType) {
  print(`class`)
}

print("is XCPProject?", project.isKindOfClass(XCPProject.self))
print("is PBXProject?", project.isKindOfClass(PBXProject.self))

print("project name: \(project.name)")
