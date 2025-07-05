import AppKit
import AVFoundation
import AudioKit
import AudioKitEX

// MARK: - 音频播放器与波形显示示例
class AudioPlayerWithWaveformExample: NSObject {
    let engine = AudioEngine()
    var player = AudioPlayer()
    var fftTap: FFTTap!
    var waveformView: WaveformView!
    
    // 音频数据用于波形显示
    private var leftChannelData: [Float] = []
    private var rightChannelData: [Float] = []
    private var isPlaying = false
    
    override init() {
        super.init()
        setupAudioEngine()
        setupWaveformView()
    }
    
    private func setupAudioEngine() {
        engine.output = player
        player.completionHandler = { [weak self] in
            DispatchQueue.main.async {
                self?.isPlaying = false
                self?.waveformView?.updatePlaybackPosition(0.0)
                print("Audio playback completed")
            }
        }
        fftTap = FFTTap(player) { fftData in
            DispatchQueue.main.async {
                self.updateSpectrum(fftData)
            }
        }
    }
    
    private func setupWaveformView() {
        waveformView = WaveformView(frame: NSRect(x: 0, y: 0, width: 400, height: 200))
        waveformView.backgroundColor = NSColor.black
        waveformView.leftWaveformColor = NSColor.green
        waveformView.rightWaveformColor = NSColor.cyan
        waveformView.cursorColor = NSColor.red
    }
    
    func start() {
        do {
            try engine.start()
            fftTap.start()
            print("Audio player with waveform engine started")
        } catch {
            print("Failed to start audio player: \(error)")
            // 尝试重新配置
            setupAudioEngine()
            do {
                try engine.start()
                fftTap.start()
                print("Audio player with waveform engine restarted successfully")
            } catch {
                print("Failed to restart audio player: \(error)")
            }
        }
    }
    
    func stop() {
        engine.stop()
        fftTap.stop()
        print("Audio player with waveform engine stopped")
    }
    
    func loadAndPlay(url: URL) {
        do {
            try player.load(url: url)
            extractWaveformData(from: url)
            player.play()
            isPlaying = true
            startPlaybackPositionUpdate()
            print("Playing: \(url.lastPathComponent)")
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
        waveformView?.updatePlaybackPosition(0.0)
    }
    
    // 提取音频文件的左右声道波形数据
    private func extractWaveformData(from url: URL) {
        do {
            let audioFile = try AVAudioFile(forReading: url)
            let format = audioFile.processingFormat
            let frameCount = UInt32(audioFile.length)
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
            try audioFile.read(into: buffer)
            let channelCount = Int(format.channelCount)
            if channelCount >= 2,
               let left = buffer.floatChannelData?[0],
               let right = buffer.floatChannelData?[1] {
                leftChannelData = Array(UnsafeBufferPointer(start: left, count: Int(frameCount)))
                rightChannelData = Array(UnsafeBufferPointer(start: right, count: Int(frameCount)))
            } else if channelCount == 1, let left = buffer.floatChannelData?[0] {
                leftChannelData = Array(UnsafeBufferPointer(start: left, count: Int(frameCount)))
                rightChannelData = leftChannelData
            } else {
                leftChannelData = []
                rightChannelData = []
            }
            // 降采样以适合显示
            let downsampleFactor = max(1, leftChannelData.count / 1000)
            var leftDown: [Float] = []
            var rightDown: [Float] = []
            for i in stride(from: 0, to: leftChannelData.count, by: downsampleFactor) {
                leftDown.append(leftChannelData[i])
                rightDown.append(rightChannelData[i])
            }
            DispatchQueue.main.async {
                self.waveformView?.updateWaveform(left: leftDown, right: rightDown)
            }
        } catch {
            print("Failed to extract waveform data: \(error)")
        }
    }
    
    private func updateSpectrum(_ fftData: [Float]) {
        // 可选：实时频谱显示
    }
    
    private func startPlaybackPositionUpdate() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self, self.isPlaying else {
                timer.invalidate()
                return
            }
            let currentTime = self.player.currentTime
            let duration = self.player.duration
            let progress = duration > 0 ? currentTime / duration : 0.0
            DispatchQueue.main.async {
                self.waveformView?.updatePlaybackPosition(Float(progress))
            }
        }
    }
}

// MARK: - 波形显示视图
class WaveformView: NSView {
    var backgroundColor: NSColor = NSColor.black { didSet { needsDisplay = true } }
    var leftWaveformColor: NSColor = NSColor.green { didSet { needsDisplay = true } }
    var rightWaveformColor: NSColor = NSColor.cyan { didSet { needsDisplay = true } }
    var cursorColor: NSColor = NSColor.red { didSet { needsDisplay = true } }
    var zoomFactor: CGFloat = 1.0 { didSet { needsDisplay = true } }
    private var leftChannelData: [Float] = []
    private var rightChannelData: [Float] = []
    private var playbackPosition: Float = 0.0
    
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
    func updateWaveform(left: [Float], right: [Float]) {
        leftChannelData = left
        rightChannelData = right
        needsDisplay = true
    }
    func updatePlaybackPosition(_ position: Float) {
        playbackPosition = position
        needsDisplay = true
    }
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.setFillColor(backgroundColor.cgColor)
        context.fill(bounds)
        drawWaveform(context: context)
        drawPlaybackCursor(context: context)
    }
    private func drawWaveform(context: CGContext) {
        guard !leftChannelData.isEmpty else { return }
        
        let width = bounds.width
        let height = bounds.height
        let halfHeight = height / 2
        
        // 绘制分隔线
        context.setStrokeColor(NSColor.gray.cgColor)
        context.setLineWidth(1.0)
        context.beginPath()
        context.move(to: CGPoint(x: 0, y: halfHeight))
        context.addLine(to: CGPoint(x: width, y: halfHeight))
        context.strokePath()
        
        // 绘制标签
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10),
            .foregroundColor: NSColor.white
        ]
        
        // 左声道标签
        let leftLabel = "左声道 (L)"
        let leftLabelSize = leftLabel.size(withAttributes: labelAttributes)
        leftLabel.draw(at: CGPoint(x: 5, y: halfHeight - leftLabelSize.height - 5), withAttributes: labelAttributes)
        
        // 右声道标签
        let rightLabel = "右声道 (R)"
        let rightLabelSize = rightLabel.size(withAttributes: labelAttributes)
        rightLabel.draw(at: CGPoint(x: 5, y: height - rightLabelSize.height - 5), withAttributes: labelAttributes)
        
        // 左声道（上半部分）
        context.setStrokeColor(leftWaveformColor.cgColor)
        context.setLineWidth(1.0)
        context.beginPath()
        
        let leftStep = (width * zoomFactor) / CGFloat(leftChannelData.count)
        let leftCenterY = halfHeight / 2  // 上半部分的中心
        
        for (index, sample) in leftChannelData.enumerated() {
            let x = CGFloat(index) * leftStep - (width * (zoomFactor - 1) / 2)
            let amplitude = CGFloat(sample) * (halfHeight / 2) * 0.8
            let y = leftCenterY + amplitude
            
            if index == 0 {
                context.move(to: CGPoint(x: x, y: y))
            } else {
                context.addLine(to: CGPoint(x: x, y: y))
            }
        }
        context.strokePath()
        
        // 右声道（下半部分）
        context.setStrokeColor(rightWaveformColor.cgColor)
        context.setLineWidth(1.0)
        context.beginPath()
        
        let rightStep = (width * zoomFactor) / CGFloat(rightChannelData.count)
        let rightCenterY = halfHeight + (halfHeight / 2)  // 下半部分的中心
        
        for (index, sample) in rightChannelData.enumerated() {
            let x = CGFloat(index) * rightStep - (width * (zoomFactor - 1) / 2)
            let amplitude = CGFloat(sample) * (halfHeight / 2) * 0.8
            let y = rightCenterY + amplitude
            
            if index == 0 {
                context.move(to: CGPoint(x: x, y: y))
            } else {
                context.addLine(to: CGPoint(x: x, y: y))
            }
        }
        context.strokePath()
    }
    private func drawPlaybackCursor(context: CGContext) {
        let width = bounds.width
        let height = bounds.height
        let x = CGFloat(playbackPosition) * width
        context.setStrokeColor(cursorColor.cgColor)
        context.setLineWidth(2.0)
        context.beginPath()
        context.move(to: CGPoint(x: x, y: 0))
        context.addLine(to: CGPoint(x: x, y: height))
        context.strokePath()
    }
}

// MARK: - 音频播放器控制面板
class AudioPlayerWithWaveformControlPanel: NSView {
    private var audioPlayer: AudioPlayerWithWaveformExample!
    private var waveformView: WaveformView!
    private let playButton = NSButton()
    private let pauseButton = NSButton()
    private let stopButton = NSButton()
    private let openButton = NSButton()
    private let timeLabel = NSTextField()
    private let zoomSlider = NSSlider()
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupAudioPlayer()
        setupUI()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupAudioPlayer()
        setupUI()
    }
    private func setupAudioPlayer() {
        audioPlayer = AudioPlayerWithWaveformExample()
        audioPlayer.start()
        waveformView = audioPlayer.waveformView
    }
    private func setupUI() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        waveformView.frame = NSRect(x: 20, y: 140, width: 400, height: 200)
        addSubview(waveformView)
        setupButtons()
        setupTimeLabel()
        setupZoomSlider()
        setupLayout()
    }
    private func setupButtons() {
        openButton.title = "打开音频文件"
        openButton.bezelStyle = .rounded
        openButton.target = self
        openButton.action = #selector(openAudioFile)
        addSubview(openButton)
        playButton.title = "播放"
        playButton.bezelStyle = .rounded
        playButton.target = self
        playButton.action = #selector(playAudio)
        addSubview(playButton)
        pauseButton.title = "暂停"
        pauseButton.bezelStyle = .rounded
        pauseButton.target = self
        pauseButton.action = #selector(pauseAudio)
        addSubview(pauseButton)
        stopButton.title = "停止"
        stopButton.bezelStyle = .rounded
        stopButton.target = self
        stopButton.action = #selector(stopAudio)
        addSubview(stopButton)
    }
    private func setupTimeLabel() {
        timeLabel.stringValue = "时间: 00:00 / 00:00"
        timeLabel.isEditable = false
        timeLabel.isBordered = false
        timeLabel.backgroundColor = NSColor.clear
        timeLabel.font = NSFont.systemFont(ofSize: 12)
        addSubview(timeLabel)
    }
    private func setupZoomSlider() {
        zoomSlider.minValue = 1.0
        zoomSlider.maxValue = 10.0
        zoomSlider.doubleValue = 1.0
        zoomSlider.target = self
        zoomSlider.action = #selector(zoomSliderChanged)
        addSubview(zoomSlider)
    }
    private func setupLayout() {
        let buttonWidth: CGFloat = 80
        let buttonHeight: CGFloat = 30
        let spacing: CGFloat = 10
        let startX: CGFloat = 20
        let startY: CGFloat = 90
        openButton.frame = NSRect(x: startX, y: startY, width: buttonWidth, height: buttonHeight)
        playButton.frame = NSRect(x: startX + buttonWidth + spacing, y: startY, width: buttonWidth, height: buttonHeight)
        pauseButton.frame = NSRect(x: startX + (buttonWidth + spacing) * 2, y: startY, width: buttonWidth, height: buttonHeight)
        stopButton.frame = NSRect(x: startX + (buttonWidth + spacing) * 3, y: startY, width: buttonWidth, height: buttonHeight)
        timeLabel.frame = NSRect(x: startX, y: startY - 30, width: 200, height: 20)
        zoomSlider.frame = NSRect(x: startX, y: startY - 60, width: 300, height: 20)
    }
    @objc private func openAudioFile() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.audio, .mp3, .wav, .aiff]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.begin { [weak self] result in
            if result == .OK, let url = openPanel.url {
                self?.audioPlayer.loadAndPlay(url: url)
            }
        }
    }
    @objc private func playAudio() {
        audioPlayer.resume()
    }
    @objc private func pauseAudio() {
        audioPlayer.pause()
    }
    @objc private func stopAudio() {
        audioPlayer.stopPlayback()
    }
    @objc private func zoomSliderChanged() {
        waveformView.zoomFactor = CGFloat(zoomSlider.doubleValue)
    }
    deinit {
        audioPlayer.stop()
    }
} 
