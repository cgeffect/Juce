import AudioKit
import SoundpipeAudioKit
import AudioKitEX
import AudioToolbox
import AppKit

// MARK: - 基础音频引擎管理器
class AudioKitManager: NSObject {
    static let shared = AudioKitManager()
    
    let engine = AudioEngine()
    var isRunning = false
    
    private override init() {
        super.init()
    }
    
    func start() {
        guard !isRunning else { return }
        do {
            try engine.start()
            isRunning = true
            print("AudioKit engine started")
        } catch {
            print("Failed to start AudioKit engine: \(error)")
        }
    }
    
    func stop() {
        guard isRunning else { return }
        engine.stop()
        isRunning = false
        print("AudioKit engine stopped")
    }
}

// MARK: - 振荡器示例
class OscillatorExample: NSObject {
    let engine = AudioEngine()
    var oscillator = Oscillator()
    
    override init() {
        super.init()
        setupOscillator()
    }
    
    private func setupOscillator() {
        oscillator.amplitude = 0.2
        oscillator.frequency = 440.0
        engine.output = oscillator
    }
    
    func start() {
        do {
            try engine.start()
            print("Oscillator started")
        } catch {
            print("Failed to start oscillator: \(error)")
            // 尝试重新配置
            setupOscillator()
            do {
                try engine.start()
                print("Oscillator restarted successfully")
            } catch {
                print("Failed to restart oscillator: \(error)")
            }
        }
    }
    
    func stop() {
        engine.stop()
        print("Oscillator stopped")
    }
    
    func play() {
        oscillator.start()
    }
    
    func pause() {
        oscillator.stop()
    }
    
    func setFrequency(_ frequency: Float) {
        oscillator.frequency = frequency
    }
    
    func setAmplitude(_ amplitude: Float) {
        oscillator.amplitude = amplitude
    }
}

// MARK: - 音频播放器示例
class AudioPlayerExample: NSObject {
    let engine = AudioEngine()
    var player = AudioPlayer()
    
    override init() {
        super.init()
        setupPlayer()
    }
    
    private func setupPlayer() {
        engine.output = player
        
        // 设置完成回调
        player.completionHandler = { [weak self] in
            DispatchQueue.main.async {
                print("Audio playback completed")
                // 可以在这里添加播放下一首的逻辑
            }
        }
    }
    
    func start() {
        do {
            try engine.start()
            print("Audio player engine started")
        } catch {
            print("Failed to start audio player: \(error)")
            // 尝试重新配置
            setupPlayer()
            do {
                try engine.start()
                print("Audio player engine restarted successfully")
            } catch {
                print("Failed to restart audio player: \(error)")
            }
        }
    }
    
    func stop() {
        engine.stop()
        print("Audio player engine stopped")
    }
    
    func loadAndPlay(url: URL) {
        do {
            try player.load(url: url)
            player.play()
            print("Playing: \(url.lastPathComponent)")
        } catch {
            print("Failed to load audio file: \(error)")
        }
    }
    
    func pause() {
        player.pause()
    }
    
    func resume() {
        player.resume()
    }
    
    func stopPlayback() {
        player.stop()
    }
}

// MARK: - 效果器示例
class EffectsExample: NSObject {
    let engine = AudioEngine()
    var oscillator: Oscillator!
    var reverb: Reverb!
    var delay: Delay!
    
    override init() {
        super.init()
        setupEffects()
    }
    
    private func setupEffects() {
        // 先创建振荡器
        oscillator = Oscillator()
        oscillator.amplitude = 0.1
        oscillator.frequency = 440.0
        
        // 然后创建效果器
        reverb = Reverb(oscillator)
        reverb.dryWetMix = 0.5
        
        // 使用安全的参数值
                    delay = Delay(reverb, time: 0.1, feedback: 0.3, lowPassCutoff: 15000, dryWetMix: 50)
        
        engine.output = delay
    }
    
    func start() {
        do {
            // 确保音频引擎在启动前已经正确配置
            try engine.start()
            print("Effects engine started")
        } catch {
            print("Failed to start effects engine: \(error)")
            // 尝试重新配置音频引擎
            setupEffects()
            do {
                try engine.start()
                print("Effects engine restarted successfully")
            } catch {
                print("Failed to restart effects engine: \(error)")
            }
        }
    }
    
    func stop() {
        engine.stop()
        print("Effects engine stopped")
    }
    
    func play() {
        oscillator.start()
    }
    
    func pause() {
        oscillator.stop()
    }
    
    func setReverbMix(_ mix: Float) {
        reverb.dryWetMix = mix
    }
    
    func setDelayTime(_ time: Float) {
        delay.time = time
    }
    
    func setDelayFeedback(_ feedback: Float) {
        delay.feedback = feedback
    }
}

// MARK: - AppKit UI 组件
class AudioKitControlPanel: NSView {
    private var oscillatorExample: OscillatorExample?
    private var audioPlayerExample: AudioPlayerExample?
    private var effectsExample: EffectsExample?
    
    private let frequencySlider = NSSlider()
    private let amplitudeSlider = NSSlider()
    private let playButton = NSButton()
    private let stopButton = NSButton()
    private let reverbMixSlider = NSSlider()
    private let delayTimeSlider = NSSlider()
    
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
        // 不在这里创建音频示例，而是在需要时懒加载
        // 这样可以避免启动时同时创建多个音频引擎
    }
    
    private func setupUI() {
        // 设置背景色
        wantsLayer = true
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        // 频率滑块
        let frequencyLabel = NSTextField(labelWithString: "Frequency:")
        frequencyLabel.frame = NSRect(x: 20, y: 200, width: 80, height: 20)
        addSubview(frequencyLabel)
        
        frequencySlider.frame = NSRect(x: 110, y: 200, width: 200, height: 20)
        frequencySlider.minValue = 20.0
        frequencySlider.maxValue = 2000.0
        frequencySlider.doubleValue = 440.0
        frequencySlider.target = self
        frequencySlider.action = #selector(frequencyChanged)
        addSubview(frequencySlider)
        
        // 振幅滑块
        let amplitudeLabel = NSTextField(labelWithString: "Amplitude:")
        amplitudeLabel.frame = NSRect(x: 20, y: 170, width: 80, height: 20)
        addSubview(amplitudeLabel)
        
        amplitudeSlider.frame = NSRect(x: 110, y: 170, width: 200, height: 20)
        amplitudeSlider.minValue = 0.0
        amplitudeSlider.maxValue = 1.0
        amplitudeSlider.doubleValue = 0.2
        amplitudeSlider.target = self
        amplitudeSlider.action = #selector(amplitudeChanged)
        addSubview(amplitudeSlider)
        
        // 播放按钮
        playButton.frame = NSRect(x: 20, y: 130, width: 80, height: 30)
        playButton.title = "Play"
        playButton.bezelStyle = .rounded
        playButton.target = self
        playButton.action = #selector(playButtonClicked)
        addSubview(playButton)
        
        // 停止按钮
        stopButton.frame = NSRect(x: 110, y: 130, width: 80, height: 30)
        stopButton.title = "Stop"
        stopButton.bezelStyle = .rounded
        stopButton.target = self
        stopButton.action = #selector(stopButtonClicked)
        addSubview(stopButton)
        
        // 混响混合滑块
        let reverbLabel = NSTextField(labelWithString: "Reverb Mix:")
        reverbLabel.frame = NSRect(x: 20, y: 100, width: 80, height: 20)
        addSubview(reverbLabel)
        
        reverbMixSlider.frame = NSRect(x: 110, y: 100, width: 200, height: 20)
        reverbMixSlider.minValue = 0.0
        reverbMixSlider.maxValue = 1.0
        reverbMixSlider.doubleValue = 0.5
        reverbMixSlider.target = self
        reverbMixSlider.action = #selector(reverbMixChanged)
        addSubview(reverbMixSlider)
        
        // 延迟时间滑块
        let delayLabel = NSTextField(labelWithString: "Delay Time:")
        delayLabel.frame = NSRect(x: 20, y: 70, width: 80, height: 20)
        addSubview(delayLabel)
        
        delayTimeSlider.frame = NSRect(x: 110, y: 70, width: 200, height: 20)
        delayTimeSlider.minValue = 0.0
        delayTimeSlider.maxValue = 1.0
        delayTimeSlider.doubleValue = 0.1
        delayTimeSlider.target = self
        delayTimeSlider.action = #selector(delayTimeChanged)
        addSubview(delayTimeSlider)
        
        // 标题
        let titleLabel = NSTextField(labelWithString: "AudioKit Examples")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 16)
        titleLabel.frame = NSRect(x: 20, y: 250, width: 300, height: 30)
        addSubview(titleLabel)
    }
    
    // MARK: - 懒加载音频示例
    
    private func ensureOscillatorExample() {
        if oscillatorExample == nil {
            oscillatorExample = OscillatorExample()
            oscillatorExample?.start()
            print("Oscillator example created and started")
        }
    }
    
    private func ensureEffectsExample() {
        if effectsExample == nil {
            effectsExample = EffectsExample()
            effectsExample?.start()
            print("Effects example created and started")
        }
    }
    
    private func ensureAudioPlayerExample() {
        if audioPlayerExample == nil {
            audioPlayerExample = AudioPlayerExample()
            audioPlayerExample?.start()
            print("Audio player example created and started")
        }
    }
    
    @objc private func frequencyChanged() {
        let frequency = Float(frequencySlider.doubleValue)
        ensureOscillatorExample()
        oscillatorExample?.setFrequency(frequency)
        ensureEffectsExample()
        effectsExample?.play() // 重新开始播放以应用新频率
    }
    
    @objc private func amplitudeChanged() {
        let amplitude = Float(amplitudeSlider.doubleValue)
        ensureOscillatorExample()
        oscillatorExample?.setAmplitude(amplitude)
    }
    
    @objc private func playButtonClicked() {
        ensureOscillatorExample()
        oscillatorExample?.play()
        ensureEffectsExample()
        effectsExample?.play()
    }
    
    @objc private func stopButtonClicked() {
        oscillatorExample?.pause()
        effectsExample?.pause()
    }
    
    @objc private func reverbMixChanged() {
        let mix = Float(reverbMixSlider.doubleValue)
        ensureEffectsExample()
        effectsExample?.setReverbMix(mix)
    }
    
    @objc private func delayTimeChanged() {
        let time = Float(delayTimeSlider.doubleValue)
        ensureEffectsExample()
        effectsExample?.setDelayTime(time)
    }
    
    deinit {
        oscillatorExample?.stop()
        audioPlayerExample?.stop()
        effectsExample?.stop()
    }
} 
