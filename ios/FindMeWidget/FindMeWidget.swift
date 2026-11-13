// Test widget, kept while the iPhone widget is parked (docs/HANDOFF.md, guide chapter 17 "iPhone spike"): shows
// whether the signing gives the App Group the real widget needs. Sideloadly with a free Apple ID does not. Replace
// with the real widget once it does.
import SwiftUI
import WidgetKit

private let appGroup = "group.app.findme.mobile"

struct SpikeEntry: TimelineEntry {
  let date: Date
  let groupFound: Bool
  let appWrote: String
  let granted: String
}

struct SpikeProvider: TimelineProvider {
  func placeholder(in context: Context) -> SpikeEntry {
    SpikeEntry(date: Date(), groupFound: false, appWrote: "…", granted: "…")
  }

  func getSnapshot(in context: Context, completion: @escaping (SpikeEntry) -> Void) {
    completion(read())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<SpikeEntry>) -> Void) {
    completion(Timeline(entries: [read()], policy: .after(Date().addingTimeInterval(15 * 60))))
  }

  private func read() -> SpikeEntry {
    let found =
      FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) != nil
    let wrote = UserDefaults(suiteName: appGroup)?.string(forKey: "spike") ?? "nothing"
    return SpikeEntry(date: Date(), groupFound: found, appWrote: wrote, granted: grantedGroups())
  }
}

/// Round 3: the signing profiles of both the widget and the app it sits in, with a distinct word for each way
/// reading one can fail, so "no profile" no longer hides three different answers.
private func grantedGroups() -> String {
  let widget = Bundle.main.bundleURL  // …/Runner.app/PlugIns/FindMeWidget.appex
  let app = widget.deletingLastPathComponent().deletingLastPathComponent()  // …/Runner.app
  return "widget: \(describe(widget))\napp: \(describe(app))"
}

private func describe(_ bundle: URL) -> String {
  let url = bundle.appendingPathComponent("embedded.mobileprovision")
  guard FileManager.default.fileExists(atPath: url.path) else { return "no file" }
  guard let data = try? Data(contentsOf: url) else { return "unreadable" }
  // The profile is a signed blob with a plain XML plist inside it.
  guard let start = data.range(of: Data("<?xml".utf8)),
    let end = data.range(of: Data("</plist>".utf8), in: start.upperBound..<data.endIndex)
  else { return "no xml (\(data.count) B)" }
  guard
    let plist = try? PropertyListSerialization.propertyList(
      from: data.subdata(in: start.lowerBound..<end.upperBound), format: nil) as? [String: Any]
  else { return "bad plist" }
  let ents = plist["Entitlements"] as? [String: Any] ?? [:]
  let groups = ents["com.apple.security.application-groups"] as? [String] ?? []
  if groups.isEmpty { return "no groups" }
  return groups.map { g in
    let ok = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: g) != nil
    return "\(ok ? "+" : "-")\(g)"
  }.joined(separator: " ")
}

struct SpikeView: View {
  let entry: SpikeEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text("group: \(entry.groupFound ? "OK" : "MISSING")").font(.caption2).bold()
      Text("app wrote: \(entry.appWrote)").font(.caption2)
      Text("read: ") .font(.caption2) + Text(entry.date, style: .time).font(.caption2)
      Text("granted:").font(.caption2).bold()
      Text(entry.granted).font(.system(size: 9)).minimumScaleFactor(0.5)
    }
    .widgetBackground(Color(red: 1.0, green: 0.95, blue: 0.96))
  }
}

extension View {
  @ViewBuilder func widgetBackground(_ color: Color) -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      containerBackground(color, for: .widget)
    } else {
      padding().background(color)
    }
  }
}

@main
struct FindMeWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "FindMeWidget", provider: SpikeProvider()) { entry in
      SpikeView(entry: entry)
    }
    .configurationDisplayName("Find Me")
    .description("Spike")
    .supportedFamilies([.systemMedium, .systemSmall])
  }
}
