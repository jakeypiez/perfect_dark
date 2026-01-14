import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var settings: GameSettings
    @State private var isLaunching = false
    @State private var launchError: String?
    @State private var showingLaunchError = false
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HeaderView()
            
            Divider()
            
            // Main Content
            HStack(spacing: 0) {
                // Sidebar
                SidebarView(selectedTab: $selectedTab)
                    .frame(width: 200)
                
                Divider()
                
                // Content Area
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        switch selectedTab {
                        case 0:
                            RomSelectionView()
                        case 1:
                            VideoSettingsView()
                        case 2:
                            GameSettingsView()
                        case 3:
                            AudioSettingsView()
                        case 4:
                            PlayerSettingsView()
                        case 5:
                            AdvancedSettingsView()
                        default:
                            RomSelectionView()
                        }
                    }
                    .padding(24)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            Divider()
            
            // Footer with Launch Button
            FooterView(isLaunching: $isLaunching, launchError: $launchError, showingLaunchError: $showingLaunchError)
        }
        .frame(width: 800, height: 600)
        .background(Color(NSColor.windowBackgroundColor))
        .alert("Launch Error", isPresented: $showingLaunchError) {
            Button("OK") { }
        } message: {
            Text(launchError ?? "Unknown error occurred")
        }
    }
}

struct HeaderView: View {
    var body: some View {
        HStack {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 32))
                .foregroundColor(.accentColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Perfect Dark")
                    .font(.system(size: 24, weight: .bold))
                Text("PC Port Launcher")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("Rare 2000 / Port by fgsfds")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct SidebarView: View {
    @Binding var selectedTab: Int
    
    let menuItems = [
        ("folder.badge.plus", "ROM File"),
        ("display", "Video"),
        ("gearshape", "Game"),
        ("speaker.wave.2", "Audio"),
        ("person", "Player"),
        ("wrench.and.screwdriver", "Advanced")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(0..<menuItems.count, id: \.self) { index in
                SidebarButton(
                    icon: menuItems[index].0,
                    title: menuItems[index].1,
                    isSelected: selectedTab == index
                ) {
                    selectedTab = index
                }
            }
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct SidebarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .frame(width: 24)
                Text(title)
                    .font(.system(size: 14))
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            .foregroundColor(isSelected ? .accentColor : .primary)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct FooterView: View {
    @EnvironmentObject var settings: GameSettings
    @Binding var isLaunching: Bool
    @Binding var launchError: String?
    @Binding var showingLaunchError: Bool
    
    var body: some View {
        HStack {
            // ROM Status
            HStack(spacing: 8) {
                Circle()
                    .fill(settings.isReadyToLaunch ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                
                if settings.isReadyToLaunch {
                    Text("ROM: \(settings.romFileName)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else {
                    Text("No ROM file selected")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Launch Button
            Button(action: launchGame) {
                HStack(spacing: 8) {
                    if isLaunching {
                        ProgressView()
                            .scaleEffect(0.7)
                            .progressViewStyle(.circular)
                    } else {
                        Image(systemName: "play.fill")
                    }
                    Text(isLaunching ? "Launching..." : "Launch Game")
                        .fontWeight(.semibold)
                }
                .frame(width: 140)
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!settings.isReadyToLaunch || isLaunching)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    func launchGame() {
        isLaunching = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let result = GameLauncher.shared.launchGame(settings: settings)
            
            DispatchQueue.main.async {
                isLaunching = false
                if case .failure(let error) = result {
                    launchError = error.localizedDescription
                    showingLaunchError = true
                }
            }
        }
    }
}

struct RomSelectionView: View {
    @EnvironmentObject var settings: GameSettings
    @State private var isDragging = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "ROM File", subtitle: "Select your Perfect Dark ROM file")
            
            // Drop Zone
            VStack(spacing: 16) {
                if settings.romPath.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 48))
                            .foregroundColor(isDragging ? .accentColor : .secondary)
                        
                        Text("Drag & Drop ROM File Here")
                            .font(.headline)
                            .foregroundColor(isDragging ? .accentColor : .primary)
                        
                        Text("or click to browse")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Supported format: .z64")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.green)
                        
                        Text(settings.romFileName)
                            .font(.headline)
                            .lineLimit(1)
                        
                        Text(settings.romPath)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                        
                        Button("Change ROM") {
                            browseForRom()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isDragging ? Color.accentColor : Color.gray.opacity(0.3),
                        style: StrokeStyle(lineWidth: 2, dash: settings.romPath.isEmpty ? [8] : [])
                    )
            )
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isDragging ? Color.accentColor.opacity(0.1) : Color.clear)
            )
            .onDrop(of: [.fileURL], isTargeted: $isDragging) { providers in
                handleDrop(providers: providers)
            }
            .onTapGesture {
                if settings.romPath.isEmpty {
                    browseForRom()
                }
            }
            
            // ROM Region Selection
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("ROM Region")
                            .font(.headline)
                        
                        Spacer()
                        
                        Picker("", selection: $settings.romRegion) {
                            ForEach(GameSettings.RomRegion.allCases) { region in
                                Text(region.displayName).tag(region)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 200)
                    }
                    
                    Text("Select the region that matches your ROM file. Using the wrong region will cause the game to fail to start.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(8)
            }
            
            // ROM Requirements
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    Label("ROM Requirements", systemImage: "info.circle")
                        .font(.headline)
                    
                    Text("• ROM must be in .z64 format (big-endian)")
                    Text("• Supported versions: NTSC v1.1, PAL, or JPN")
                    Text("• ROM size should be exactly 32 MB")
                    Text("• Do not use compressed archives (.zip, .rar, .7z)")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(8)
            }
        }
    }
    
    func browseForRom() {
        let panel = NSOpenPanel()
        panel.title = "Select Perfect Dark ROM"
        panel.allowedContentTypes = [UTType(filenameExtension: "z64") ?? .data, UTType(filenameExtension: "n64") ?? .data]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        
        if panel.runModal() == .OK, let url = panel.url {
            settings.romPath = url.path
            settings.detectRomRegion()
        }
    }
    
    func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, error in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else {
                return
            }
            
            let ext = url.pathExtension.lowercased()
            if ext == "z64" || ext == "n64" {
                DispatchQueue.main.async {
                    settings.romPath = url.path
                    settings.detectRomRegion()
                }
            }
        }
        return true
    }
}

struct VideoSettingsView: View {
    @EnvironmentObject var settings: GameSettings
    
    // MacBook-optimized resolutions (16:10 aspect ratio common on MacBooks)
    let commonResolutions = [
        // 16:10 MacBook Native/Scaled Resolutions
        (1280, 800, "1280×800 (16:10 MacBook)"),
        (1440, 900, "1440×900 (16:10 MacBook Air)"),
        (1680, 1050, "1680×1050 (16:10 Scaled)"),
        (1920, 1200, "1920×1200 (16:10 WUXGA)"),
        (2560, 1600, "2560×1600 (16:10 MacBook Pro)"),
        // 16:9 Resolutions (External Displays)
        (1280, 720, "1280×720 (16:9 HD)"),
        (1920, 1080, "1920×1080 (16:9 Full HD)"),
        (2560, 1440, "2560×1440 (16:9 QHD)"),
        // Retina / HiDPI
        (2880, 1800, "2880×1800 (Retina 15\")"),
        (3024, 1890, "3024×1890 (MacBook Pro 14\")"),
        (3456, 2160, "3456×2160 (MacBook Pro 16\")"),
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Video Settings", subtitle: "Configure display and graphics options")
            
            // Resolution
            GroupBox {
                VStack(alignment: .leading, spacing: 16) {
                    Label("Resolution", systemImage: "rectangle.dashed")
                        .font(.headline)
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Width")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("Width", value: $settings.windowWidth, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                        }
                        
                        Text("×")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Height")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("Height", value: $settings.windowHeight, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                        }
                        
                        Spacer()
                        
                        Menu("Presets") {
                            ForEach(commonResolutions, id: \.2) { res in
                                Button(res.2) {
                                    settings.windowWidth = res.0
                                    settings.windowHeight = res.1
                                }
                            }
                        }
                        .menuStyle(.borderlessButton)
                    }
                }
                .padding(8)
            }
            
            // Display Mode
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Display Mode", systemImage: "display")
                        .font(.headline)
                    
                    Toggle("Fullscreen", isOn: $settings.fullscreen)
                    
                    if settings.fullscreen {
                        Toggle("Exclusive Fullscreen", isOn: $settings.fullscreenExclusive)
                            .padding(.leading, 20)
                        
                        Text("Exclusive fullscreen may provide better performance but prevents easy Alt-Tab switching")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 20)
                    }
                }
                .padding(8)
            }
            
            // Graphics Quality
            GroupBox {
                VStack(alignment: .leading, spacing: 16) {
                    Label("Graphics Quality", systemImage: "paintbrush")
                        .font(.headline)
                    
                    HStack {
                        Text("VSync")
                        Spacer()
                        Picker("", selection: $settings.vsync) {
                            Text("Off").tag(0)
                            Text("On").tag(1)
                            Text("Adaptive").tag(-1)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 200)
                    }
                    
                    HStack {
                        Text("Anti-Aliasing (MSAA)")
                        Spacer()
                        Picker("", selection: $settings.msaa) {
                            Text("Off").tag(0)
                            Text("2×").tag(2)
                            Text("4×").tag(4)
                            Text("8×").tag(8)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 200)
                    }
                    
                    HStack {
                        Text("Texture Filter")
                        Spacer()
                        Picker("", selection: $settings.textureFilter) {
                            ForEach(GameSettings.TextureFilter.allCases) { filter in
                                Text(filter.displayName).tag(filter)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 200)
                    }
                    
                    Toggle("Detail Textures", isOn: $settings.detailTextures)
                    Toggle("Use Framebuffers", isOn: $settings.useFramebuffers)
                    
                    HStack {
                        Text("Framerate Limit")
                        Spacer()
                        Picker("", selection: $settings.framerateLimit) {
                            Text("Unlimited").tag(0)
                            Text("30 FPS").tag(30)
                            Text("60 FPS").tag(60)
                            Text("120 FPS (ProMotion)").tag(120)
                            Text("144 FPS").tag(144)
                            Text("240 FPS").tag(240)
                        }
                        .pickerStyle(.menu)
                        .frame(width: 200)
                    }
                }
                .padding(8)
            }
            
            // MacBook-Specific Settings
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Label("MacBook Optimization", systemImage: "laptopcomputer")
                        .font(.headline)
                    
                    Toggle("Retina / HiDPI Resolution", isOn: $settings.allowRetinaResolution)
                    Text("Enable native resolution rendering on Retina displays. May impact performance on older Macs.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 20)
                    
                    Toggle("Trackpad Mode", isOn: $settings.trackpadMode)
                    Text("Optimizes mouse sensitivity and acceleration for MacBook trackpads. Disable if using an external mouse.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 20)
                }
                .padding(8)
            }
        }
    }
}

struct GameSettingsView: View {
    @EnvironmentObject var settings: GameSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Game Settings", subtitle: "Configure gameplay options")
            
            // General
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Label("General", systemImage: "gearshape")
                        .font(.headline)
                    
                    Toggle("Skip Intro Videos", isOn: $settings.skipIntro)
                    
                    Toggle("Menu Mouse Control", isOn: $settings.menuMouseControl)
                    
                    HStack {
                        Text("HUD Position")
                        Spacer()
                        Picker("", selection: $settings.hudCenter) {
                            ForEach(GameSettings.HudCenterMode.allCases) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 200)
                    }
                }
                .padding(8)
            }
            
            // Visual Effects
            GroupBox {
                VStack(alignment: .leading, spacing: 16) {
                    Label("Visual Effects", systemImage: "sparkles")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Screen Shake Intensity")
                            Spacer()
                            Text(String(format: "%.1f×", settings.screenShakeIntensity))
                                .foregroundColor(.secondary)
                                .frame(width: 50)
                        }
                        Slider(value: $settings.screenShakeIntensity, in: 0...3, step: 0.1)
                    }
                    
                    HStack {
                        Text("Max Explosions")
                        Spacer()
                        Stepper(value: $settings.maxExplosions, in: 6...96, step: 6) {
                            Text("\(settings.maxExplosions)")
                                .frame(width: 40, alignment: .trailing)
                        }
                    }
                    
                    Toggle("GoldenEye-Style Muzzle Flashes", isOn: $settings.geMuzzleFlashes)
                }
                .padding(8)
            }
            
            // Multiplayer
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Multiplayer", systemImage: "person.2")
                        .font(.headline)
                    
                    Toggle("Disable Death Music", isOn: $settings.disableMpDeathMusic)
                    
                    Text("Disables the music that plays when you die in multiplayer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(8)
            }
            
            // Memory
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Memory", systemImage: "memorychip")
                        .font(.headline)
                    
                    HStack {
                        Text("Memory Size")
                        Spacer()
                        Picker("", selection: $settings.memorySize) {
                            Text("4 MB (N64)").tag(4)
                            Text("8 MB (Expansion Pak)").tag(8)
                            Text("16 MB (Default)").tag(16)
                            Text("32 MB").tag(32)
                            Text("64 MB").tag(64)
                            Text("128 MB").tag(128)
                        }
                        .pickerStyle(.menu)
                        .frame(width: 200)
                    }
                    
                    Text("Higher memory allows for better textures and more complex scenes. Default is 16 MB.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(8)
            }
        }
    }
}

struct AudioSettingsView: View {
    @EnvironmentObject var settings: GameSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Audio Settings", subtitle: "Configure sound options")
            
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Sound", systemImage: "speaker.wave.2")
                        .font(.headline)
                    
                    Toggle("Disable All Sound", isOn: $settings.disableSound)
                    
                    Text("Completely disables audio playback. Useful for troubleshooting.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(8)
            }
            
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Note", systemImage: "info.circle")
                        .font(.headline)
                    
                    Text("Additional audio settings like volume levels are configured in-game through the Options menu.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(8)
            }
        }
    }
}

struct PlayerSettingsView: View {
    @EnvironmentObject var settings: GameSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Player Settings", subtitle: "Configure player-specific options")
            
            // Field of View
            GroupBox {
                VStack(alignment: .leading, spacing: 16) {
                    Label("Field of View", systemImage: "eye")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Vertical FOV")
                            Spacer()
                            Text(String(format: "%.0f°", settings.player1FovY))
                                .foregroundColor(.secondary)
                                .frame(width: 50)
                        }
                        Slider(value: $settings.player1FovY, in: 40...120, step: 1)
                    }
                    
                    Toggle("FOV Affects Zoom Weapons", isOn: $settings.player1FovAffectsZoom)
                    
                    Text("When enabled, scoped weapons will also use your custom FOV setting")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(8)
            }
            
            // Mouse Controls
            GroupBox {
                VStack(alignment: .leading, spacing: 16) {
                    Label("Mouse Controls", systemImage: "computermouse")
                        .font(.headline)
                    
                    Toggle("Mouse Aim Mode", isOn: $settings.player1MouseAimMode)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Horizontal Sensitivity")
                            Spacer()
                            Text(String(format: "%.2f", settings.player1MouseAimSpeedX))
                                .foregroundColor(.secondary)
                                .frame(width: 50)
                        }
                        Slider(value: $settings.player1MouseAimSpeedX, in: 0.1...5, step: 0.05)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Vertical Sensitivity")
                            Spacer()
                            Text(String(format: "%.2f", settings.player1MouseAimSpeedY))
                                .foregroundColor(.secondary)
                                .frame(width: 50)
                        }
                        Slider(value: $settings.player1MouseAimSpeedY, in: 0.1...5, step: 0.05)
                    }
                }
                .padding(8)
            }
            
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Note", systemImage: "info.circle")
                        .font(.headline)
                    
                    Text("Additional player settings and key bindings can be configured in-game or by editing the pd.ini configuration file.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(8)
            }
        }
    }
}

struct AdvancedSettingsView: View {
    @EnvironmentObject var settings: GameSettings
    @State private var showingResetConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Advanced Settings", subtitle: "Configure paths and advanced options")
            
            // Paths
            GroupBox {
                VStack(alignment: .leading, spacing: 16) {
                    Label("Paths", systemImage: "folder")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Game Executable")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack {
                            TextField("Path to game executable", text: $settings.gameExecutablePath)
                                .textFieldStyle(.roundedBorder)
                            Button("Browse") {
                                browseForExecutable()
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Game Data Directory")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack {
                            TextField("Path to game data", text: $settings.gameDataPath)
                                .textFieldStyle(.roundedBorder)
                            Button("Browse") {
                                browseForDataDirectory()
                            }
                        }
                    }
                    
                    Text("Leave empty to use automatic detection. The launcher will look for the executable in the same directory as the ROM.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(8)
            }
            
            // Config File
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Configuration File", systemImage: "doc.text")
                        .font(.headline)
                    
                    HStack {
                        Button("Open pd.ini in Editor") {
                            openConfigFile()
                        }
                        
                        Button("Reveal in Finder") {
                            revealConfigFile()
                        }
                    }
                    
                    Text("Advanced settings can be manually edited in the pd.ini configuration file.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(8)
            }
            
            // Reset
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .font(.headline)
                    
                    Button("Reset All Settings to Defaults") {
                        showingResetConfirmation = true
                    }
                    .foregroundColor(.red)
                    
                    Text("This will reset all launcher settings to their default values. Your ROM file path will be preserved.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(8)
            }
            .alert("Reset Settings", isPresented: $showingResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    settings.resetToDefaults()
                }
            } message: {
                Text("Are you sure you want to reset all settings to their default values?")
            }
        }
    }
    
    func browseForExecutable() {
        let panel = NSOpenPanel()
        panel.title = "Select Perfect Dark Executable"
        panel.allowedContentTypes = [.unixExecutable, .executable]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        
        if panel.runModal() == .OK, let url = panel.url {
            settings.gameExecutablePath = url.path
        }
    }
    
    func browseForDataDirectory() {
        let panel = NSOpenPanel()
        panel.title = "Select Game Data Directory"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        
        if panel.runModal() == .OK, let url = panel.url {
            settings.gameDataPath = url.path
        }
    }
    
    func openConfigFile() {
        let configPath = getConfigFilePath()
        if FileManager.default.fileExists(atPath: configPath) {
            NSWorkspace.shared.open(URL(fileURLWithPath: configPath))
        }
    }
    
    func revealConfigFile() {
        let configPath = getConfigFilePath()
        if FileManager.default.fileExists(atPath: configPath) {
            NSWorkspace.shared.selectFile(configPath, inFileViewerRootedAtPath: "")
        } else {
            // Reveal the directory where it would be
            let dir = (configPath as NSString).deletingLastPathComponent
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: dir)
        }
    }
    
    func getConfigFilePath() -> String {
        if !settings.gameDataPath.isEmpty {
            return (settings.gameDataPath as NSString).appendingPathComponent("pd.ini")
        }
        
        let romDir = (settings.romPath as NSString).deletingLastPathComponent
        return (romDir as NSString).appendingPathComponent("pd.ini")
    }
}

struct SectionHeader: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var settings: GameSettings
    
    var body: some View {
        TabView {
            VideoSettingsView()
                .tabItem {
                    Label("Video", systemImage: "display")
                }
            
            GameSettingsView()
                .tabItem {
                    Label("Game", systemImage: "gearshape")
                }
        }
        .padding()
        .frame(width: 600, height: 500)
    }
}

#Preview {
    ContentView()
        .environmentObject(GameSettings())
}
