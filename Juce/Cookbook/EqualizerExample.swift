import AppKit
import AVFoundation
import AudioKit
import AudioKitEX
import SoundpipeAudioKit

// MARK: - 均衡器示例
class EqualizerExample: NSObject {
    let engine = AudioEngine()
    var player = AudioPlayer()
    var equalizerFilters: [EqualizerFilter] = []
    
    // 均衡器频段设置
    private let frequencyBands: [Float] = [60, 170, 310, 600, 1000, 3000, 6000, 12000, 14000, 16000]
    private var bandGains: [Float] = Array(repeating: 0.0, count: 10) // 10个频段
    private var isPlaying = false
    
    override init() {
        super.init()
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        // 创建10个均衡器滤波器
        var currentInput: Node = player
        
        for frequency in frequencyBands {
            let filter = EqualizerFilter(currentInput, centerFrequency: frequency, bandwidth: 100.0, gain: 1.0)
            equalizerFilters.append(filter)
            currentInput = filter
        }
        
        // 设置音频链：player -> equalizerFilters -> engine
        engine.output = currentInput
        
        // 设置完成回调
        player.completionHandler = { [weak self] in
            DispatchQueue.main.async {
                self?.isPlaying = false
                print("Equalizer playback completed")
            }
        }
    }
    

    
    func start() {
        do {
            try engine.start()
            print("Equalizer engine started")
        } catch {
            print("Failed to start equalizer engine: \(error)")
            // 尝试重新配置
            setupAudioEngine()
            do {
                try engine.start()
                print("Equalizer engine restarted successfully")
            } catch {
                print("Failed to restart equalizer engine: \(error)")
            }
        }
    }
    
    func stop() {
        engine.stop()
        print("Equalizer engine stopped")
    }
    
    func loadAndPlay(url: URL) {
        do {
            try player.load(url: url)
            player.play()
            isPlaying = true
            print("Playing with equalizer: \(url.lastPathComponent)")
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
    
    // 设置特定频段的增益
    func setBandGain(bandIndex: Int, gain: Float) {
        guard bandIndex >= 0 && bandIndex < frequencyBands.count && bandIndex < equalizerFilters.count else { return }
        bandGains[bandIndex] = gain
        
        // 更新均衡器参数
        let filter = equalizerFilters[bandIndex]
        filter.gain = gain
    }
    
    // 获取频段增益
    func getBandGain(bandIndex: Int) -> Float {
        guard bandIndex >= 0 && bandIndex < bandGains.count else { return 0.0 }
        return bandGains[bandIndex]
    }
    
    // 获取频段频率
    func getBandFrequency(bandIndex: Int) -> Float {
        guard bandIndex >= 0 && bandIndex < frequencyBands.count else { return 0.0 }
        return frequencyBands[bandIndex]
    }
    
    // 重置所有频段
    func resetAllBands() {
        bandGains = Array(repeating: 0.0, count: frequencyBands.count)
        for (index, filter) in equalizerFilters.enumerated() {
            filter.gain = 0.0
        }
    }
    
    // 应用预设
    func applyPreset(_ preset: EqualizerPreset) {
        switch preset {
        case .flat:
            resetAllBands()
        case .bass:
            setBandGain(bandIndex: 0, gain: 6.0)  // 60Hz
            setBandGain(bandIndex: 1, gain: 4.0)  // 170Hz
            setBandGain(bandIndex: 2, gain: 2.0)  // 310Hz
        case .treble:
            setBandGain(bandIndex: 6, gain: 3.0)  // 6kHz
            setBandGain(bandIndex: 7, gain: 4.0)  // 12kHz
            setBandGain(bandIndex: 8, gain: 5.0)  // 14kHz
            setBandGain(bandIndex: 9, gain: 6.0)  // 16kHz
        case .vocal:
            setBandGain(bandIndex: 3, gain: 2.0)  // 600Hz
            setBandGain(bandIndex: 4, gain: 4.0)  // 1kHz
            setBandGain(bandIndex: 5, gain: 3.0)  // 3kHz
        case .rock:
            setBandGain(bandIndex: 0, gain: 4.0)  // 60Hz
            setBandGain(bandIndex: 1, gain: 2.0)  // 170Hz
            setBandGain(bandIndex: 4, gain: 1.0)  // 1kHz
            setBandGain(bandIndex: 6, gain: 2.0)  // 6kHz
            setBandGain(bandIndex: 7, gain: 3.0)  // 12kHz
        }
    }
    

}

// MARK: - 均衡器预设
enum EqualizerPreset: String, CaseIterable {
    case flat = "平直"
    case bass = "低音增强"
    case treble = "高音增强"
    case vocal = "人声增强"
    case rock = "摇滚"
    
    var description: String {
        return self.rawValue
    }
}

// MARK: - 均衡器控制面板
class EqualizerControlPanel: NSView {
    private var equalizerExample: EqualizerExample!
    
    // UI 组件
    private let playButton = NSButton()
    private let pauseButton = NSButton()
    private let stopButton = NSButton()
    private let openButton = NSButton()
    private let presetButton = NSPopUpButton()
    private let resetButton = NSButton()
    
    // 均衡器滑块数组
    private var bandSliders: [NSSlider] = []
    private var bandLabels: [NSTextField] = []
    private var gainLabels: [NSTextField] = []
    private let equalizerTitleLabel = NSTextField()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupEqualizer()
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupEqualizer()
        setupUI()
    }
    
    private func setupEqualizer() {
        equalizerExample = EqualizerExample()
        // 延迟启动，避免启动时的参数错误
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.equalizerExample.start()
        }
    }
    
    private func setupUI() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        setupButtons()
        setupPresetControls()
        setupEqualizerTitle()
        setupEqualizerSliders()
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
        for preset in EqualizerPreset.allCases {
            presetButton.addItem(withTitle: preset.description)
        }
        presetButton.target = self
        presetButton.action = #selector(presetChanged)
        addSubview(presetButton)
        
        // 重置按钮
        resetButton.title = "重置"
        resetButton.bezelStyle = .rounded
        resetButton.target = self
        resetButton.action = #selector(resetEqualizer)
        addSubview(resetButton)
    }
    
    private func setupEqualizerSliders() {
        let frequencyBands: [Float] = [60, 170, 310, 600, 1000, 3000, 6000, 12000, 14000, 16000]
        
        for (index, frequency) in frequencyBands.enumerated() {
            // 频段标签
            let label = NSTextField()
            label.stringValue = formatFrequency(frequency)
            label.isEditable = false
            label.isBordered = false
            label.backgroundColor = NSColor.clear
            label.font = NSFont.systemFont(ofSize: 10)
            label.alignment = .center
            addSubview(label)
            bandLabels.append(label)
            
            // 增益滑块 - 设置为竖向
            let slider = NSSlider()
            slider.minValue = -12.0
            slider.maxValue = 12.0
            slider.doubleValue = 0.0
            slider.isVertical = true  // 设置为竖向
            slider.numberOfTickMarks = 13  // 添加刻度标记
            slider.allowsTickMarkValuesOnly = false  // 允许连续值
            slider.target = self
            slider.action = #selector(bandSliderChanged(_:))
            slider.tag = index
            addSubview(slider)
            bandSliders.append(slider)
            
            // 增益值标签
            let gainLabel = NSTextField()
            gainLabel.stringValue = "0 dB"
            gainLabel.isEditable = false
            gainLabel.isBordered = false
            gainLabel.backgroundColor = NSColor.clear
            gainLabel.font = NSFont.systemFont(ofSize: 9)
            gainLabel.alignment = .center
            addSubview(gainLabel)
            gainLabels.append(gainLabel)
        }
    }
    
    private func setupEqualizerTitle() {
        equalizerTitleLabel.stringValue = "10段均衡器"
        equalizerTitleLabel.isEditable = false
        equalizerTitleLabel.isBordered = false
        equalizerTitleLabel.backgroundColor = NSColor.clear
        equalizerTitleLabel.font = NSFont.boldSystemFont(ofSize: 14)
        equalizerTitleLabel.alignment = .center
        addSubview(equalizerTitleLabel)
    }
    
    private func setupLayout() {
        let buttonWidth: CGFloat = 100
        let buttonHeight: CGFloat = 35
        let spacing: CGFloat = 15
        let startX: CGFloat = 20
        let startY: CGFloat = 20
        
        // 均衡器滑块布局 - 竖向滑块，放在上方
        let sliderWidth: CGFloat = 25
        let sliderHeight: CGFloat = 200
        let sliderSpacing: CGFloat = 80
        let sliderStartX: CGFloat = 200
        let sliderStartY: CGFloat = 150

        // 控制按钮布局在底部
        openButton.frame = NSRect(x: startX, y: startY, width: buttonWidth, height: buttonHeight)
        playButton.frame = NSRect(x: startX + buttonWidth + spacing, y: startY, width: buttonWidth, height: buttonHeight)
        pauseButton.frame = NSRect(x: startX + (buttonWidth + spacing) * 2, y: startY, width: buttonWidth, height: buttonHeight)
        stopButton.frame = NSRect(x: startX + (buttonWidth + spacing) * 3, y: startY, width: buttonWidth, height: buttonHeight)
        
        // 预设控制布局在底部
        presetButton.frame = NSRect(x: startX + (buttonWidth + spacing) * 4 + 20, y: startY, width: 120, height: buttonHeight)
        resetButton.frame = NSRect(x: startX + (buttonWidth + spacing) * 4 + 150, y: startY, width: 80, height: buttonHeight)
        
        // 均衡器标题在上方
        equalizerTitleLabel.frame = NSRect(x: sliderStartX - 50, y: sliderStartY + sliderHeight + 30, width: 800, height: 25)
                
        for (index, _) in bandSliders.enumerated() {
            let x = sliderStartX + CGFloat(index) * sliderSpacing
            
            // 频段标签 - 在滑块下方
            bandLabels[index].frame = NSRect(x: x - 20, y: sliderStartY - 30, width: 60, height: 20)
            
            // 增益滑块 - 竖向布局
            bandSliders[index].frame = NSRect(x: x, y: sliderStartY, width: sliderWidth, height: sliderHeight)
            
            // 增益值标签 - 在滑块上方
            gainLabels[index].frame = NSRect(x: x - 20, y: sliderStartY + sliderHeight + 10, width: 60, height: 20)
            
            // 设置滑块的初始值显示
            gainLabels[index].stringValue = "0 dB"
        }
        
        // 添加中心线标记
        addCenterLineMarkers()
    }
    
    private func addCenterLineMarkers() {
        let sliderStartX: CGFloat = 200
        let sliderStartY: CGFloat = 150
        let sliderHeight: CGFloat = 200
        let sliderSpacing: CGFloat = 80
        
        for index in 0..<bandSliders.count {
            let x = sliderStartX + CGFloat(index) * sliderSpacing
            
            // 创建中心线标记
            let centerLine = NSView(frame: NSRect(x: x + 10, y: sliderStartY + sliderHeight/2 - 1, width: 5, height: 2))
            centerLine.wantsLayer = true
            centerLine.layer?.backgroundColor = NSColor.gray.cgColor
            addSubview(centerLine)
        }
    }
    
    private func formatFrequency(_ frequency: Float) -> String {
        if frequency >= 1000 {
            return String(format: "%.0fk", frequency / 1000)
        } else {
            return String(format: "%.0f", frequency)
        }
    }
    
    @objc private func openAudioFile() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.audio, .mp3, .wav, .aiff]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        
        openPanel.begin { [weak self] result in
            if result == .OK, let url = openPanel.url {
                self?.equalizerExample.loadAndPlay(url: url)
            }
        }
    }
    
    @objc private func playAudio() {
        equalizerExample.resume()
    }
    
    @objc private func pauseAudio() {
        equalizerExample.pause()
    }
    
    @objc private func stopAudio() {
        equalizerExample.stopPlayback()
    }
    
    @objc private func presetChanged() {
        let selectedIndex = presetButton.indexOfSelectedItem
        guard selectedIndex >= 0 && selectedIndex < EqualizerPreset.allCases.count else { return }
        
        let preset = EqualizerPreset.allCases[selectedIndex]
        equalizerExample.applyPreset(preset)
        
        // 更新滑块显示
        updateSliderDisplay()
    }
    
    @objc private func resetEqualizer() {
        equalizerExample.resetAllBands()
        updateSliderDisplay()
    }
    
    @objc private func bandSliderChanged(_ sender: NSSlider) {
        let bandIndex = sender.tag
        let gain = Float(sender.doubleValue)
        
        equalizerExample.setBandGain(bandIndex: bandIndex, gain: gain)
        
        // 更新增益值标签
        gainLabels[bandIndex].stringValue = String(format: "%.1f dB", gain)
    }
    
    private func updateSliderDisplay() {
        for (index, slider) in bandSliders.enumerated() {
            let gain = equalizerExample.getBandGain(bandIndex: index)
            slider.doubleValue = Double(gain)
            gainLabels[index].stringValue = String(format: "%.1f dB", gain)
        }
    }
    
    deinit {
        equalizerExample.stop()
    }
} 
