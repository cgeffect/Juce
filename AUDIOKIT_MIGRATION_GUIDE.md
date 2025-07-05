# AudioKit Cookbook 迁移到 AppKit 指南

## 概述

本指南展示了如何将 [AudioKit Cookbook](https://github.com/AudioKit/Cookbook) 中的 SwiftUI 示例程序移植到 AppKit 项目中。

## 迁移原则

### 1. 架构转换
- **SwiftUI View** → **NSView**
- **@StateObject** → **NSObject 属性**
- **@Published** → **KVO 或通知**
- **SwiftUI 控件** → **AppKit 控件**

### 2. 核心组件保持不变
- **Conductor** 类保持基本不变
- **AudioKit 信号处理** 逻辑完全保留
- **数据模型** 结构保持一致

## 已移植的示例

### 基础示例 (`AudioKitExamples.swift`)

#### 1. 振荡器示例 (OscillatorExample)
```swift
// 原始 SwiftUI 版本
class OscillatorConductor: ObservableObject, HasAudioEngine {
    let engine = AudioEngine()
    var osc = Oscillator()
    @Published var isPlaying: Bool = false
}

// AppKit 版本
class OscillatorExample: NSObject {
    let engine = AudioEngine()
    var oscillator = Oscillator()
    
    func play() { oscillator.start() }
    func pause() { oscillator.stop() }
    func setFrequency(_ frequency: Float) { oscillator.frequency = frequency }
}
```

#### 2. 音频播放器示例 (AudioPlayerExample)
- 支持音频文件播放
- 包含完成回调处理
- 播放控制（播放、暂停、停止）

#### 3. 效果器示例 (EffectsExample)
- 混响效果
- 延迟效果
- 实时参数调节

### 高级示例 (`AdvancedAudioKitExamples.swift`)

#### 1. FM 振荡器 (FMOscillatorExample)
- 频率调制合成
- 调制指数控制
- 载波和调制器频率设置

#### 2. 滤波器 (FilterExample)
- 低通滤波器
- 高通滤波器
- 截止频率实时调节

#### 3. 失真效果 (DistortionExample)
- 前置增益控制
- 后置增益控制
- 失真形状参数

#### 4. 物理建模 (PhysicalModelExample)
- 拨弦物理模型
- 频率控制
- 触发播放

## UI 组件转换

### SwiftUI → AppKit 控件映射

| SwiftUI | AppKit | 说明 |
|---------|--------|------|
| `Slider` | `NSSlider` | 滑块控件 |
| `Button` | `NSButton` | 按钮控件 |
| `Text` | `NSTextField` | 文本显示 |
| `VStack` | `NSStackView` | 垂直布局 |
| `HStack` | `NSStackView` | 水平布局 |
| `TabView` | `NSTabView` | 标签页 |

### 事件处理转换

```swift
// SwiftUI 版本
Button("Play") {
    conductor.isPlaying.toggle()
}

// AppKit 版本
let playButton = NSButton()
playButton.title = "Play"
playButton.target = self
playButton.action = #selector(playButtonClicked)

@objc private func playButtonClicked() {
    conductor.play()
}
```

## 使用方法

### 1. 在 ViewController 中集成

```swift
class ViewController: NSViewController {
    private var audioKitControlPanel: AudioKitControlPanel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 创建控制面板
        audioKitControlPanel = AudioKitControlPanel(frame: view.bounds)
        audioKitControlPanel.autoresizingMask = [.width, .height]
        view.addSubview(audioKitControlPanel)
    }
}
```

### 2. 使用高级示例

```swift
class ViewController: NSViewController {
    private var advancedPanel: AdvancedAudioKitControlPanel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 创建高级控制面板（包含标签页）
        advancedPanel = AdvancedAudioKitControlPanel(frame: view.bounds)
        advancedPanel.autoresizingMask = [.width, .height]
        view.addSubview(advancedPanel)
    }
}
```

## 关键差异

### 1. 生命周期管理
- **SwiftUI**: 自动管理，使用 `onAppear`/`onDisappear`
- **AppKit**: 手动管理，在 `deinit` 中停止音频引擎

### 2. 状态管理
- **SwiftUI**: 使用 `@Published` 和 `@StateObject`
- **AppKit**: 使用 KVO 或直接方法调用

### 3. 布局系统
- **SwiftUI**: 声明式布局
- **AppKit**: 命令式布局，需要手动设置 frame 和约束

## 扩展建议

### 1. 添加更多示例
可以继续移植 Cookbook 中的其他示例：
- 包络发生器
- 音序器
- MIDI 处理
- 3D 音频

### 2. 改进 UI
- 使用 Auto Layout 约束
- 添加更多视觉反馈
- 实现参数自动化

### 3. 性能优化
- 使用音频缓冲区
- 实现音频处理线程
- 添加音频分析功能

## 注意事项

1. **音频权限**: 确保在 Info.plist 中添加麦克风使用权限
2. **内存管理**: 及时释放音频资源，避免内存泄漏
3. **线程安全**: 音频处理应在后台线程进行
4. **错误处理**: 添加适当的错误处理和用户反馈

## 参考资源

- [AudioKit Cookbook](https://github.com/AudioKit/Cookbook) - 原始 SwiftUI 示例
- [AudioKit 文档](https://audiokit.io/docs/) - 官方文档
- [AppKit 编程指南](https://developer.apple.com/documentation/appkit) - AppKit 框架文档 