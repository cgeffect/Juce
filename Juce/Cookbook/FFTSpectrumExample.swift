import AppKit
import AVFoundation
import AudioKit
import AudioKitEX
import Accelerate

// MARK: - FFT频谱分析器示例
class FFTSpectrumExample: NSObject {
    let engine = AudioEngine()
    var player = AudioPlayer()
    var fftTap: FFTTap!
    var spectrumView: FFTSpectrumView!
    
    private var isPlaying = false
    private var fftData: [Float] = []
    private let fftSize = 1024
    private let sampleRate: Double = 44100.0
    
    override init() {
        super.init()
        setupAudioEngine()
        setupSpectrumView()
    }
    
    private func setupAudioEngine() {
        // 创建FFT Tap来获取音频数据
        fftTap = FFTTap(player, bufferSize: 1024, callbackQueue: .main) { [weak self] fftData in
            self?.updateSpectrum(fftData)
        }
        
        // 设置音频链：player -> engine
        engine.output = player
        
        // 设置完成回调
        player.completionHandler = { [weak self] in
            DispatchQueue.main.async {
                self?.isPlaying = false
                print("FFT Spectrum playback completed")
            }
        }
    }
    

    
    private func setupSpectrumView() {
        spectrumView = FFTSpectrumView(frame: NSRect(x: 0, y: 0, width: 400, height: 200))
        spectrumView.backgroundColor = NSColor.black
    }
    
    func start() {
        do {
            try engine.start()
            // 延迟启动 FFT Tap，确保视图已准备好
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.fftTap.start()
                print("FFT Spectrum engine started")
            }
        } catch {
            print("Failed to start FFT spectrum engine: \(error)")
            // 尝试重新配置
            setupAudioEngine()
            do {
                try engine.start()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.fftTap.start()
                    print("FFT Spectrum engine restarted successfully")
                }
            } catch {
                print("Failed to restart FFT spectrum engine: \(error)")
            }
        }
    }
    
    func stop() {
        fftTap.stop()
        engine.stop()
        print("FFT Spectrum engine stopped")
    }
    
    func loadAndPlay(url: URL) {
        do {
            try player.load(url: url)
            player.play()
            isPlaying = true
            print("Playing with FFT spectrum: \(url.lastPathComponent)")
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
    
    private func updateSpectrum(_ fftData: [Float]) {
        // 验证 FFT 数据有效性
        let validData = fftData.compactMap { value -> Float? in
            if value.isNaN || value.isInfinite {
                return nil
            }
            return max(0.0, value) // 确保值非负
        }
        
        // 确保有有效数据
        guard !validData.isEmpty else { return }
        
        DispatchQueue.main.async {
            self.spectrumView.updateSpectrum(validData)
        }
    }
    

}

// MARK: - FFT频谱显示视图
class FFTSpectrumView: NSView {
    var backgroundColor: NSColor = NSColor.black { didSet { needsDisplay = true } }
    var spectrumColor: NSColor = NSColor.green { didSet { needsDisplay = true } }
    var gridColor: NSColor = NSColor.darkGray { didSet { needsDisplay = true } }
    
    private var spectrumData: [Float] = []
    private var smoothedData: [Float] = []
    private var peakData: [Float] = []
    private var maxSpectrumValue: Float = 1.0
    private let smoothingFactor: Float = 0.3 // 平滑因子
    private let peakDecayFactor: Float = 0.95 // 峰值衰减因子
    
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
    
    func updateSpectrum(_ data: [Float]) {
        // 验证数据有效性，过滤掉 NaN 和无穷大值
        let validData = data.compactMap { value -> Float? in
            if value.isNaN || value.isInfinite {
                return 0.0
            }
            return max(0.0, value) // 确保值非负
        }
        
        spectrumData = validData
        
        // 应用平滑效果
        if smoothedData.isEmpty {
            smoothedData = validData
        } else {
            // 确保数组长度匹配
            let minCount = min(validData.count, smoothedData.count)
            if smoothedData.count != minCount {
                smoothedData = Array(smoothedData.prefix(minCount))
            }
            
            for i in 0..<minCount {
                let newValue = validData[i]
                let oldValue = smoothedData[i]
                if !newValue.isNaN && !oldValue.isNaN {
                    smoothedData[i] = oldValue * (1.0 - smoothingFactor) + newValue * smoothingFactor
                }
            }
        }
        
        // 更新峰值数据
        if peakData.isEmpty {
            peakData = smoothedData
        } else {
            // 确保数组长度匹配
            let minCount = min(smoothedData.count, peakData.count)
            if peakData.count != minCount {
                peakData = Array(peakData.prefix(minCount))
            }
            
            for i in 0..<minCount {
                let currentValue = smoothedData[i]
                let peakValue = peakData[i]
                if !currentValue.isNaN && !peakValue.isNaN {
                    if currentValue > peakValue {
                        peakData[i] = currentValue
                    } else {
                        peakData[i] *= peakDecayFactor
                    }
                }
            }
        }
        
        // 计算最大值，避免 NaN
        let validMax = smoothedData.compactMap { value -> Float? in
            if value.isNaN || value.isInfinite {
                return nil
            }
            return value
        }.max() ?? 1.0
        
        maxSpectrumValue = max(validMax, 0.001) // 避免除零
        needsDisplay = true
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        context.setFillColor(backgroundColor.cgColor)
        context.fill(bounds)
        
        drawGrid(context: context)
        drawSpectrum(context: context)
        drawLabels(context: context)
    }
    
    private func drawGrid(context: CGContext) {
        let width = bounds.width
        let height = bounds.height
        
        context.setStrokeColor(gridColor.cgColor)
        context.setLineWidth(0.5)
        
        // 绘制水平网格线
        let horizontalLines = 10
        for i in 0...horizontalLines {
            let y = height * CGFloat(i) / CGFloat(horizontalLines)
            context.beginPath()
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: width, y: y))
            context.strokePath()
        }
        
        // 绘制垂直网格线（频率标记）
        let verticalLines = 8
        for i in 0...verticalLines {
            let x = width * CGFloat(i) / CGFloat(verticalLines)
            context.beginPath()
            context.move(to: CGPoint(x: x, y: 0))
            context.addLine(to: CGPoint(x: x, y: height))
            context.strokePath()
        }
    }
    
    private func drawSpectrum(context: CGContext) {
        guard !spectrumData.isEmpty else { return }
        
        let width = bounds.width
        let height = bounds.height
        
        // 只显示前一半的FFT数据（因为FFT是对称的）
        let displayCount = min(spectrumData.count / 2, 256)
        guard displayCount > 0 else { return }
        
        let barWidth = width / CGFloat(displayCount)
        
        for index in 0..<displayCount {
            // 安全获取数据值
            let value: Float
            if smoothedData.isEmpty || index >= smoothedData.count {
                value = index < spectrumData.count ? spectrumData[index] : 0.0
            } else {
                value = smoothedData[index]
            }
            
            // 验证值有效性
            guard !value.isNaN && !value.isInfinite else { continue }
            
            let normalizedValue = value / maxSpectrumValue
            let barHeight = height * CGFloat(normalizedValue)
            let x = CGFloat(index) * barWidth
            let y: CGFloat = 0 // 从底部开始绘制
            
            // 确保坐标有效
            guard !x.isNaN && !y.isNaN && !barHeight.isNaN else { continue }
            
            // 根据频率位置创建颜色渐变
            let hue = CGFloat(index) / CGFloat(displayCount) * 0.7 // 从红色到青色
            let color = NSColor(hue: hue, saturation: 0.8, brightness: 0.8, alpha: 1.0)
            context.setFillColor(color.cgColor)
            
            let barRect = NSRect(x: x, y: y, width: barWidth * 0.8, height: barHeight)
            context.fill(barRect)
            
            // 绘制峰值线
            if !peakData.isEmpty && index < peakData.count {
                let peakValue = peakData[index]
                guard !peakValue.isNaN && !peakValue.isInfinite else { continue }
                
                let peakNormalizedValue = peakValue / maxSpectrumValue
                let peakHeight = height * CGFloat(peakNormalizedValue)
                let peakY = peakHeight // 峰值线从底部开始
                
                // 确保峰值坐标有效
                guard !peakY.isNaN else { continue }
                
                context.setStrokeColor(NSColor.white.cgColor)
                context.setLineWidth(1.0)
                context.beginPath()
                context.move(to: CGPoint(x: x, y: peakY))
                context.addLine(to: CGPoint(x: x + barWidth * 0.8, y: peakY))
                context.strokePath()
            }
        }
    }
    
    private func drawLabels(context: CGContext) {
        let width = bounds.width
        let height = bounds.height
        
        // 确保尺寸有效
        guard width > 0 && height > 0 else { return }
        
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10),
            .foregroundColor: NSColor.white
        ]
        
        // 绘制频率标签
        let sampleRate: Double = 44100.0
        let maxFreq = sampleRate / 2.0 // 奈奎斯特频率
        
        let frequencies = [0, 1000, 2000, 4000, 8000, 16000, 22050]
        for (index, freq) in frequencies.enumerated() {
            let normalizedFreq = Double(freq) / maxFreq
            let x = width * CGFloat(normalizedFreq)
            
            // 确保坐标在有效范围内
            guard x >= 0 && x <= width else { continue }
            
            let label = freq >= 1000 ? "\(freq/1000)k" : "\(freq)"
            let labelSize = label.size(withAttributes: labelAttributes)
            let labelX = x - labelSize.width/2
            let labelY: CGFloat = 5
            
            // 确保标签位置有效
            guard !labelX.isNaN && !labelY.isNaN else { continue }
            
            label.draw(at: CGPoint(x: labelX, y: labelY), withAttributes: labelAttributes)
        }
        
        // 绘制标题
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 12),
            .foregroundColor: NSColor.white
        ]
        let title = "实时频谱分析"
        let titleSize = title.size(withAttributes: titleAttributes)
        let titleX = (width - titleSize.width)/2
        let titleY = height - 20
        
        // 确保标题位置有效
        guard !titleX.isNaN && !titleY.isNaN else { return }
        
        title.draw(at: CGPoint(x: titleX, y: titleY), withAttributes: titleAttributes)
    }
}

// MARK: - FFT频谱控制面板
class FFTSpectrumControlPanel: NSView {
    private var fftExample: FFTSpectrumExample!
    private var spectrumView: FFTSpectrumView!
    
    // UI 组件
    private let playButton = NSButton()
    private let pauseButton = NSButton()
    private let stopButton = NSButton()
    private let openButton = NSButton()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupFFTExample()
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupFFTExample()
        setupUI()
    }
    
    private func setupFFTExample() {
        fftExample = FFTSpectrumExample()
        fftExample.start()
        spectrumView = fftExample.spectrumView
    }
    
    private func setupUI() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        // 设置频谱视图在上方，避免遮挡标签切换按钮
        // y 坐标从底部开始计算，需要给底部按钮留出空间
        spectrumView.frame = NSRect(x: 20, y: 80, width: 1100, height: 450)
        addSubview(spectrumView)
        
        setupButtons()
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
    

    
    private func setupLayout() {
        let buttonWidth: CGFloat = 100
        let buttonHeight: CGFloat = 35
        let spacing: CGFloat = 15
        let startX: CGFloat = 20
        let startY: CGFloat = 20
        
        // 控制按钮布局在底部
        openButton.frame = NSRect(x: startX, y: startY, width: buttonWidth, height: buttonHeight)
        playButton.frame = NSRect(x: startX + buttonWidth + spacing, y: startY, width: buttonWidth, height: buttonHeight)
        pauseButton.frame = NSRect(x: startX + (buttonWidth + spacing) * 2, y: startY, width: buttonWidth, height: buttonHeight)
        stopButton.frame = NSRect(x: startX + (buttonWidth + spacing) * 3, y: startY, width: buttonWidth, height: buttonHeight)
    }
    
    @objc private func openAudioFile() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.audio, .mp3, .wav, .aiff]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        
        openPanel.begin { [weak self] result in
            if result == .OK, let url = openPanel.url {
                self?.fftExample.loadAndPlay(url: url)
            }
        }
    }
    
    @objc private func playAudio() {
        fftExample.resume()
    }
    
    @objc private func pauseAudio() {
        fftExample.pause()
    }
    
    @objc private func stopAudio() {
        fftExample.stopPlayback()
    }
    
    deinit {
        fftExample.stop()
    }
} 
