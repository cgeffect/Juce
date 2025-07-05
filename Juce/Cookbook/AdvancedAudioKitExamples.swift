import AudioKit
import SoundpipeAudioKit
import AudioKitEX
import AudioToolbox
import AppKit

// MARK: - 高级音频示例集合
class AdvancedAudioKitExamples: NSObject {
    
    // MARK: - FM 振荡器示例
    class FMOscillatorExample: NSObject {
        let engine = AudioEngine()
        var fmOscillator = FMOscillator()
        
        override init() {
            super.init()
            setupFMOscillator()
        }
        
        private func setupFMOscillator() {
            fmOscillator.baseFrequency = 440.0
            fmOscillator.carrierMultiplier = 1.0
            fmOscillator.modulatingMultiplier = 2.0
            fmOscillator.modulationIndex = 3.0
            fmOscillator.amplitude = 0.2
            engine.output = fmOscillator
        }
        
        func start() {
            do {
                try engine.start()
                print("FM Oscillator started")
            } catch {
                print("Failed to start FM oscillator: \(error)")
                // 尝试重新配置
                setupFMOscillator()
                do {
                    try engine.start()
                    print("FM Oscillator restarted successfully")
                } catch {
                    print("Failed to restart FM oscillator: \(error)")
                }
            }
        }
        
        func stop() {
            engine.stop()
            print("FM Oscillator stopped")
        }
        
        func play() {
            fmOscillator.start()
        }
        
        func pause() {
            fmOscillator.stop()
        }
        
        func setBaseFrequency(_ frequency: Float) {
            fmOscillator.baseFrequency = frequency
        }
        
        func setModulationIndex(_ index: Float) {
            fmOscillator.modulationIndex = index
        }
    }
    
    // MARK: - 滤波器示例
    class FilterExample: NSObject {
        let engine = AudioEngine()
        var oscillator: Oscillator!
        var lowPassFilter: LowPassFilter!
        var highPassFilter: HighPassFilter!
        
        override init() {
            super.init()
            setupFilters()
        }
        
        private func setupFilters() {
            // 先创建振荡器
            oscillator = Oscillator()
            oscillator.amplitude = 0.2
            oscillator.frequency = 440.0
            
            // 然后创建滤波器
            lowPassFilter = LowPassFilter(oscillator)
            lowPassFilter.cutoffFrequency = 1000.0
            lowPassFilter.resonance = 0.0
            
            highPassFilter = HighPassFilter(lowPassFilter)
            highPassFilter.cutoffFrequency = 200.0
            highPassFilter.resonance = 0.0
            
            engine.output = highPassFilter
        }
        
        func start() {
            do {
                try engine.start()
                print("Filter example started")
            } catch {
                print("Failed to start filter example: \(error)")
                // 尝试重新配置
                setupFilters()
                do {
                    try engine.start()
                    print("Filter example restarted successfully")
                } catch {
                    print("Failed to restart filter example: \(error)")
                }
            }
        }
        
        func stop() {
            engine.stop()
            print("Filter example stopped")
        }
        
        func play() {
            oscillator.start()
        }
        
        func pause() {
            oscillator.stop()
        }
        
        func setLowPassCutoff(_ frequency: Float) {
            lowPassFilter.cutoffFrequency = frequency
        }
        
        func setHighPassCutoff(_ frequency: Float) {
            highPassFilter.cutoffFrequency = frequency
        }
    }
    
    // MARK: - 失真效果示例
    class DistortionExample: NSObject {
        let engine = AudioEngine()
        var oscillator: Oscillator!
        var distortion: TanhDistortion!
        
        override init() {
            super.init()
            setupDistortion()
        }
        
        private func setupDistortion() {
            // 先创建振荡器
            oscillator = Oscillator()
            oscillator.amplitude = 0.1
            oscillator.frequency = 440.0
            
            // 然后创建失真效果器
            distortion = TanhDistortion(oscillator)
            distortion.pregain = 1.0
            distortion.postgain = 1.0
            distortion.positiveShapeParameter = 0.0
            distortion.negativeShapeParameter = 0.0
            
            engine.output = distortion
        }
        
        func start() {
            do {
                try engine.start()
                print("Distortion example started")
            } catch {
                print("Failed to start distortion example: \(error)")
                // 尝试重新配置
                setupDistortion()
                do {
                    try engine.start()
                    print("Distortion example restarted successfully")
                } catch {
                    print("Failed to restart distortion example: \(error)")
                }
            }
        }
        
        func stop() {
            engine.stop()
            print("Distortion example stopped")
        }
        
        func play() {
            oscillator.start()
        }
        
        func pause() {
            oscillator.stop()
        }
        
        func setPregain(_ gain: Float) {
            distortion.pregain = gain
        }
        
        func setPostgain(_ gain: Float) {
            distortion.postgain = gain
        }
    }
    
    // MARK: - 物理建模示例
    class PhysicalModelExample: NSObject {
        let engine = AudioEngine()
        var pluckedString = PluckedString()
        
        override init() {
            super.init()
            setupPluckedString()
        }
        
        private func setupPluckedString() {
            pluckedString.frequency = 440.0
            pluckedString.amplitude = 0.2
            engine.output = pluckedString
        }
        
        func start() {
            do {
                try engine.start()
                print("Physical model example started")
            } catch {
                print("Failed to start physical model example: \(error)")
                // 尝试重新配置
                setupPluckedString()
                do {
                    try engine.start()
                    print("Physical model example restarted successfully")
                } catch {
                    print("Failed to restart physical model example: \(error)")
                }
            }
        }
        
        func stop() {
            engine.stop()
            print("Physical model example stopped")
        }
        
        func pluck() {
            pluckedString.trigger()
        }
        
        func setFrequency(_ frequency: Float) {
            pluckedString.frequency = frequency
        }
    }
}

// MARK: - 高级控制面板
class AdvancedAudioKitControlPanel: NSView {
    private var fmOscillatorExample: AdvancedAudioKitExamples.FMOscillatorExample?
    private var filterExample: AdvancedAudioKitExamples.FilterExample?
    private var distortionExample: AdvancedAudioKitExamples.DistortionExample?
    private var physicalModelExample: AdvancedAudioKitExamples.PhysicalModelExample?
    
    private let tabView = NSTabView()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
        setupAudioExamples()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupAudioExamples()
    }
    
    private func setupAudioExamples() {
        fmOscillatorExample = AdvancedAudioKitExamples.FMOscillatorExample()
        filterExample = AdvancedAudioKitExamples.FilterExample()
        distortionExample = AdvancedAudioKitExamples.DistortionExample()
        physicalModelExample = AdvancedAudioKitExamples.PhysicalModelExample()
        
        // 延迟启动所有音频引擎，避免启动时的参数错误
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.fmOscillatorExample?.start()
            self.filterExample?.start()
            self.distortionExample?.start()
            self.physicalModelExample?.start()
        }
    }
    
    private func setupUI() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        // 设置标签视图
        tabView.frame = bounds
        tabView.autoresizingMask = [.width, .height]
        addSubview(tabView)
        
        // 添加各个标签页
        tabView.addTabViewItem(createFMOscillatorTab())
        tabView.addTabViewItem(createFilterTab())
        tabView.addTabViewItem(createDistortionTab())
        tabView.addTabViewItem(createPhysicalModelTab())
    }
    
    private func createFMOscillatorTab() -> NSTabViewItem {
        let tabViewItem = NSTabViewItem()
        tabViewItem.label = "FM Oscillator"
        
        let view = NSView()
        
        // 基础频率滑块
        let baseFreqLabel = NSTextField(labelWithString: "Base Frequency:")
        baseFreqLabel.frame = NSRect(x: 20, y: 200, width: 120, height: 20)
        view.addSubview(baseFreqLabel)
        
        let baseFreqSlider = NSSlider()
        baseFreqSlider.frame = NSRect(x: 150, y: 200, width: 200, height: 20)
        baseFreqSlider.minValue = 20.0
        baseFreqSlider.maxValue = 2000.0
        baseFreqSlider.doubleValue = 440.0
        baseFreqSlider.target = self
        baseFreqSlider.action = #selector(fmBaseFrequencyChanged)
        view.addSubview(baseFreqSlider)
        
        // 调制指数滑块
        let modIndexLabel = NSTextField(labelWithString: "Modulation Index:")
        modIndexLabel.frame = NSRect(x: 20, y: 170, width: 120, height: 20)
        view.addSubview(modIndexLabel)
        
        let modIndexSlider = NSSlider()
        modIndexSlider.frame = NSRect(x: 150, y: 170, width: 200, height: 20)
        modIndexSlider.minValue = 0.0
        modIndexSlider.maxValue = 10.0
        modIndexSlider.doubleValue = 3.0
        modIndexSlider.target = self
        modIndexSlider.action = #selector(fmModulationIndexChanged)
        view.addSubview(modIndexSlider)
        
        // 播放按钮
        let playButton = NSButton()
        playButton.frame = NSRect(x: 20, y: 130, width: 80, height: 30)
        playButton.title = "Play"
        playButton.bezelStyle = .rounded
        playButton.target = self
        playButton.action = #selector(fmPlayButtonClicked)
        view.addSubview(playButton)
        
        // 停止按钮
        let stopButton = NSButton()
        stopButton.frame = NSRect(x: 110, y: 130, width: 80, height: 30)
        stopButton.title = "Stop"
        stopButton.bezelStyle = .rounded
        stopButton.target = self
        stopButton.action = #selector(fmStopButtonClicked)
        view.addSubview(stopButton)
        
        tabViewItem.view = view
        return tabViewItem
    }
    
    private func createFilterTab() -> NSTabViewItem {
        let tabViewItem = NSTabViewItem()
        tabViewItem.label = "Filters"
        
        let view = NSView()
        
        // 低通滤波器截止频率
        let lowPassLabel = NSTextField(labelWithString: "Low Pass Cutoff:")
        lowPassLabel.frame = NSRect(x: 20, y: 200, width: 120, height: 20)
        view.addSubview(lowPassLabel)
        
        let lowPassSlider = NSSlider()
        lowPassSlider.frame = NSRect(x: 150, y: 200, width: 200, height: 20)
        lowPassSlider.minValue = 20.0
        lowPassSlider.maxValue = 20000.0
        lowPassSlider.doubleValue = 1000.0
        lowPassSlider.target = self
        lowPassSlider.action = #selector(lowPassCutoffChanged)
        view.addSubview(lowPassSlider)
        
        // 高通滤波器截止频率
        let highPassLabel = NSTextField(labelWithString: "High Pass Cutoff:")
        highPassLabel.frame = NSRect(x: 20, y: 170, width: 120, height: 20)
        view.addSubview(highPassLabel)
        
        let highPassSlider = NSSlider()
        highPassSlider.frame = NSRect(x: 150, y: 170, width: 200, height: 20)
        highPassSlider.minValue = 20.0
        highPassSlider.maxValue = 20000.0
        highPassSlider.doubleValue = 200.0
        highPassSlider.target = self
        highPassSlider.action = #selector(highPassCutoffChanged)
        view.addSubview(highPassSlider)
        
        // 播放按钮
        let playButton = NSButton()
        playButton.frame = NSRect(x: 20, y: 130, width: 80, height: 30)
        playButton.title = "Play"
        playButton.bezelStyle = .rounded
        playButton.target = self
        playButton.action = #selector(filterPlayButtonClicked)
        view.addSubview(playButton)
        
        // 停止按钮
        let stopButton = NSButton()
        stopButton.frame = NSRect(x: 110, y: 130, width: 80, height: 30)
        stopButton.title = "Stop"
        stopButton.bezelStyle = .rounded
        stopButton.target = self
        stopButton.action = #selector(filterStopButtonClicked)
        view.addSubview(stopButton)
        
        tabViewItem.view = view
        return tabViewItem
    }
    
    private func createDistortionTab() -> NSTabViewItem {
        let tabViewItem = NSTabViewItem()
        tabViewItem.label = "Distortion"
        
        let view = NSView()
        
        // 前置增益
        let pregainLabel = NSTextField(labelWithString: "Pre-gain:")
        pregainLabel.frame = NSRect(x: 20, y: 200, width: 120, height: 20)
        view.addSubview(pregainLabel)
        
        let pregainSlider = NSSlider()
        pregainSlider.frame = NSRect(x: 150, y: 200, width: 200, height: 20)
        pregainSlider.minValue = 0.0
        pregainSlider.maxValue = 10.0
        pregainSlider.doubleValue = 1.0
        pregainSlider.target = self
        pregainSlider.action = #selector(pregainChanged)
        view.addSubview(pregainSlider)
        
        // 后置增益
        let postgainLabel = NSTextField(labelWithString: "Post-gain:")
        postgainLabel.frame = NSRect(x: 20, y: 170, width: 120, height: 20)
        view.addSubview(postgainLabel)
        
        let postgainSlider = NSSlider()
        postgainSlider.frame = NSRect(x: 150, y: 170, width: 200, height: 20)
        postgainSlider.minValue = 0.0
        postgainSlider.maxValue = 10.0
        postgainSlider.doubleValue = 1.0
        postgainSlider.target = self
        postgainSlider.action = #selector(postgainChanged)
        view.addSubview(postgainSlider)
        
        // 播放按钮
        let playButton = NSButton()
        playButton.frame = NSRect(x: 20, y: 130, width: 80, height: 30)
        playButton.title = "Play"
        playButton.bezelStyle = .rounded
        playButton.target = self
        playButton.action = #selector(distortionPlayButtonClicked)
        view.addSubview(playButton)
        
        // 停止按钮
        let stopButton = NSButton()
        stopButton.frame = NSRect(x: 110, y: 130, width: 80, height: 30)
        stopButton.title = "Stop"
        stopButton.bezelStyle = .rounded
        stopButton.target = self
        stopButton.action = #selector(distortionStopButtonClicked)
        view.addSubview(stopButton)
        
        tabViewItem.view = view
        return tabViewItem
    }
    
    private func createPhysicalModelTab() -> NSTabViewItem {
        let tabViewItem = NSTabViewItem()
        tabViewItem.label = "Physical Model"
        
        let view = NSView()
        
        // 频率滑块
        let freqLabel = NSTextField(labelWithString: "Frequency:")
        freqLabel.frame = NSRect(x: 20, y: 200, width: 120, height: 20)
        view.addSubview(freqLabel)
        
        let freqSlider = NSSlider()
        freqSlider.frame = NSRect(x: 150, y: 200, width: 200, height: 20)
        freqSlider.minValue = 20.0
        freqSlider.maxValue = 2000.0
        freqSlider.doubleValue = 440.0
        freqSlider.target = self
        freqSlider.action = #selector(physicalModelFrequencyChanged)
        view.addSubview(freqSlider)
        
        // 拨弦按钮
        let pluckButton = NSButton()
        pluckButton.frame = NSRect(x: 20, y: 130, width: 80, height: 30)
        pluckButton.title = "Pluck"
        pluckButton.bezelStyle = .rounded
        pluckButton.target = self
        pluckButton.action = #selector(pluckButtonClicked)
        view.addSubview(pluckButton)
        
        tabViewItem.view = view
        return tabViewItem
    }
    
    // MARK: - FM Oscillator 事件处理
    @objc private func fmBaseFrequencyChanged(_ sender: NSSlider) {
        let frequency = Float(sender.doubleValue)
        fmOscillatorExample?.setBaseFrequency(frequency)
    }
    
    @objc private func fmModulationIndexChanged(_ sender: NSSlider) {
        let index = Float(sender.doubleValue)
        fmOscillatorExample?.setModulationIndex(index)
    }
    
    @objc private func fmPlayButtonClicked() {
        fmOscillatorExample?.play()
    }
    
    @objc private func fmStopButtonClicked() {
        fmOscillatorExample?.pause()
    }
    
    // MARK: - Filter 事件处理
    @objc private func lowPassCutoffChanged(_ sender: NSSlider) {
        let frequency = Float(sender.doubleValue)
        filterExample?.setLowPassCutoff(frequency)
    }
    
    @objc private func highPassCutoffChanged(_ sender: NSSlider) {
        let frequency = Float(sender.doubleValue)
        filterExample?.setHighPassCutoff(frequency)
    }
    
    @objc private func filterPlayButtonClicked() {
        filterExample?.play()
    }
    
    @objc private func filterStopButtonClicked() {
        filterExample?.pause()
    }
    
    // MARK: - Distortion 事件处理
    @objc private func pregainChanged(_ sender: NSSlider) {
        let gain = Float(sender.doubleValue)
        distortionExample?.setPregain(gain)
    }
    
    @objc private func postgainChanged(_ sender: NSSlider) {
        let gain = Float(sender.doubleValue)
        distortionExample?.setPostgain(gain)
    }
    
    @objc private func distortionPlayButtonClicked() {
        distortionExample?.play()
    }
    
    @objc private func distortionStopButtonClicked() {
        distortionExample?.pause()
    }
    
    // MARK: - Physical Model 事件处理
    @objc private func physicalModelFrequencyChanged(_ sender: NSSlider) {
        let frequency = Float(sender.doubleValue)
        physicalModelExample?.setFrequency(frequency)
    }
    
    @objc private func pluckButtonClicked() {
        physicalModelExample?.pluck()
    }
    
    deinit {
        fmOscillatorExample?.stop()
        filterExample?.stop()
        distortionExample?.stop()
        physicalModelExample?.stop()
    }
} 
