## LaunchAgents

On `launchd` and `launchdctl`:</br>
https://www.launchd.info

On `launchd.plist`:</br>
https://www.manpagez.com/man/5/launchd.plist/

### LaunchAgent-AppDelegate-DispatchSource

```Swift
private func setupEventHandlers() {
    signal(SIGHUP, SIG_IGN)
    signal(SIGINT, SIG_IGN)
    signal(SIGTERM, SIG_IGN)
    
    sighupSource.setEventHandler {
        [weak self] in
        
        self?.handleQuitEvent("SIGHUP")
    }
    sighupSource.resume()
    
    sigintSource.setEventHandler {
        [weak self] in
        
        self?.handleQuitEvent("SIGINT")
    }
    sigintSource.resume()
    
    sigtermSource.setEventHandler {
        [weak self] in
        
        self?.handleQuitEvent("SIGTERM")
    }
    sigtermSource.resume()
}
```

### LaunchAgent-AppDelegate-NotificationCenter

Launch agent with `AppDelegate` should use `NotificationCenter`

```Swift
private func setupWorkspaceNotifications() {
    let center = NSWorkspace.shared.notificationCenter
    center.addObserver(self, selector: #selector(AppDelegate.handleWillPowerOff(_:)), name: NSWorkspace.willPowerOffNotification, object: nil)
}

@objc
private func handleWillPowerOff(_ notification: Notification) {
    handleQuitEvent()
}
```

### LaunchAgent-DispatchSource

```Swift
func main() -> Int32 {
    signal(SIGTERM, SIG_IGN)
    let termSource = DispatchSource.makeSignalSource(signal: SIGTERM)
    termSource.setEventHandler {
        handleQuitEvent()
        
        exit(EXIT_SUCCESS)
    }
    termSource.resume()
    
    dispatchMain()
}
```

## Additional Information

### LLDB process handling

To change how LLDB handles signals:

```sh
process handle <SIGNALNAME> [ --pass <true|false|1|0> ] [ --stop <true|false|1|0> ] [ --notify <true|false|1|0> ]
```

Sample:

```sh
process handle SIGTERM --stop false --pass true
```

### Launch agent *.plist (App.plist)

```xml
LSUIElement <boolean>
```

A Boolean value indicating whether the app is an agent app that runs in the background and doesn't appear in the Dock.
### Launch agent *.plist (launchd.plist)

```
ExitTimeOut <integer>
```
The amount of time launchd waits before sending a SIGKILL signal. The default value is 20 seconds. The value zero is interpreted as infinity.

### Notes

Each sample has a directory `Install` which contains helper shell scripts to install (generate `launchd.plist`) and run the launch agent.
