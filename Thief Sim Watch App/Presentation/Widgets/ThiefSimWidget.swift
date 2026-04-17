import WidgetKit
import SwiftUI

struct SimpleEntry: TimelineEntry {
    let date: Date
    let balance: Int
    let districtId: DistrictID
}

struct ComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), balance: 1000, districtId: .outskirts)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let (balance, districtId) = ComplicationDataService.shared.load()
        let entry = SimpleEntry(date: Date(), balance: balance, districtId: districtId)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let (balance, districtId) = ComplicationDataService.shared.load()
        let entry = SimpleEntry(date: Date(), balance: balance, districtId: districtId)
        
        // Complications don't need frequent updates unless the app is running,
        // and the app requests reloads via WidgetCenter when data changes.
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct ThiefSimComplicationView: View {
    var entry: SimpleEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            CircularView(entry: entry)
                .widgetURL(URL(string: "thiefsim://district/\(entry.districtId.rawValue)"))
        case .accessoryRectangular:
            RectangularView(entry: entry)
                .widgetURL(URL(string: "thiefsim://district/\(entry.districtId.rawValue)"))
        default:
            Text("Thief")
                .widgetURL(URL(string: "thiefsim://district/\(entry.districtId.rawValue)"))
        }
    }
}

private struct CircularView: View {
    let entry: SimpleEntry
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Image(systemName: "mask.fill")
                    .font(.system(size: 10))
                Text("$\(entry.balance)")
                    .font(.system(size: 8, weight: .bold))
                    .minimumScaleFactor(0.5)
            }
        }
    }
}

private struct RectangularView: View {
    let entry: SimpleEntry
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "mask.fill")
                        .foregroundColor(.blue)
                    Text("Thief Sim")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                
                Text(districtName(for: entry.districtId))
                    .font(.caption)
                Text("Balance: $\(entry.balance)")
                    .font(.caption2)
                    .foregroundColor(.yellow)
            }
            Spacer()
        }
    }
    
    private func districtName(for id: DistrictID) -> String {
        switch id {
        case .outskirts: return "Примістя"
        case .center: return "Центр"
        case .island: return "Острів"
        }
    }
}

struct ThiefSimWidget: Widget {
    let kind: String = "ThiefSimWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ComplicationProvider()) { entry in
            ThiefSimComplicationView(entry: entry)
                .containerBackground(.black.gradient, for: .widget)
        }
        .configurationDisplayName("Thief Sim Status")
        .description("Shows your current balance and district.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

// Since complications are now Widgets, we need a WidgetBundle if we want 
// to support multiple widgets, or just one Widget.
// Note: To make this active, it needs to be part of a target that has
// the @main attribute for WidgetBundle. In watchOS 10, the app target itself
// can sometimes host widgets but usually a separate "Watch Widget Extension" 
// target is created.
struct ThiefSimWidgetBundle: WidgetBundle {
    var body: some Widget {
        ThiefSimWidget()
    }
}
