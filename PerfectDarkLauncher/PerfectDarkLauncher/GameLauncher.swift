import Foundation
import AppKit

class GameLauncher {
    static let shared = GameLauncher()
    
    enum LaunchError: LocalizedError {
        case romNotFound
        case executableNotFound
        case failedToCreateConfigFile
        case failedToLaunch(String)
        case invalidConfiguration(String)
        
        var errorDescription: String? {
            switch self {
            case .romNotFound:
                return "ROM file not found. Please select a valid ROM file."
            case .executableNotFound:
                return "Game executable not found. Please build the game or specify the executable path in Advanced settings."
            case .failedToCreateConfigFile:
                return "Failed to create configuration file."
            case .failedToLaunch(let message):
                return "Failed to launch game: \(message)"
            case .invalidConfiguration(let message):
                return "Invalid configuration: \(message)"
            }
        }
    }
    
    private init() {}
    
    func launchGame(settings: GameSettings) -> Result<Void, LaunchError> {
        // Verify ROM exists
        guard FileManager.default.fileExists(atPath: settings.romPath) else {
            return .failure(.romNotFound)
        }
        
        // Find executable
        let executablePath = findExecutable(settings: settings)
        guard let executable = executablePath, FileManager.default.fileExists(atPath: executable) else {
            return .failure(.executableNotFound)
        }
        
        // Determine working directory
        let workingDirectory = getWorkingDirectory(settings: settings, executablePath: executable)
        
        // Create/update config file
        if case .failure(let error) = writeConfigFile(settings: settings, directory: workingDirectory) {
            return .failure(error)
        }
        
        // Setup ROM file (copy or symlink if needed)
        if case .failure(let error) = setupRomFile(settings: settings, directory: workingDirectory) {
            return .failure(error)
        }
        
        // Build launch arguments
        var arguments: [String] = []
        
        // ROM file argument
        arguments.append("--rom-file")
        arguments.append(settings.romPath)
        
        // Save directory (where pd.ini goes) - uses lowercase "perfectdark" to match SDL_GetPrefPath
        arguments.append("--savedir")
        arguments.append(workingDirectory)
        
        // Base directory (where data folder is) - should be where the ROM or data folder is
        let baseDir = findBaseDirectory(romPath: settings.romPath, settings: settings)
        if let baseDir = baseDir {
            arguments.append("--basedir")
            arguments.append(baseDir)
        }
        
        // Sound disable
        if settings.disableSound {
            arguments.append("--no-sound")
        }
        
        // Skip intro
        if settings.skipIntro {
            arguments.append("--skip-intro")
        }
        
        // Launch the game by replacing this process with the game (execv)
        // This makes the game "become" Carrington - single Dock icon
        
        // Change to working directory
        FileManager.default.changeCurrentDirectoryPath(workingDirectory)
        
        // Set environment variables
        setenv("DYLD_LIBRARY_PATH", workingDirectory, 1)
        
        // Build argv for execv (executable path + arguments + NULL terminator)
        var argv: [UnsafeMutablePointer<CChar>?] = []
        argv.append(strdup(executable))
        for arg in arguments {
            argv.append(strdup(arg))
        }
        argv.append(nil)
        
        // Replace this process with the game
        execv(executable, &argv)
        
        // If execv returns, it failed
        return .failure(.failedToLaunch("execv failed: \(String(cString: strerror(errno)))"))
    }
    
    private func findExecutable(settings: GameSettings) -> String? {
        // Check if user specified a path
        if !settings.gameExecutablePath.isEmpty && FileManager.default.fileExists(atPath: settings.gameExecutablePath) {
            return settings.gameExecutablePath
        }
        
        // First, check for bundled executables in the app bundle
        if let bundledExecutable = findBundledExecutable(settings: settings) {
            return bundledExecutable
        }
        
        let romDirectory = (settings.romPath as NSString).deletingLastPathComponent
        
        // Common executable names based on architecture
        let arch = getArchitecture()
        let possibleNames = [
            "pd.\(arch)",
            "pd",
            "pd.osx",
            "pd.arm64",
            "pd.x86_64",
            "Perfect Dark",
            "PerfectDark"
        ]
        
        // Look in ROM directory
        for name in possibleNames {
            let path = (romDirectory as NSString).appendingPathComponent(name)
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        
        // Look in data directory if specified
        if !settings.gameDataPath.isEmpty {
            for name in possibleNames {
                let path = (settings.gameDataPath as NSString).appendingPathComponent(name)
                if FileManager.default.isExecutableFile(atPath: path) {
                    return path
                }
            }
        }
        
        // Look in common build directories relative to ROM
        let buildDirs = [
            "build",
            "Build",
            "bin",
            "../build",
            "../Build"
        ]
        
        for dir in buildDirs {
            let buildPath = (romDirectory as NSString).appendingPathComponent(dir)
            for name in possibleNames {
                let path = (buildPath as NSString).appendingPathComponent(name)
                if FileManager.default.isExecutableFile(atPath: path) {
                    return path
                }
            }
        }
        
        return nil
    }
    
    private func findBundledExecutable(settings: GameSettings) -> String? {
        guard let resourcePath = Bundle.main.resourcePath else { return nil }
        
        // Map region to executable name
        let executableName: String
        switch settings.romRegion {
        case .ntscFinal:
            executableName = "pd.arm64"
        case .palFinal:
            executableName = "pd.pal.arm64"
        case .jpnFinal:
            executableName = "pd.jpn.arm64"
        }
        
        let bundledPath = (resourcePath as NSString).appendingPathComponent(executableName)
        
        if FileManager.default.isExecutableFile(atPath: bundledPath) {
            return bundledPath
        }
        
        // Fallback: try to find any bundled executable
        let fallbackNames = ["pd.arm64", "pd.pal.arm64", "pd.jpn.arm64"]
        for name in fallbackNames {
            let path = (resourcePath as NSString).appendingPathComponent(name)
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        
        return nil
    }
    
    private func getArchitecture() -> String {
        #if arch(arm64)
        return "arm64"
        #elseif arch(x86_64)
        return "x86_64"
        #else
        return "unknown"
        #endif
    }
    
    private func findBaseDirectory(romPath: String, settings: GameSettings) -> String? {
        // If user specified a data path, check for "data" subfolder there
        if !settings.gameDataPath.isEmpty {
            let dataPath = (settings.gameDataPath as NSString).appendingPathComponent("data")
            if FileManager.default.fileExists(atPath: dataPath) {
                return dataPath
            }
            // Maybe they pointed directly at data folder
            if settings.gameDataPath.hasSuffix("/data") || settings.gameDataPath.hasSuffix("/data/") {
                return settings.gameDataPath
            }
        }
        
        // Check ROM directory for "data" folder
        let romDirectory = (romPath as NSString).deletingLastPathComponent
        let romDataPath = (romDirectory as NSString).appendingPathComponent("data")
        if FileManager.default.fileExists(atPath: romDataPath) {
            return romDataPath
        }
        
        // Check parent of ROM directory
        let parentDirectory = (romDirectory as NSString).deletingLastPathComponent
        let parentDataPath = (parentDirectory as NSString).appendingPathComponent("data")
        if FileManager.default.fileExists(atPath: parentDataPath) {
            return parentDataPath
        }
        
        // Check Application Support
        let appSupportData = (getApplicationSupportDirectory() as NSString).appendingPathComponent("data")
        if FileManager.default.fileExists(atPath: appSupportData) {
            return appSupportData
        }
        
        // Let the game figure it out from executable directory
        return nil
    }
    
    private func getWorkingDirectory(settings: GameSettings, executablePath: String) -> String {
        // If user specified a data path, use that
        if !settings.gameDataPath.isEmpty {
            return settings.gameDataPath
        }
        
        // If executable is bundled in app, use Application Support directory
        if executablePath.contains(".app/Contents/Resources") {
            return getApplicationSupportDirectory()
        }
        
        // Otherwise use executable's directory
        return (executablePath as NSString).deletingLastPathComponent
    }
    
    private func getApplicationSupportDirectory() -> String {
        let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        // Note: Must be lowercase "perfectdark" to match SDL_GetPrefPath("", "perfectdark")
        let pdSupportURL = appSupportURL.appendingPathComponent("perfectdark")
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: pdSupportURL, withIntermediateDirectories: true)
        
        return pdSupportURL.path
    }
    
    private func writeConfigFile(settings: GameSettings, directory: String) -> Result<Void, LaunchError> {
        let configPath = (directory as NSString).appendingPathComponent("pd.ini")
        
        // Note: Key names must match those registered in the game's video.c and main.c
        // Video settings use "Video.Default*" prefix for resolution/window settings
        let config = """
        ; Perfect Dark PC Port Configuration
        ; Generated by Perfect Dark Launcher
        
        [Video]
        DefaultWidth=\(settings.windowWidth)
        DefaultHeight=\(settings.windowHeight)
        DefaultFullscreen=\(settings.fullscreen ? 1 : 0)
        DefaultMaximize=\(settings.maximize ? 1 : 0)
        ExclusiveFullscreen=\(settings.fullscreenExclusive ? 1 : 0)
        CenterWindow=1
        VSync=\(settings.vsync)
        MSAA=\(settings.msaa)
        FramerateLimit=\(settings.framerateLimit)
        TextureFilter=\(settings.textureFilter.rawValue)
        TextureFilter2D=\(settings.textureFilter2D ? 1 : 0)
        DetailTextures=\(settings.detailTextures ? 1 : 0)
        FramebufferEffects=\(settings.useFramebuffers ? 1 : 0)
        AllowHiDpi=\(settings.allowRetinaResolution ? 1 : 0)
        DisplayFPS=\(settings.displayFPS ? 1 : 0)
        
        [Game]
        MemorySize=\(settings.memorySize)
        SkipIntro=\(settings.skipIntro ? 1 : 0)
        CenterHUD=\(settings.hudCenter.rawValue)
        MenuMouseControl=\(settings.menuMouseControl ? 1 : 0)
        ScreenShakeIntensity=\(String(format: "%.2f", settings.screenShakeIntensity))
        DisableMpDeathMusic=\(settings.disableMpDeathMusic ? 1 : 0)
        GEMuzzleFlashes=\(settings.geMuzzleFlashes ? 1 : 0)
        MaxExplosions=\(settings.maxExplosions)
        
        [Game.Player1]
        FovY=\(String(format: "%.1f", settings.player1FovY))
        FovAffectsZoom=\(settings.player1FovAffectsZoom ? 1 : 0)
        MouseAimMode=\(settings.player1MouseAimMode ? 1 : 0)
        MouseAimSpeedX=\(String(format: "%.2f", settings.trackpadMode ? settings.player1MouseAimSpeedX * 0.6 : settings.player1MouseAimSpeedX))
        MouseAimSpeedY=\(String(format: "%.2f", settings.trackpadMode ? settings.player1MouseAimSpeedY * 0.6 : settings.player1MouseAimSpeedY))
        CrosshairSway=\(String(format: "%.2f", settings.crosshairSway))
        
        """
        
        // Check if config already exists and try to preserve unknown settings
        if FileManager.default.fileExists(atPath: configPath) {
            // For simplicity, we'll just overwrite. A more sophisticated approach
            // would parse and merge.
        }
        
        do {
            try config.write(toFile: configPath, atomically: true, encoding: .utf8)
            return .success(())
        } catch {
            return .failure(.failedToCreateConfigFile)
        }
    }
    
    private func setupRomFile(settings: GameSettings, directory: String) -> Result<Void, LaunchError> {
        // The ROM will be passed via command line, so we don't need to copy it
        // But we could optionally create a symlink for convenience
        
        let expectedRomName = settings.romRegion.expectedRomName
        let targetPath = (directory as NSString).appendingPathComponent(expectedRomName)
        
        // If ROM is not in the expected location, create a symlink
        if settings.romPath != targetPath && !FileManager.default.fileExists(atPath: targetPath) {
            do {
                try FileManager.default.createSymbolicLink(atPath: targetPath, withDestinationPath: settings.romPath)
            } catch {
                // Symlink failed, but that's okay - we'll pass the path via command line
            }
        }
        
        return .success(())
    }
}
