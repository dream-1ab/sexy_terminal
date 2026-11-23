import Cocoa
import FlutterMacOS


final class WindowDropInstaller: NSObject {
  private static var targets: [Int64: WindowDropTarget] = [:]
  private static var channel: FlutterMethodChannel?

  static func install(engine: FlutterEngine) {
    channel = FlutterMethodChannel(
      name: "reminal/window_file_drop",
      binaryMessenger: engine.binaryMessenger
    )
    channel?.setMethodCallHandler { call, result in
      guard let viewId = call.arguments as? Int64 else {
        result(FlutterError(code: "invalid_view", message: "Expected a view ID", details: nil))
        return
      }
      switch call.method {
      case "attach":
        if targets[viewId] != nil { result(nil); return }
        guard let controller = NSApplication.shared.windows
          .compactMap({ $0.contentViewController as? FlutterViewController })
          .first(where: { $0.attached() && $0.viewIdentifier == viewId }),
          let channel else {
          result(FlutterError(code: "view_not_found", message: "Flutter view not found", details: viewId))
          return
        }
        let target = WindowDropTarget(frame: controller.view.bounds, viewId: viewId, channel: channel)
        target.autoresizingMask = [.width, .height]
        controller.view.addSubview(target)
        targets[viewId] = target
        result(nil)
      case "detach":
        targets.removeValue(forKey: viewId)?.removeFromSuperview()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}

private final class WindowDropTarget: NSView {
  private let channel: FlutterMethodChannel
  private let viewId: Int64

  init(frame: NSRect, viewId: Int64, channel: FlutterMethodChannel) {
    self.channel = channel
    self.viewId = viewId
    super.init(frame: frame)
    registerForDraggedTypes([
      .fileURL,
      NSPasteboard.PasteboardType("NSFilenamesPboardType"),
    ])
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func hitTest(_ point: NSPoint) -> NSView? { nil }

  override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation { .copy }

  override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
    let urls = sender.draggingPasteboard.readObjects(
      forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]
    ) as? [URL] ?? []
    guard !urls.isEmpty else { return false }
    let position = convert(sender.draggingLocation, from: nil)
    channel.invokeMethod("drop", arguments: [
      "viewId": viewId, "x": position.x, "y": bounds.height - position.y,
      "paths": urls.map { $0.path },
    ])
    return true
  }
}
