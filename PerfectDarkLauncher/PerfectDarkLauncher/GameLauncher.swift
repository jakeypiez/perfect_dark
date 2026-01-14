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
        
        // Sound disable
        if settings.disableSound {
            arguments.append("--no-sound")
        }
        
        // Skip intro
        if settings.skipIntro {
            arguments.append("--skip-intro")
        }
        
        // Launch the game
        do {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = arguments
            process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)
            
            // Set up environment
            var environment = ProcessInfo.processInfo.environment
            environment["DYLD_LIBRARY_PATH"] = workingDirectory
            process.environment = environment
            
            try process.run()
            
            return .success(())
        } catch {
            return .failure(.failedToLaunch(error.localizedDescription))
        }
    }
    
    private func findExecutable(settings: GameSettings) -> String? {
        // Check if user specified a path
        if !settings.gameExecutablePath.isEmpty && FileManager.default.fileExists(atPath: settings.gameExecutablePath) {
            return settings.gameExecutablePath
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
    
    private func getArchitecture() -> String {
        #if arch(arm64)
        return "arm64"
        #elseif arch(x86_64)
        return "x86_64"
        #else
        return "unknown"
        #endif
    }
    
    private func getWorkingDirectory(settings: GameSettings, executablePath: String) -> String {
        if !settings.gameDataPath.isEmpty {
            return settings.gameDataPath
        }
        return (executablePath as NSString).deletingLastPathComponent
    }
    
    private func writeConfigFile(settings: GameSettings, directory: String) -> Result<Void, LaunchError> {
        let configPath = (directory as NSString).appendingPathComponent("pd.ini")
        
        let config = """
        ; Perfect Dark PC Port Configuration
        ; Generated by Perfect Dark Launcher
        
        [Video]
        Width=\(settings.windowWidth)
        Height=\(settings.windowHeight)
        Fullscreen=\(settings.fullscreen ? 1 : 0)
        FullscreenExclusive=\(settings.fullscreenExclusive ? 1 : 0)
        Vsync=\(settings.vsync)
        MSAA=\(settings.msaa)
        FramerateLimit=\(settings.framerateLimit)
        TextureFilter=\(settings.textureFilter.rawValue)
        DetailTextures=\(settings.detailTextures ? 1 : 0)
        Framebuffers=\(settings.useFramebuffers ? 1 : 0)
        
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
        MouseAimSpeedX=\(String(format: "%.2f", settings.player1MouseAimSpeedX))
        MouseAimSpeedY=\(String(format: "%.2f", settings.player1MouseAimSpeedY))
        
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
