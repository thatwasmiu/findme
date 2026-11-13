// SPIKE (throwaway, branch spike/ios-widget): does a widget work on an iPhone signed by Sideloadly with a free
// Apple ID? Round 1 showed "group: MISSING". Round 2 also lists the App Groups the signing profile actually granted,
// to tell "none at all" from "granted under another name". Delete when the real iOS widget lands or the idea is
// dropped.
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

/// The App Groups in this extension's signing profile, each marked "+" if iOS gives it a shared folder.
private func grantedGroups() -> String {
  guard let url = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision"),
    let data = try? Data(contentsOf: url),
    // The profile is a signed blob with a plain XML plist inside it.
    let text = String(data: data, encoding: .isoLatin1),
    let start = text.range(of: "<?xml"),
    let end = text.range(of: "</plist>"),
    let plist = try? PropertyListSerialization.propertyList(
      from: Data(text[start.lowerBound..<end.upperBound].utf8), format: nil) as? [String: Any],
    let ents = plist["Entitlements"] as? [String: Any]
  else { return "no profile" }
  let groups = ents["com.apple.security.application-groups"] as? [String] ?? []
  if groups.isEmpty { return "none" }
  return groups.map { g in
    let ok = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: g) != nil
    return "\(ok ? "+" : "-") \(g)"
  }.joined(separator: "\n")
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
