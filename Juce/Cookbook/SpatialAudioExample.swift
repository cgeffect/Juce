import AppKit
import AVFoundation
import AudioKit
import AudioKitEX
import SoundpipeAudioKit

// MARK: - 扩展
extension Float {
    func clamped(to range: ClosedRange<Float>) -> Float {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - 空间音频效果器示例
class SpatialAudioExample: NSObject {
    let engine = AudioEngine()
    var player = AudioPlayer()
    var spatialView: SpatialAudioView!
    
    // 空间音频处理节点
    var reverb: Reverb!
    var delay: Delay!
    var panner: Panner!
    var compressor: Compressor!
    
    // 空间音频参数
    private var azimuth: Float = 0.0      // 水平角度 (-180° 到 180°)
    private var elevation: Float = 0.0    // 垂直角度 (-90° 到 90°)
    private var distance: Float = 1.0     // 距离 (0.1 到 10.0)
    private var reverbMix: Float = 0.3    // 混响混合量
    private var delayTime: Float = 0.1    // 延迟时间
    private var delayFeedback: Float = 0.3 // 延迟反馈
    private var isPlaying = false
    
    override init() {
        super.init()
        setupAudioEngine()
        setupSpatialView()
    }
    
    private func setupAudioEngine() {
        // 创建空间音频处理链
        reverb = Reverb(player, dryWetMix: reverbMix)
        delay = Delay(reverb, time: delayTime, feedback: delayFeedback, lowPassCutoff: 15000, dryWetMix: 50)
        panner = Panner(delay, pan: 0.0)
        compressor = Compressor(panner, threshold: -20, headRoom: 5, attackTime: 0.01, releaseTime: 0.1, masterGain: 0)
        
        // 设置音频链：player -> reverb -> delay -> panner -> compressor -> engine
        engine.output = compressor
        
        // 设置完成回调
        player.completionHandler = { [weak self] in
            DispatchQueue.main.async {
                self?.isPlaying = false
                print("Spatial audio playback completed")
            }
        }
    }
    

    
    private func setupSpatialView() {
        spatialView = SpatialAudioView(frame: NSRect(x: 0, y: 0, width: 400, height: 300))
        spatialView.backgroundColor = NSColor.black
    }
    
    func start() {
        do {
            // 确保音频引擎在启动前已经正确配置
            try engine.start()
            print("Spatial audio engine started")
        } catch {
            print("Failed to start spatial audio engine: \(error)")
            // 尝试重新配置音频引擎
            setupAudioEngine()
            do {
                try engine.start()
                print("Spatial audio engine restarted successfully")
            } catch {
                print("Failed to restart spatial audio engine: \(error)")
            }
        }
    }
    
    func stop() {
        engine.stop()
        print("Spatial audio engine stopped")
    }
    
    func loadAndPlay(url: URL) {
        do {
            try player.load(url: url)
            player.play()
            isPlaying = true
            print("Playing with spatial audio: \(url.lastPathComponent)")
        } catch {
            print("Failed to load audio file: \(error)")
        }
    }
    
    func pause() {
        player.pause()
        isPlaying = false
    }
    
    func resume() {
        player.resume()
        isPlaying = true
    }
    
    func stopPlayback() {
        player.stop()
        isPlaying = false
    }
    
    // MARK: - 空间音频参数控制
    
    func setAzimuth(_ value: Float) {
        azimuth = value
        updateSpatialParameters()
    }
    
    func setElevation(_ value: Float) {
        elevation = value
        updateSpatialParameters()
    }
    
    func setDistance(_ value: Float) {
        distance = value
        updateSpatialParameters()
    }
    
    func setReverbMix(_ value: Float) {
        reverbMix = value
        reverb.dryWetMix = value
    }
    
    func setDelayTime(_ value: Float) {
        delayTime = value
        delay.time = value
    }
    
    func setDelayFeedback(_ value: Float) {
        delayFeedback = value
        delay.feedback = value
    }
    
    private func updateSpatialParameters() {
        // 根据方位角和仰角计算立体声定位
        let pan = sin(azimuth * .pi / 180.0)
        panner.pan = pan.clamped(to: -1.0...1.0)
        
        // 根据距离调整混响和延迟
        let distanceFactor = 1.0 / max(distance, 0.1)
        let reverbMixValue = (reverbMix * distanceFactor).clamped(to: 0.0...1.0)
        let delayMixValue = (50 * distanceFactor).clamped(to: 0.0...100.0)
        
        reverb.dryWetMix = reverbMixValue
        delay.dryWetMix = delayMixValue
        
        // 更新空间视图
        DispatchQueue.main.async {
            self.spatialView.updatePosition(azimuth: self.azimuth, elevation: self.elevation, distance: self.distance)
        }
    }
    
    // 应用预设
    func applyPreset(_ preset: SpatialAudioPreset) {
        switch preset {
        case .room:
            setAzimuth(0)
            setElevation(0)
            setDistance(2.0)
            setReverbMix(0.4)
            setDelayTime(0.05)
            setDelayFeedback(0.2)
        case .hall:
            setAzimuth(0)
            setElevation(0)
            setDistance(5.0)
            setReverbMix(0.7)
            setDelayTime(0.1)
            setDelayFeedback(0.4)
        case .surround:
            setAzimuth(45)
            setElevation(10)
            setDistance(3.0)
            setReverbMix(0.5)
            setDelayTime(0.08)
            setDelayFeedback(0.3)
        case .distant:
            setAzimuth(90)
            setElevation(-20)
            setDistance(8.0)
            setReverbMix(0.8)
            setDelayTime(0.15)
            setDelayFeedback(0.5)
        case .close:
            setAzimuth(-30)
            setElevation(5)
            setDistance(0.5)
            setReverbMix(0.1)
            setDelayTime(0.02)
            setDelayFeedback(0.1)
        }
        
        // 立即更新参数
        updateSpatialParameters()
    }
    

}

// MARK: - 空间音频预设
enum SpatialAudioPreset: String, CaseIterable {
    case room = "房间"
    case hall = "大厅"
    case surround = "环绕"
    case distant = "远处"
    case close = "近距离"
    
    var description: String {
        return self.rawValue
    }
}

// MARK: - 空间音频可视化视图
class SpatialAudioView: NSView {
    var backgroundColor: NSColor = NSColor.black { didSet { needsDisplay = true } }
    var gridColor: NSColor = NSColor.darkGray { didSet { needsDisplay = true } }
    var positionColor: NSColor = NSColor.yellow { didSet { needsDisplay = true } }
    var listenerColor: NSColor = NSColor.green { didSet { needsDisplay = true } }
    
    private var azimuth: Float = 0.0
    private var elevation: Float = 0.0
    private var distance: Float = 1.0
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        wantsLayer = true
        layer?.backgroundColor = backgroundColor.cgColor
    }
    
    func updatePosition(azimuth: Float, elevation: Float, distance: Float) {
        self.azimuth = azimuth
        self.elevation = elevation
        self.distance = distance
        needsDisplay = true
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        context.setFillColor(backgroundColor.cgColor)
        context.fill(bounds)
        
        drawGrid(context: context)
        drawListener(context: context)
        drawSoundSource(context: context)
        drawLabels(context: context)
    }
    
    private func drawGrid(context: CGContext) {
        let width = bounds.width
        let height = bounds.height
        let centerX = width / 2
        let centerY = height / 2
        
        context.setStrokeColor(gridColor.cgColor)
        context.setLineWidth(0.5)
        
        // 绘制同心圆（距离网格）
        let maxRadius = min(width, height) / 2 - 20
        for i in 1...5 {
            let radius = maxRadius * CGFloat(i) / 5.0
            context.beginPath()
            context.addEllipse(in: CGRect(x: centerX - radius, y: centerY - radius, width: radius * 2, height: radius * 2))
            context.strokePath()
        }
        
        // 绘制角度线
        let angles: [CGFloat] = [-90, -45, 0, 45, 90]
        for angle in angles {
            let radians = angle * .pi / 180.0
            let endX = centerX + cos(radians) * maxRadius
            let endY = centerY + sin(radians) * maxRadius
            
            context.beginPath()
            context.move(to: CGPoint(x: centerX, y: centerY))
            context.addLine(to: CGPoint(x: endX, y: endY))
            context.strokePath()
        }
    }
    
    private func drawListener(context: CGContext) {
        let width = bounds.width
        let height = bounds.height
        let centerX = width / 2
        let centerY = height / 2
        
        // 绘制听众位置（中心点）
        context.setFillColor(listenerColor.cgColor)
        let listenerSize: CGFloat = 8
        let listenerRect = CGRect(x: centerX - listenerSize/2, y: centerY - listenerSize/2, width: listenerSize, height: listenerSize)
        context.fillEllipse(in: listenerRect)
        
        // 绘制听众标签
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10),
            .foregroundColor: NSColor.white
        ]
        let label = "听众"
        let labelSize = label.size(withAttributes: labelAttributes)
        label.draw(at: CGPoint(x: centerX - labelSize.width/2, y: centerY + 15), withAttributes: labelAttributes)
    }
    
    private func drawSoundSource(context: CGContext) {
        let width = bounds.width
        let height = bounds.height
        let centerX = width / 2
        let centerY = height / 2
        let maxRadius = min(width, height) / 2 - 20
        
        // 计算声源位置
        let azimuthRadians = CGFloat(azimuth) * .pi / 180.0
        let normalizedDistance = CGFloat(distance) / 10.0 // 假设最大距离为10
        let radius = maxRadius * normalizedDistance
        
        let sourceX = centerX + cos(azimuthRadians) * radius
        let sourceY = centerY + sin(azimuthRadians) * radius
        
        // 绘制声源
        context.setFillColor(positionColor.cgColor)
        let sourceSize: CGFloat = 12
        let sourceRect = CGRect(x: sourceX - sourceSize/2, y: sourceY - sourceSize/2, width: sourceSize, height: sourceSize)
        context.fillEllipse(in: sourceRect)
        
        // 绘制连接线
        context.setStrokeColor(positionColor.cgColor)
        context.setLineWidth(2.0)
        context.beginPath()
        context.move(to: CGPoint(x: centerX, y: centerY))
        context.addLine(to: CGPoint(x: sourceX, y: sourceY))
        context.strokePath()
        
        // 绘制声源标签
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10),
            .foregroundColor: NSColor.white
        ]
        let label = "声源"
        let labelSize = label.size(withAttributes: labelAttributes)
        label.draw(at: CGPoint(x: sourceX - labelSize.width/2, y: sourceY - 20), withAttributes: labelAttributes)
    }
    
    private func drawLabels(context: CGContext) {
        let width = bounds.width
        let height = bounds.height
        
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10),
            .foregroundColor: NSColor.white
        ]
        
        // 绘制参数信息
        let infoText = [
            "方位角: \(Int(azimuth))°",
            "仰角: \(Int(elevation))°",
            "距离: \(String(format: "%.1f", distance))"
        ]
        
        for (index, text) in infoText.enumerated() {
            let y = height - 20 - CGFloat(index * 15)
            text.draw(at: CGPoint(x: 10, y: y), withAttributes: labelAttributes)
        }
        
        // 绘制标题
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 12),
            .foregroundColor: NSColor.white
        ]
        let title = "3D空间音频"
        let titleSize = title.size(withAttributes: titleAttributes)
        title.draw(at: CGPoint(x: (width - titleSize.width)/2, y: height - 20), withAttributes: titleAttributes)
    }
}

// MARK: - 空间音频控制面板
class SpatialAudioControlPanel: NSView {
    private var spatialExample: SpatialAudioExample!
    private var spatialView: SpatialAudioView!
    
    // UI 组件
    private let playButton = NSButton()
    private let pauseButton = NSButton()
    private let stopButton = NSButton()
    private let openButton = NSButton()
    private let presetButton = NSPopUpButton()
    
    // 空间音频控制滑块
    private let azimuthSlider = NSSlider()
    private let elevationSlider = NSSlider()
    private let distanceSlider = NSSlider()
    private let reverbSlider = NSSlider()
    private let delayTimeSlider = NSSlider()
    private let delayFeedbackSlider = NSSlider()
    
    // 标签
    private let azimuthLabel = NSTextField()
    private let elevationLabel = NSTextField()
    private let distanceLabel = NSTextField()
    private let reverbLabel = NSTextField()
    private let delayTimeLabel = NSTextField()
    private let delayFeedbackLabel = NSTextField()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupSpatialExample()
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSpatialExample()
        setupUI()
    }
    
    private func setupSpatialExample() {
        spatialExample = SpatialAudioExample()
        spatialExample.start()
        spatialView = spatialExample.spatialView
    }
    
    private func setupUI() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        // 设置空间视图
        spatialView.frame = NSRect(x: 20, y: 20, width: 450, height: 400)
        addSubview(spatialView)
        
        setupButtons()
        setupPresetControls()
        setupSpatialControls()
        setupLayout()
    }
    
    private func setupButtons() {
        // 打开文件按钮
        openButton.title = "打开音频文件"
        openButton.bezelStyle = .rounded
        openButton.target = self
        openButton.action = #selector(openAudioFile)
        addSubview(openButton)
        
        // 播放按钮
        playButton.title = "播放"
        playButton.bezelStyle = .rounded
        playButton.target = self
        playButton.action = #selector(playAudio)
        addSubview(playButton)
        
        // 暂停按钮
        pauseButton.title = "暂停"
        pauseButton.bezelStyle = .rounded
        pauseButton.target = self
        pauseButton.action = #selector(pauseAudio)
        addSubview(pauseButton)
        
        // 停止按钮
        stopButton.title = "停止"
        stopButton.bezelStyle = .rounded
        stopButton.target = self
        stopButton.action = #selector(stopAudio)
        addSubview(stopButton)
    }
    
    private func setupPresetControls() {
        // 预设选择按钮
        presetButton.removeAllItems()
        for preset in SpatialAudioPreset.allCases {
            presetButton.addItem(withTitle: preset.description)
        }
        presetButton.target = self
        presetButton.action = #selector(presetChanged)
        addSubview(presetButton)
    }
    
    private func setupSpatialControls() {
        // 方位角控制
        setupSlider(azimuthSlider, label: azimuthLabel, title: "方位角", min: -180, max: 180, value: 0, action: #selector(azimuthChanged))
        
        // 仰角控制
        setupSlider(elevationSlider, label: elevationLabel, title: "仰角", min: -90, max: 90, value: 0, action: #selector(elevationChanged))
        
        // 距离控制
        setupSlider(distanceSlider, label: distanceLabel, title: "距离", min: 0.1, max: 10.0, value: 1.0, action: #selector(distanceChanged))
        
        // 混响控制
        setupSlider(reverbSlider, label: reverbLabel, title: "混响", min: 0.0, max: 1.0, value: 0.3, action: #selector(reverbChanged))
        
        // 延迟时间控制
        setupSlider(delayTimeSlider, label: delayTimeLabel, title: "延迟时间", min: 0.01, max: 2.0, value: 0.1, action: #selector(delayTimeChanged))
        
        // 延迟反馈控制
        setupSlider(delayFeedbackSlider, label: delayFeedbackLabel, title: "延迟反馈", min: -1.0, max: 1.0, value: 0.3, action: #selector(delayFeedbackChanged))
    }
    
    private func setupSlider(_ slider: NSSlider, label: NSTextField, title: String, min: Double, max: Double, value: Double, action: Selector) {
        slider.minValue = min
        slider.maxValue = max
        slider.doubleValue = value
        slider.target = self
        slider.action = action
        addSubview(slider)
        
        label.stringValue = "\(title): \(String(format: "%.1f", value))"
        label.isEditable = false
        label.isBordered = false
        label.backgroundColor = NSColor.clear
        label.font = NSFont.systemFont(ofSize: 10)
        addSubview(label)
    }
    

    
    private func setupLayout() {
        let buttonWidth: CGFloat = 80
        let buttonHeight: CGFloat = 30
        let spacing: CGFloat = 10
        let startX: CGFloat = 500
        let startY: CGFloat = 400
        
        // 控制按钮布局
        openButton.frame = NSRect(x: startX, y: startY, width: buttonWidth, height: buttonHeight)
        playButton.frame = NSRect(x: startX + buttonWidth + spacing, y: startY, width: buttonWidth, height: buttonHeight)
        pauseButton.frame = NSRect(x: startX + (buttonWidth + spacing) * 2, y: startY, width: buttonWidth, height: buttonHeight)
        stopButton.frame = NSRect(x: startX + (buttonWidth + spacing) * 3, y: startY, width: buttonWidth, height: buttonHeight)
        
        // 预设控制
        presetButton.frame = NSRect(x: startX, y: startY - 40, width: 120, height: buttonHeight)
        

        
        // 空间音频控制布局
        let sliderWidth: CGFloat = 200
        let sliderHeight: CGFloat = 20
        let sliderSpacing: CGFloat = 30
        let sliderStartX: CGFloat = startX
        let sliderStartY: CGFloat = startY - 150
        
        // 方位角
        azimuthSlider.frame = NSRect(x: sliderStartX, y: sliderStartY, width: sliderWidth, height: sliderHeight)
        azimuthLabel.frame = NSRect(x: sliderStartX + sliderWidth + 10, y: sliderStartY, width: 100, height: sliderHeight)
        
        // 仰角
        elevationSlider.frame = NSRect(x: sliderStartX, y: sliderStartY - sliderSpacing, width: sliderWidth, height: sliderHeight)
        elevationLabel.frame = NSRect(x: sliderStartX + sliderWidth + 10, y: sliderStartY - sliderSpacing, width: 100, height: sliderHeight)
        
        // 距离
        distanceSlider.frame = NSRect(x: sliderStartX, y: sliderStartY - sliderSpacing * 2, width: sliderWidth, height: sliderHeight)
        distanceLabel.frame = NSRect(x: sliderStartX + sliderWidth + 10, y: sliderStartY - sliderSpacing * 2, width: 100, height: sliderHeight)
        
        // 混响
        reverbSlider.frame = NSRect(x: sliderStartX, y: sliderStartY - sliderSpacing * 3, width: sliderWidth, height: sliderHeight)
        reverbLabel.frame = NSRect(x: sliderStartX + sliderWidth + 10, y: sliderStartY - sliderSpacing * 3, width: 100, height: sliderHeight)
        
        // 延迟时间
        delayTimeSlider.frame = NSRect(x: sliderStartX, y: sliderStartY - sliderSpacing * 4, width: sliderWidth, height: sliderHeight)
        delayTimeLabel.frame = NSRect(x: sliderStartX + sliderWidth + 10, y: sliderStartY - sliderSpacing * 4, width: 100, height: sliderHeight)
        
        // 延迟反馈
        delayFeedbackSlider.frame = NSRect(x: sliderStartX, y: sliderStartY - sliderSpacing * 5, width: sliderWidth, height: sliderHeight)
        delayFeedbackLabel.frame = NSRect(x: sliderStartX + sliderWidth + 10, y: sliderStartY - sliderSpacing * 5, width: 100, height: sliderHeight)
    }
    
    @objc private func openAudioFile() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.audio, .mp3, .wav, .aiff]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        
        openPanel.begin { [weak self] result in
            if result == .OK, let url = openPanel.url {
                self?.spatialExample.loadAndPlay(url: url)
            }
        }
    }
    
    @objc private func playAudio() {
        spatialExample.resume()
    }
    
    @objc private func pauseAudio() {
        spatialExample.pause()
    }
    
    @objc private func stopAudio() {
        spatialExample.stopPlayback()
    }
    
    @objc private func presetChanged() {
        let selectedIndex = presetButton.indexOfSelectedItem
        guard selectedIndex >= 0 && selectedIndex < SpatialAudioPreset.allCases.count else { return }
        
        let preset = SpatialAudioPreset.allCases[selectedIndex]
        spatialExample.applyPreset(preset)
        
        // 更新滑块显示
        updateSliderDisplay()
    }
    
    @objc private func azimuthChanged() {
        let value = Float(azimuthSlider.doubleValue)
        spatialExample.setAzimuth(value)
        azimuthLabel.stringValue = "方位角: \(Int(value))°"
    }
    
    @objc private func elevationChanged() {
        let value = Float(elevationSlider.doubleValue)
        spatialExample.setElevation(value)
        elevationLabel.stringValue = "仰角: \(Int(value))°"
    }
    
    @objc private func distanceChanged() {
        let value = Float(distanceSlider.doubleValue)
        spatialExample.setDistance(value)
        distanceLabel.stringValue = "距离: \(String(format: "%.1f", value))"
    }
    
    @objc private func reverbChanged() {
        let value = Float(reverbSlider.doubleValue)
        spatialExample.setReverbMix(value)
        reverbLabel.stringValue = "混响: \(String(format: "%.2f", value))"
    }
    
    @objc private func delayTimeChanged() {
        let value = Float(delayTimeSlider.doubleValue)
        spatialExample.setDelayTime(value)
        delayTimeLabel.stringValue = "延迟时间: \(String(format: "%.2f", value))s"
    }
    
    @objc private func delayFeedbackChanged() {
        let value = Float(delayFeedbackSlider.doubleValue)
        spatialExample.setDelayFeedback(value)
        delayFeedbackLabel.stringValue = "延迟反馈: \(String(format: "%.2f", value))"
    }
    
    private func updateSliderDisplay() {
        // 这里可以根据需要更新滑块显示
    }
    
    deinit {
        spatialExample.stop()
    }
} 