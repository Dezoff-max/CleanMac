import CleanMacCore
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
        case .dashboard: L.t("section.dashboard")
        case .scan: L.t("section.scan")
        case .results: L.t("section.results")
        case .permissions: L.t("section.permissions")
        case .settings: L.t("section.settings")
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

    init(_ riskLevel: CleanupRiskLevel) {
        switch riskLevel {
        case .safe: self = .safe
        case .review: self = .review
        }
    }

    var title: String {
        switch self {
        case .safe: L.t("risk.safe")
        case .review: L.t("risk.review")
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
    let category: CleanupCategory
    let title: String
    let detail: String
    let pathHint: String
    let systemImage: String
    let risk: CleanupRisk
    let isDefaultSelected: Bool

    var id: String { category.rawValue }
}

struct ScanResult: Identifiable {
    let id: String
    let category: CleanupCategory
    let title: String
    let location: String
    let size: String
    let sizeBytes: Int64
    let risk: CleanupRisk
    let isDirectory: Bool
    let isSizeEstimate: Bool
    let modified: String

    init(item: CleanupScanItem) {
        id = item.id
        category = item.category
        title = item.displayName
        location = item.path
        size = CleanMacFormatters.bytes(item.sizeBytes)
        sizeBytes = item.sizeBytes
        risk = CleanupRisk(item.risk)
        isDirectory = item.isDirectory
        isSizeEstimate = item.isSizeEstimate
        modified = CleanMacFormatters.relativeDate(item.modifiedAt)
    }
}

enum PermissionState {
    case granted
    case limited
    case unknown
    case recommended
    case later

    var title: String {
        switch self {
        case .granted: L.t("permission.state.granted")
        case .limited: L.t("permission.state.limited")
        case .unknown: L.t("permission.state.unknown")
        case .recommended: L.t("permission.state.recommended")
        case .later: L.t("permission.state.later")
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
    static func metrics(report: CleanupScanReport?, selectedAreaCount: Int) -> [DashboardMetric] {
        [
            DashboardMetric(
                id: "selected",
                title: L.t("metric.selected.title"),
                value: "\(selectedAreaCount)",
                footnote: L.t("metric.selected.footnote"),
                systemImage: "folder.badge.gearshape"
            ),
            DashboardMetric(
                id: "found",
                title: L.t("metric.found.title"),
                value: "\(report?.items.count ?? 0)",
                footnote: L.t("metric.found.footnote"),
                systemImage: "checklist"
            ),
            DashboardMetric(
                id: "space",
                title: L.t("metric.space.title"),
                value: CleanMacFormatters.bytes(report?.totalSizeBytes ?? 0),
                footnote: report == nil ? L.t("metric.space.empty") : L.t("metric.space.footnote"),
                systemImage: "externaldrive"
            )
        ]
    }

    static var cleanupAreas: [CleanupArea] {
        [
            CleanupArea(
                category: .userCaches,
                title: L.t("area.userCaches.title"),
                detail: L.t("area.userCaches.detail"),
                pathHint: "~/Library/Caches",
                systemImage: "shippingbox",
                risk: .safe,
                isDefaultSelected: true
            ),
            CleanupArea(
                category: .browserCaches,
                title: L.t("area.browserCaches.title"),
                detail: L.t("area.browserCaches.detail"),
                pathHint: "~/Library/Caches/{Safari, Google, Firefox, ...}",
                systemImage: "safari",
                risk: .safe,
                isDefaultSelected: true
            ),
            CleanupArea(
                category: .nodePackageCaches,
                title: L.t("area.nodeCaches.title"),
                detail: L.t("area.nodeCaches.detail"),
                pathHint: "~/.npm, ~/Library/Caches/Yarn, pnpm",
                systemImage: "curlybraces.square",
                risk: .safe,
                isDefaultSelected: true
            ),
            CleanupArea(
                category: .swiftPackageBuilds,
                title: L.t("area.swiftpm.title"),
                detail: L.t("area.swiftpm.detail"),
                pathHint: "~/Library/Caches/org.swift.swiftpm",
                systemImage: "swift",
                risk: .safe,
                isDefaultSelected: true
            ),
            CleanupArea(
                category: .logs,
                title: L.t("area.logs.title"),
                detail: L.t("area.logs.detail"),
                pathHint: "~/Library/Logs",
                systemImage: "doc.text.magnifyingglass",
                risk: .safe,
                isDefaultSelected: true
            ),
            CleanupArea(
                category: .temporaryFiles,
                title: L.t("area.temporary.title"),
                detail: L.t("area.temporary.detail"),
                pathHint: "$TMPDIR",
                systemImage: "clock.arrow.circlepath",
                risk: .safe,
                isDefaultSelected: true
            ),
            CleanupArea(
                category: .trash,
                title: L.t("area.trash.title"),
                detail: L.t("area.trash.detail"),
                pathHint: "~/.Trash",
                systemImage: "trash",
                risk: .review,
                isDefaultSelected: false
            ),
            CleanupArea(
                category: .downloads,
                title: L.t("area.downloads.title"),
                detail: L.t("area.downloads.detail"),
                pathHint: "~/Downloads",
                systemImage: "arrow.down.circle",
                risk: .review,
                isDefaultSelected: false
            ),
            CleanupArea(
                category: .downloadedInstallers,
                title: L.t("area.installers.title"),
                detail: L.t("area.installers.detail"),
                pathHint: "~/Downloads/*.dmg, *.pkg, *.zip, *.xip",
                systemImage: "opticaldiscdrive",
                risk: .review,
                isDefaultSelected: false
            ),
            CleanupArea(
                category: .xcodeDerivedData,
                title: L.t("area.xcode.title"),
                detail: L.t("area.xcode.detail"),
                pathHint: "~/Library/Developer/Xcode/DerivedData",
                systemImage: "hammer",
                risk: .review,
                isDefaultSelected: true
            )
        ]
    }

    static func permissions(fullDiskAccess: FullDiskAccessCheckResult) -> [PermissionItem] {
        [
            PermissionItem(
                id: "files",
                title: L.t("permission.files.title"),
                detail: L.t("permission.files.detail"),
                systemImage: "folder",
                state: .recommended
            ),
            PermissionItem(
                id: "full-disk",
                title: L.t("permission.fullDisk.title"),
                detail: fullDiskDetail(for: fullDiskAccess),
                systemImage: "internaldrive",
                state: permissionState(for: fullDiskAccess.state)
            ),
            PermissionItem(
                id: "automation",
                title: L.t("permission.automation.title"),
                detail: L.t("permission.automation.detail"),
                systemImage: "wand.and.stars",
                state: .later
            )
        ]
    }

    private static func permissionState(for fullDiskState: FullDiskAccessState) -> PermissionState {
        switch fullDiskState {
        case .granted: .granted
        case .limited: .limited
        case .unknown: .unknown
        }
    }

    private static func fullDiskDetail(for result: FullDiskAccessCheckResult) -> String {
        switch result.state {
        case .granted:
            L.f("permission.fullDisk.detail.granted", result.readableProbeCount, result.availableProbeCount)
        case .limited:
            L.f("permission.fullDisk.detail.limited", result.readableProbeCount, result.availableProbeCount)
        case .unknown:
            L.t("permission.fullDisk.detail.unknown")
        }
    }

    static func area(for category: CleanupCategory) -> CleanupArea {
        cleanupAreas.first { $0.category == category } ?? cleanupAreas[0]
    }
}
