使用了本地的dependencies, 把package文件夹里的Package.swift依赖改为本地依赖
```
    dependencies: [.package(path: "../AudioKit")],
```