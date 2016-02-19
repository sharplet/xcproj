import Xcproj

do {
  try Xcproj.loadFrameworks()
} catch {
  print(error)
}
