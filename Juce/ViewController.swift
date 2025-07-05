//
//  ViewController.swift
//  Juce
//
//  Created by Jason on 2025/7/4.
//

import Cocoa
import AudioKit

class ViewController: NSViewController, NSTabViewDelegate {

    private var audioKitControlPanel: AudioKitControlPanel!
    private var audioPlayerWithWaveformPanel: AudioPlayerWithWaveformControlPanel!
    private var equalizerPanel: EqualizerControlPanel!
    private var fftSpectrumPanel: FFTSpectrumControlPanel!
    private var spatialAudioPanel: SpatialAudioControlPanel!

    override func viewDidLoad() {
        super.viewDidLoad()

        // 设置窗口大小为 1200x900 - 更高以适应空间音频界面
        if let window = view.window {
            window.setFrame(NSRect(x: window.frame.origin.x, y: window.frame.origin.y, width: 1200, height: 900), display: true)
        }

        // 创建标签视图
        let tabView = NSTabView(frame: view.bounds)
        tabView.autoresizingMask = [.width, .height]
        view.addSubview(tabView)
        
        // 创建基础 AudioKit 控制面板标签页
        let basicTab = NSTabViewItem()
        basicTab.label = "基础示例"
        basicTab.view = NSView(frame: NSRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height))
        tabView.addTabViewItem(basicTab)
        
        // 创建音频播放器与波形显示标签页
        let waveformTab = NSTabViewItem()
        waveformTab.label = "音频播放器与波形"
        waveformTab.view = NSView(frame: NSRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height))
        tabView.addTabViewItem(waveformTab)
        
        // 创建均衡器标签页
        let equalizerTab = NSTabViewItem()
        equalizerTab.label = "均衡器"
        equalizerTab.view = NSView(frame: NSRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height))
        tabView.addTabViewItem(equalizerTab)
        
        // 创建FFT频谱分析标签页
        let fftTab = NSTabViewItem()
        fftTab.label = "FFT频谱分析"
        fftTab.view = NSView(frame: NSRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height))
        tabView.addTabViewItem(fftTab)
        
        // 创建空间音频标签页
        let spatialTab = NSTabViewItem()
        spatialTab.label = "空间音频"
        spatialTab.view = NSView(frame: NSRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height))
        tabView.addTabViewItem(spatialTab)
        
        // 设置窗口标题
        view.window?.title = "AudioKit Examples - AppKit Version"
        
        // 初始化控制面板（现在使用懒加载，不会同时创建多个音频引擎）
        initializeControlPanels(tabView: tabView)
        
        print("AudioKit examples loaded successfully")
    }
    
    private func initializeControlPanels(tabView: NSTabView) {
        // 只创建基础 AudioKit 控制面板，其他面板使用懒加载
        audioKitControlPanel = AudioKitControlPanel(frame: NSRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height))
        tabView.tabViewItem(at: 0).view = audioKitControlPanel
        
        // 为其他标签页创建占位视图，使用懒加载
        for i in 1...4 {
            let placeholderView = NSView(frame: NSRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height))
            placeholderView.wantsLayer = true
            placeholderView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
            
            let label = NSTextField(labelWithString: "点击标签页加载示例...")
            label.font = NSFont.systemFont(ofSize: 16)
            label.textColor = NSColor.secondaryLabelColor
            label.alignment = .center
            label.frame = NSRect(x: 0, y: 0, width: 300, height: 30)
            label.center(in: placeholderView)
            placeholderView.addSubview(label)
            
            tabView.tabViewItem(at: i).view = placeholderView
        }
        
        // 设置标签页切换监听
        tabView.delegate = self
        
        print("Control panels initialized with lazy loading")
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    // MARK: - NSTabViewDelegate
    
    func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        guard let selectedItem = tabViewItem,
              let selectedIndex = tabView.tabViewItems.firstIndex(of: selectedItem) else { return }
        
        // 根据选中的标签页懒加载对应的控制面板
        switch selectedIndex {
        case 1: // 音频播放器与波形
            if audioPlayerWithWaveformPanel == nil {
                audioPlayerWithWaveformPanel = AudioPlayerWithWaveformControlPanel(frame: NSRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height))
                selectedItem.view = audioPlayerWithWaveformPanel
                print("Audio player with waveform panel loaded")
            }
        case 2: // 均衡器
            if equalizerPanel == nil {
                equalizerPanel = EqualizerControlPanel(frame: NSRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height))
                selectedItem.view = equalizerPanel
                print("Equalizer panel loaded")
            }
        case 3: // FFT频谱分析
            if fftSpectrumPanel == nil {
                fftSpectrumPanel = FFTSpectrumControlPanel(frame: NSRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height))
                selectedItem.view = fftSpectrumPanel
                print("FFT spectrum panel loaded")
            }
        case 4: // 空间音频
            if spatialAudioPanel == nil {
                spatialAudioPanel = SpatialAudioControlPanel(frame: NSRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height))
                selectedItem.view = spatialAudioPanel
                print("Spatial audio panel loaded")
            }
        default:
            break
        }
    }
    
    deinit {
        // 确保音频引擎在视图控制器销毁时停止
        AudioKitManager.shared.stop()
    }
}

// MARK: - NSView Extension for centering
extension NSView {
    func center(in parentView: NSView) {
        let parentFrame = parentView.bounds
        let selfFrame = self.frame
        let x = (parentFrame.width - selfFrame.width) / 2
        let y = (parentFrame.height - selfFrame.height) / 2
        self.frame = NSRect(x: x, y: y, width: selfFrame.width, height: selfFrame.height)
    }
}

