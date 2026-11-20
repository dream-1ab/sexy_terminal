// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  var engine: FlutterEngine?

  override func applicationDidFinishLaunching(_ notification: Notification) {
    engine = FlutterEngine(name: "project", project: nil)
    engine?.run(withEntrypoint:nil)
    RegisterGeneratedPlugins(registry: engine!)
    WindowDropInstaller.install(engine: engine!)
  }
}

private final class WindowDropInstaller: NSObject {
  private static var installedWindows = NSHashTable<NSWindow>.weakObjects()
  private static var initialWindows = NSHashTable<NSWindow>.weakObjects()
  private static var channel: FlutterMethodChannel?

  static func install(engine: FlutterEngine) {
    channel = FlutterMethodChannel(
      name: "desktop_drop",
      binaryMessenger: engine.binaryMessenger
    )
    let center = NotificationCenter.default
    center.addObserver(
      self,
      selector: #selector(windowDidBecomeKey(_:)),
      name: NSWindow.didBecomeKeyNotification,
      object: nil
    )
    center.addObserver(
      self,
      selector: #selector(windowDidBecomeMain(_:)),
      name: NSWindow.didBecomeMainNotification,
      object: nil
    )
    for window in NSApplication.shared.windows { initialWindows.add(window) }
  }

  @objc private static func windowDidBecomeKey(_ notification: Notification) {
    if let window = notification.object as? NSWindow { attach(to: window) }
  }

  @objc private static func windowDidBecomeMain(_ notification: Notification) {
    if let window = notification.object as? NSWindow { attach(to: window) }
  }

  private static func attach(to window: NSWindow) {
    guard let contentView = window.contentView,
          !initialWindows.contains(window),
          !installedWindows.contains(window),
          let channel else { return }
    let target = WindowDropTarget(frame: contentView.bounds, channel: channel)
    target.autoresizingMask = [.width, .height]
    contentView.addSubview(target)
    installedWindows.add(window)
  }
}

private final class WindowDropTarget: NSView {
  private let channel: FlutterMethodChannel

  init(frame: NSRect, channel: FlutterMethodChannel) {
    self.channel = channel
    super.init(frame: frame)
    registerForDraggedTypes([
      .fileURL,
      NSPasteboard.PasteboardType("NSFilenamesPboardType"),
    ])
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
    channel.invokeMethod("entered", arguments: point(sender.draggingLocation))
    return .copy
  }

  override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
    channel.invokeMethod("updated", arguments: point(sender.draggingLocation))
    return .copy
  }

  override func draggingExited(_ sender: NSDraggingInfo?) {
    channel.invokeMethod("exited", arguments: nil)
  }

  override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
    let urls = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self]) as? [NSURL] ?? []
    let items = urls.compactMap { url -> [String: Any]? in
      guard let path = url.path else { return nil }
      return ["path": path, "isDirectory": false, "fromPromise": false]
    }
    channel.invokeMethod("performOperation_macos", arguments: items)
    return !items.isEmpty
  }

  private func point(_ value: NSPoint) -> [CGFloat] {
    [value.x, bounds.height - value.y]
  }
}
