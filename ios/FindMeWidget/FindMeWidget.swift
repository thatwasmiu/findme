// SPIKE (throwaway, branch spike/ios-widget): does a widget work on an iPhone signed by Sideloadly with a free
// Apple ID? It shows whether the App Group is there and the last time the app wrote to it. Delete when the real
// iOS widget lands or the idea is dropped.
import SwiftUI
import WidgetKit

private let appGroup = "group.app.findme.mobile"

struct SpikeEntry: TimelineEntry {
  let date: Date
  let groupFound: Bool
  let appWrote: String
}

struct SpikeProvider: TimelineProvider {
  func placeholder(in context: Context) -> SpikeEntry {
    SpikeEntry(date: Date(), groupFound: false, appWrote: "…")
  }

  func getSnapshot(in context: Context, completion: @escaping (SpikeEntry) -> Void) {
    completion(read())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<SpikeEntry>) -> Void) {
    // Ask again in 15 minutes too, to see whether iOS lets the widget wake on its own.
    completion(Timeline(entries: [read()], policy: .after(Date().addingTimeInterval(15 * 60))))
  }

  private func read() -> SpikeEntry {
    let found =
      FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) != nil
    let wrote = UserDefaults(suiteName: appGroup)?.string(forKey: "spike") ?? "nothing"
    return SpikeEntry(date: Date(), groupFound: found, appWrote: wrote)
  }
}

struct SpikeView: View {
  let entry: SpikeEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("Find Me spike").font(.caption).bold()
      Text("group: \(entry.groupFound ? "OK" : "MISSING")").font(.caption2)
      Text("app wrote:").font(.caption2)
      Text(entry.appWrote).font(.caption2)
      Text("widget read:").font(.caption2)
      Text(entry.date, style: .time).font(.caption2)
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
    .supportedFamilies([.systemSmall])
  }
}
