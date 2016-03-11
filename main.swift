import Xcproj

let xcproj = try! Xcproj.loadFrameworks()

if let project = xcproj.projectAtPath("xcproj.xcodeproj") {
  print("project name:", project.name)
} else {
  print("no project file found")
}
