import SwiftUI
import Combine

class GameSettings: ObservableObject {
    // ROM Settings
    @Published var romPath: String {
        didSet { saveSettings() }
    }
    @Published var romRegion: RomRegion {
        didSet { saveSettings() }
    }
    
    // Video Settings
    @Published var windowWidth: Int {
        didSet { saveSettings() }
    }
    @Published var windowHeight: Int {
        didSet { saveSettings() }
    }
    @Published var fullscreen: Bool {
        didSet { saveSettings() }
    }
    @Published var fullscreenExclusive: Bool {
        didSet { saveSettings() }
    }
    @Published var vsync: Int {
        didSet { saveSettings() }
    }
    @Published var msaa: Int {
        didSet { saveSettings() }
    }
    @Published var framerateLimit: Int {
        didSet { saveSettings() }
    }
    @Published var textureFilter: TextureFilter {
        didSet { saveSettings() }
    }
    @Published var detailTextures: Bool {
        didSet { saveSettings() }
    }
    @Published var useFramebuffers: Bool {
        didSet { saveSettings() }
    }
    @Published var allowRetinaResolution: Bool {
        didSet { saveSettings() }
    }
    @Published var trackpadMode: Bool {
        didSet { saveSettings() }
    }
    @Published var maximize: Bool {
        didSet { saveSettings() }
    }
    @Published var textureFilter2D: Bool {
        didSet { saveSettings() }
    }
    @Published var displayFPS: Bool {
        didSet { saveSettings() }
    }
    @Published var displayFPSInterval: Double {
        didSet { saveSettings() }
    }
    @Published var centerWindow: Bool {
        didSet { saveSettings() }
    }
    
    // Debug/Developer Settings
    @Published var tickRateDivisor: Int {
        didSet { saveSettings() }
    }
    @Published var extraSleep: Bool {
        didSet { saveSettings() }
    }
    
    // Game Settings
    @Published var memorySize: Int {
        didSet { saveSettings() }
    }
    @Published var skipIntro: Bool {
        didSet { saveSettings() }
    }
    @Published var hudCenter: HudCenterMode {
        didSet { saveSettings() }
    }
    @Published var menuMouseControl: Bool {
        didSet { saveSettings() }
    }
    @Published var screenShakeIntensity: Double {
        didSet { saveSettings() }
    }
    @Published var disableMpDeathMusic: Bool {
        didSet { saveSettings() }
    }
    @Published var geMuzzleFlashes: Bool {
        didSet { saveSettings() }
    }
    @Published var maxExplosions: Int {
        didSet { saveSettings() }
    }
    
    // Audio Settings
    @Published var disableSound: Bool {
        didSet { saveSettings() }
    }
    
    // Player 1 Settings
    @Published var player1FovY: Double {
        didSet { saveSettings() }
    }
    @Published var player1FovAffectsZoom: Bool {
        didSet { saveSettings() }
    }
    @Published var player1MouseAimMode: Bool {
        didSet { saveSettings() }
    }
    @Published var player1MouseAimSpeedX: Double {
        didSet { saveSettings() }
    }
    @Published var player1MouseAimSpeedY: Double {
        didSet { saveSettings() }
    }
    @Published var crosshairSway: Double {
        didSet { saveSettings() }
    }
    @Published var crosshairSize: Int {
        didSet { saveSettings() }
    }
    @Published var crosshairHealth: Int {
        didSet { saveSettings() }
    }
    @Published var extendedControls: Bool {
        didSet { saveSettings() }
    }
    @Published var radialMenuSpeed: Double {
        didSet { saveSettings() }
    }
    @Published var crouchMode: CrouchMode {
        didSet { saveSettings() }
    }
    @Published var useKeyReloads: Bool {
        didSet { saveSettings() }
    }
    
    // Input Settings
    @Published var mouseEnabled: Bool {
        didSet { saveSettings() }
    }
    @Published var mouseSpeedX: Double {
        didSet { saveSettings() }
    }
    @Published var mouseSpeedY: Double {
        didSet { saveSettings() }
    }
    @Published var fakeGamepads: Int {
        didSet { saveSettings() }
    }
    
    // Paths
    @Published var gameExecutablePath: String {
        didSet { saveSettings() }
    }
    @Published var gameDataPath: String {
        didSet { saveSettings() }
    }
    
    private let defaults = UserDefaults.standard
    private var isLoading = false
    
    enum RomRegion: String, CaseIterable, Identifiable {
        case ntscFinal = "ntsc-final"
        case palFinal = "pal-final"
        case jpnFinal = "jpn-final"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .ntscFinal: return "NTSC v1.1 (USA)"
            case .palFinal: return "PAL (Europe)"
            case .jpnFinal: return "JPN (Japan)"
            }
        }
        
        var expectedRomName: String {
            return "pd.\(rawValue).z64"
        }
    }
    
    enum TextureFilter: Int, CaseIterable, Identifiable {
        case nearest = 0
        case linear = 1
        case threePoint = 2
        
        var id: Int { rawValue }
        
        var displayName: String {
            switch self {
            case .nearest: return "Nearest (Sharp)"
            case .linear: return "Linear (Smooth)"
            case .threePoint: return "3-Point (N64-like)"
            }
        }
    }
    
    enum HudCenterMode: Int, CaseIterable, Identifiable {
        case normal = 0
        case centered = 1
        case wide = 2
        
        var id: Int { rawValue }
        
        var displayName: String {
            switch self {
            case .normal: return "Normal"
            case .centered: return "Centered"
            case .wide: return "Wide"
            }
        }
    }
    
    enum CrouchMode: Int, CaseIterable, Identifiable {
        case hold = 0
        case toggle = 1
        case toggleAnalog = 2
        
        var id: Int { rawValue }
        
        var displayName: String {
            switch self {
            case .hold: return "Hold"
            case .toggle: return "Toggle"
            case .toggleAnalog: return "Toggle (Analog)"
            }
        }
    }
    
    enum CrosshairHealth: Int, CaseIterable, Identifiable {
        case off = 0
        case onColor = 1
        case onWhite = 2
        
        var id: Int { rawValue }
        
        var displayName: String {
            switch self {
            case .off: return "Off"
            case .onColor: return "On (Color)"
            case .onWhite: return "On (White)"
            }
        }
    }
    
    init() {
        isLoading = true
        
        // Load saved settings or use defaults
        romPath = defaults.string(forKey: "romPath") ?? ""
        romRegion = RomRegion(rawValue: defaults.string(forKey: "romRegion") ?? "ntsc-final") ?? .ntscFinal
        
        // Video defaults - 1440x900 is optimal for most MacBooks
        windowWidth = defaults.object(forKey: "windowWidth") as? Int ?? 1440
        windowHeight = defaults.object(forKey: "windowHeight") as? Int ?? 900
        fullscreen = defaults.bool(forKey: "fullscreen")
        fullscreenExclusive = defaults.bool(forKey: "fullscreenExclusive")
        vsync = defaults.object(forKey: "vsync") as? Int ?? 1
        msaa = defaults.object(forKey: "msaa") as? Int ?? 1
        framerateLimit = defaults.object(forKey: "framerateLimit") as? Int ?? 0
        textureFilter = TextureFilter(rawValue: defaults.object(forKey: "textureFilter") as? Int ?? 1) ?? .linear
        detailTextures = defaults.bool(forKey: "detailTextures")
        useFramebuffers = defaults.object(forKey: "useFramebuffers") as? Bool ?? true
        allowRetinaResolution = defaults.object(forKey: "allowRetinaResolution") as? Bool ?? false
        trackpadMode = defaults.object(forKey: "trackpadMode") as? Bool ?? true
        maximize = defaults.object(forKey: "maximize") as? Bool ?? false
        textureFilter2D = defaults.object(forKey: "textureFilter2D") as? Bool ?? false
        displayFPS = defaults.object(forKey: "displayFPS") as? Bool ?? false
        displayFPSInterval = defaults.object(forKey: "displayFPSInterval") as? Double ?? 1.0
        centerWindow = defaults.object(forKey: "centerWindow") as? Bool ?? true
        
        // Debug/Developer defaults
        tickRateDivisor = defaults.object(forKey: "tickRateDivisor") as? Int ?? 0
        extraSleep = defaults.object(forKey: "extraSleep") as? Bool ?? false
        
        // Game defaults
        memorySize = defaults.object(forKey: "memorySize") as? Int ?? 16
        skipIntro = defaults.object(forKey: "skipIntro") as? Bool ?? false
        hudCenter = HudCenterMode(rawValue: defaults.object(forKey: "hudCenter") as? Int ?? 0) ?? .normal
        menuMouseControl = defaults.object(forKey: "menuMouseControl") as? Bool ?? false
        screenShakeIntensity = defaults.object(forKey: "screenShakeIntensity") as? Double ?? 1.0
        disableMpDeathMusic = defaults.bool(forKey: "disableMpDeathMusic")
        geMuzzleFlashes = defaults.bool(forKey: "geMuzzleFlashes")
        maxExplosions = defaults.object(forKey: "maxExplosions") as? Int ?? 24
        
        // Audio defaults
        disableSound = defaults.bool(forKey: "disableSound")
        
        // Player 1 defaults
        player1FovY = defaults.object(forKey: "player1FovY") as? Double ?? 60.0
        player1FovAffectsZoom = defaults.object(forKey: "player1FovAffectsZoom") as? Bool ?? false
        player1MouseAimMode = defaults.bool(forKey: "player1MouseAimMode")
        player1MouseAimSpeedX = defaults.object(forKey: "player1MouseAimSpeedX") as? Double ?? 1.0
        player1MouseAimSpeedY = defaults.object(forKey: "player1MouseAimSpeedY") as? Double ?? 1.0
        crosshairSway = defaults.object(forKey: "crosshairSway") as? Double ?? 1.0
        crosshairSize = defaults.object(forKey: "crosshairSize") as? Int ?? 0
        crosshairHealth = defaults.object(forKey: "crosshairHealth") as? Int ?? 0
        extendedControls = defaults.object(forKey: "extendedControls") as? Bool ?? false
        radialMenuSpeed = defaults.object(forKey: "radialMenuSpeed") as? Double ?? 1.0
        crouchMode = CrouchMode(rawValue: defaults.object(forKey: "crouchMode") as? Int ?? 0) ?? .hold
        useKeyReloads = defaults.object(forKey: "useKeyReloads") as? Bool ?? false
        
        // Input defaults
        mouseEnabled = defaults.object(forKey: "mouseEnabled") as? Bool ?? true
        mouseSpeedX = defaults.object(forKey: "mouseSpeedX") as? Double ?? 1.0
        mouseSpeedY = defaults.object(forKey: "mouseSpeedY") as? Double ?? 1.0
        fakeGamepads = defaults.object(forKey: "fakeGamepads") as? Int ?? 0
        
        // Paths
        gameExecutablePath = defaults.string(forKey: "gameExecutablePath") ?? ""
        gameDataPath = defaults.string(forKey: "gameDataPath") ?? ""
        
        isLoading = false
    }
    
    func saveSettings() {
        guard !isLoading else { return }
        
        defaults.set(romPath, forKey: "romPath")
        defaults.set(romRegion.rawValue, forKey: "romRegion")
        
        defaults.set(windowWidth, forKey: "windowWidth")
        defaults.set(windowHeight, forKey: "windowHeight")
        defaults.set(fullscreen, forKey: "fullscreen")
        defaults.set(fullscreenExclusive, forKey: "fullscreenExclusive")
        defaults.set(vsync, forKey: "vsync")
        defaults.set(msaa, forKey: "msaa")
        defaults.set(framerateLimit, forKey: "framerateLimit")
        defaults.set(textureFilter.rawValue, forKey: "textureFilter")
        defaults.set(detailTextures, forKey: "detailTextures")
        defaults.set(useFramebuffers, forKey: "useFramebuffers")
        defaults.set(allowRetinaResolution, forKey: "allowRetinaResolution")
        defaults.set(trackpadMode, forKey: "trackpadMode")
        defaults.set(maximize, forKey: "maximize")
        defaults.set(textureFilter2D, forKey: "textureFilter2D")
        defaults.set(displayFPS, forKey: "displayFPS")
        defaults.set(displayFPSInterval, forKey: "displayFPSInterval")
        defaults.set(centerWindow, forKey: "centerWindow")
        
        // Debug/Developer settings
        defaults.set(tickRateDivisor, forKey: "tickRateDivisor")
        defaults.set(extraSleep, forKey: "extraSleep")
        
        defaults.set(memorySize, forKey: "memorySize")
        defaults.set(skipIntro, forKey: "skipIntro")
        defaults.set(hudCenter.rawValue, forKey: "hudCenter")
        defaults.set(menuMouseControl, forKey: "menuMouseControl")
        defaults.set(screenShakeIntensity, forKey: "screenShakeIntensity")
        defaults.set(disableMpDeathMusic, forKey: "disableMpDeathMusic")
        defaults.set(geMuzzleFlashes, forKey: "geMuzzleFlashes")
        defaults.set(maxExplosions, forKey: "maxExplosions")
        
        defaults.set(disableSound, forKey: "disableSound")
        
        defaults.set(player1FovY, forKey: "player1FovY")
        defaults.set(player1FovAffectsZoom, forKey: "player1FovAffectsZoom")
        defaults.set(player1MouseAimMode, forKey: "player1MouseAimMode")
        defaults.set(player1MouseAimSpeedX, forKey: "player1MouseAimSpeedX")
        defaults.set(player1MouseAimSpeedY, forKey: "player1MouseAimSpeedY")
        defaults.set(crosshairSway, forKey: "crosshairSway")
        defaults.set(crosshairSize, forKey: "crosshairSize")
        defaults.set(crosshairHealth, forKey: "crosshairHealth")
        defaults.set(extendedControls, forKey: "extendedControls")
        defaults.set(radialMenuSpeed, forKey: "radialMenuSpeed")
        defaults.set(crouchMode.rawValue, forKey: "crouchMode")
        defaults.set(useKeyReloads, forKey: "useKeyReloads")
        
        // Input settings
        defaults.set(mouseEnabled, forKey: "mouseEnabled")
        defaults.set(mouseSpeedX, forKey: "mouseSpeedX")
        defaults.set(mouseSpeedY, forKey: "mouseSpeedY")
        defaults.set(fakeGamepads, forKey: "fakeGamepads")
        
        defaults.set(gameExecutablePath, forKey: "gameExecutablePath")
        defaults.set(gameDataPath, forKey: "gameDataPath")
    }
    
    func resetToDefaults() {
        isLoading = true
        
        windowWidth = 1440
        windowHeight = 900
        fullscreen = false
        fullscreenExclusive = false
        vsync = 1
        msaa = 1
        framerateLimit = 0
        textureFilter = .linear
        detailTextures = false
        useFramebuffers = true
        allowRetinaResolution = false
        trackpadMode = true
        maximize = false
        textureFilter2D = false
        displayFPS = false
        displayFPSInterval = 1.0
        centerWindow = true
        
        // Debug/Developer defaults
        tickRateDivisor = 0
        extraSleep = false
        
        memorySize = 16
        skipIntro = false
        hudCenter = .normal
        menuMouseControl = false
        screenShakeIntensity = 1.0
        disableMpDeathMusic = false
        geMuzzleFlashes = false
        maxExplosions = 24
        
        disableSound = false
        
        player1FovY = 60.0
        player1FovAffectsZoom = false
        player1MouseAimMode = false
        player1MouseAimSpeedX = 1.0
        player1MouseAimSpeedY = 1.0
        crosshairSway = 1.0
        crosshairSize = 0
        crosshairHealth = 0
        extendedControls = false
        radialMenuSpeed = 1.0
        crouchMode = .hold
        useKeyReloads = false
        
        // Input defaults
        mouseEnabled = true
        mouseSpeedX = 1.0
        mouseSpeedY = 1.0
        fakeGamepads = 0
        
        isLoading = false
        saveSettings()
    }
    
    var isReadyToLaunch: Bool {
        return !romPath.isEmpty && FileManager.default.fileExists(atPath: romPath)
    }
    
    var romFileName: String {
        return (romPath as NSString).lastPathComponent
    }
    
    func detectRomRegion() {
        let fileName = romFileName.lowercased()
        if fileName.contains("pal") || fileName.contains("europe") {
            romRegion = .palFinal
        } else if fileName.contains("jpn") || fileName.contains("japan") {
            romRegion = .jpnFinal
        } else {
            romRegion = .ntscFinal
        }
    }
}
