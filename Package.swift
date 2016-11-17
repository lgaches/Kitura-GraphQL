import PackageDescription

let package = Package(
    name: "Kitura-GraphQL",
    dependencies: [
      .Package(url: "https://github.com/IBM-Swift/Kitura.git", majorVersion: 1, minor: 2),
      .Package(url: "https://github.com/lgaches/Graphiti.git", majorVersion: 0, minor: 1)     
    ]
)
