import Foundation

enum CleanMacSection: String, CaseIterable, Identifiable {
    case dashboard
    case scan
    case results
    case permissions
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: "Dashboard"
        case .scan: "Scan"
        case .results: "Results"
        case .permissions: "Permissions"
        case .settings: "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: "gauge.with.dots.needle.67percent"
        case .scan: "magnifyingglass"
        case .results: "checklist"
        case .permissions: "lock.shield"
        case .settings: "gearshape"
        }
    }
}

enum CleanupRisk: String {
    case safe
    case review

    var title: String {
        switch self {
        case .safe: "Safe"
        case .review: "Review"
        }
    }
}

struct DashboardMetric: Identifiable {
    let id: String
    let title: String
    let value: String
    let footnote: String
    let systemImage: String
}

struct CleanupArea: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let pathHint: String
    let estimate: String
    let systemImage: String
    let risk: CleanupRisk
    let isDefaultSelected: Bool
}

struct ScanResult: Identifiable {
    let id: String
    let title: String
    let location: String
    let size: String
    let risk: CleanupRisk
}

enum PermissionState {
    case granted
    case recommended
    case later

    var title: String {
        switch self {
        case .granted: "Ready"
        case .recommended: "Recommended"
        case .later: "Later"
        }
    }
}

struct PermissionItem: Identifiable {
    let id: String
    let title: String
    let detail: String
    let systemImage: String
    let state: PermissionState
}

enum CleanMacCatalog {
    static let metrics = [
        DashboardMetric(
            id: "areas",
            title: "Scan Areas",
            value: "6",
            footnote: "Configured for safe review",
            systemImage: "folder.badge.gearshape"
        ),
        DashboardMetric(
            id: "mode",
            title: "Cleanup Mode",
            value: "Manual",
            footnote: "Confirmation stays required",
            systemImage: "hand.raised"
        ),
        DashboardMetric(
            id: "status",
            title: "Status",
            value: "Idle",
            footnote: "Ready for first scan",
            systemImage: "bolt.horizontal.circle"
        )
    ]

    static let cleanupAreas = [
        CleanupArea(
            id: "user-cache",
            title: "User Caches",
            detail: "Application cache folders in the current user Library.",
            pathHint: "~/Library/Caches",
            estimate: "Review",
            systemImage: "shippingbox",
            risk: .safe,
            isDefaultSelected: true
        ),
        CleanupArea(
            id: "logs",
            title: "Logs",
            detail: "Rotated and older diagnostic logs.",
            pathHint: "~/Library/Logs",
            estimate: "Review",
            systemImage: "doc.text.magnifyingglass",
            risk: .safe,
            isDefaultSelected: true
        ),
        CleanupArea(
            id: "temp",
            title: "Temporary Files",
            detail: "Temporary folders that should be scanned before removal.",
            pathHint: "$TMPDIR",
            estimate: "Review",
            systemImage: "clock.arrow.circlepath",
            risk: .safe,
            isDefaultSelected: true
        ),
        CleanupArea(
            id: "trash",
            title: "Trash",
            detail: "Items already moved to Trash.",
            pathHint: "~/.Trash",
            estimate: "Review",
            systemImage: "trash",
            risk: .review,
            isDefaultSelected: false
        ),
        CleanupArea(
            id: "downloads",
            title: "Downloads Review",
            detail: "Large downloads and installers that need manual review.",
            pathHint: "~/Downloads",
            estimate: "Manual",
            systemImage: "arrow.down.circle",
            risk: .review,
            isDefaultSelected: false
        ),
        CleanupArea(
            id: "xcode",
            title: "Xcode Derived Data",
            detail: "Build caches that can grow quickly during development.",
            pathHint: "~/Library/Developer/Xcode/DerivedData",
            estimate: "Review",
            systemImage: "hammer",
            risk: .review,
            isDefaultSelected: true
        )
    ]

    static let permissions = [
        PermissionItem(
            id: "files",
            title: "Files and Folders",
            detail: "Required for scanning selected user folders.",
            systemImage: "folder",
            state: .recommended
        ),
        PermissionItem(
            id: "full-disk",
            title: "Full Disk Access",
            detail: "Needed only for deeper Library and system-adjacent scans.",
            systemImage: "internaldrive",
            state: .later
        ),
        PermissionItem(
            id: "automation",
            title: "Automation",
            detail: "Optional for opening Finder and System Settings shortcuts.",
            systemImage: "wand.and.stars",
            state: .later
        )
    ]

    static func previewResults(for selectedAreaIDs: Set<String>) -> [ScanResult] {
        cleanupAreas.filter { selectedAreaIDs.contains($0.id) }.map { area in
            ScanResult(
                id: area.id,
                title: area.title,
                location: area.pathHint,
                size: previewSize(for: area.id),
                risk: area.risk
            )
        }
    }

    private static func previewSize(for id: String) -> String {
        switch id {
        case "user-cache": "1.4 GB"
        case "logs": "320 MB"
        case "temp": "860 MB"
        case "trash": "2.1 GB"
        case "downloads": "Manual"
        case "xcode": "5.8 GB"
        default: "Review"
        }
    }
}
