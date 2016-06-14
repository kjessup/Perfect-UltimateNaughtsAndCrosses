import PackageDescription

let versions = Version(0,0,0)..<Version(10,0,0)
let urls = [
    "https://github.com/PerfectlySoft/Perfect.git",
    "https://github.com/PerfectlySoft/Perfect-SQLite.git"
]

let package = Package(
    name: "PerfectUltimateNaughtsAndCrosses",
    targets: [],
    dependencies: urls.map { .Package(url: $0, versions: versions) }
)