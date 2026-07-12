import CleanMacCore
import Foundation

enum CleanMacSection: String, CaseIterable, Identifiable {
    case dashboard
    case scan
    case results
    case diskAnalysis
    case applications
    case permissions
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: L.t("section.dashboard")
        case .scan: L.t("section.scan")
        case .results: L.t("section.results")
        case .diskAnalysis: L.t("section.diskAnalysis")
        case .applications: L.t("section.applications")
        case .permissions: L.t("section.permissions")
        case .settings: L.t("section.settings")
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: "gauge.with.dots.needle.67percent"
        case .scan: "magnifyingglass"
        case .results: "checklist"
        case .diskAnalysis: "chart.pie.fill"
        case .applications: "app.badge.checkmark"
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
    let reasons: [CleanupScanReason]

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
        reasons = item.reasons
    }

    var primaryReason: CleanupScanReason? {
        reasons.first
    }
}

extension CleanupScanReason {
    var title: String {
        switch self {
        case .applicationCache: L.t("results.reason.applicationCache.title")
        case .browserCache: L.t("results.reason.browserCache.title")
        case .nodePackageCache: L.t("results.reason.nodePackageCache.title")
        case .swiftPackageCache: L.t("results.reason.swiftPackageCache.title")
        case .staleLog: L.t("results.reason.staleLog.title")
        case .rotatedLog: L.t("results.reason.rotatedLog.title")
        case .staleTemporary: L.t("results.reason.staleTemporary.title")
        case .trashItem: L.t("results.reason.trashItem.title")
        case .largeDownload: L.t("results.reason.largeDownload.title")
        case .oldDownload: L.t("results.reason.oldDownload.title")
        case .installerArchive: L.t("results.reason.installerArchive.title")
        case .xcodeBuildData: L.t("results.reason.xcodeBuildData.title")
        }
    }

    var detail: String {
        switch self {
        case .applicationCache: L.t("results.reason.applicationCache.detail")
        case .browserCache: L.t("results.reason.browserCache.detail")
        case .nodePackageCache: L.t("results.reason.nodePackageCache.detail")
        case .swiftPackageCache: L.t("results.reason.swiftPackageCache.detail")
        case .staleLog: L.t("results.reason.staleLog.detail")
        case .rotatedLog: L.t("results.reason.rotatedLog.detail")
        case .staleTemporary: L.t("results.reason.staleTemporary.detail")
        case .trashItem: L.t("results.reason.trashItem.detail")
        case .largeDownload: L.t("results.reason.largeDownload.detail")
        case .oldDownload: L.t("results.reason.oldDownload.detail")
        case .installerArchive: L.t("results.reason.installerArchive.detail")
        case .xcodeBuildData: L.t("results.reason.xcodeBuildData.detail")
        }
    }

    var systemImage: String {
        switch self {
        case .applicationCache: "shippingbox"
        case .browserCache: "safari"
        case .nodePackageCache: "curlybraces.square"
        case .swiftPackageCache: "swift"
        case .staleLog: "doc.text.magnifyingglass"
        case .rotatedLog: "arrow.triangle.2.circlepath"
        case .staleTemporary: "clock.arrow.circlepath"
        case .trashItem: "trash"
        case .largeDownload: "externaldrive"
        case .oldDownload: "calendar.badge.clock"
        case .installerArchive: "opticaldiscdrive"
        case .xcodeBuildData: "hammer"
        }
    }
}

extension CleanupHistoryStatus {
    var title: String {
        switch self {
        case .inTrash: L.t("history.status.inTrash")
        case .restored: L.t("history.status.restored")
        case .restoreFailed: L.t("history.status.restoreFailed")
        }
    }

    var systemImage: String {
        switch self {
        case .inTrash: "trash"
        case .restored: "arrow.uturn.backward.circle"
        case .restoreFailed: "exclamationmark.triangle"
        }
    }
}

extension CleanupHistoryRecord {
    var title: String {
        let name = URL(fileURLWithPath: originalPath).lastPathComponent
        return name.isEmpty ? originalPath : name
    }

    var displayTrashedPath: String {
        trashedPath ?? L.t("history.trashPath.unknown")
    }

    var size: String {
        CleanMacFormatters.bytes(sizeBytes)
    }
}

extension CleanupRestoreFailureReason {
    var localizedHistoryMessage: String {
        switch self {
        case .missingTrashPath:
            L.t("restore.failure.missingTrashPath")
        case .missingTrashItem:
            L.t("restore.failure.missingTrashItem")
        case .outsideTrash:
            L.t("restore.failure.outsideTrash")
        case .symbolicLink:
            L.t("restore.failure.symbolicLink")
        case .outsideAllowedRoot:
            L.t("restore.failure.outsideAllowedRoot")
        case .destinationExists:
            L.t("restore.failure.destinationExists")
        case .missingOriginalParent:
            L.t("restore.failure.missingOriginalParent")
        case .moveFailed:
            L.t("restore.failure.moveFailed")
        }
    }
}

enum PermissionState {
    case granted
    case limited
    case unknown
    case recommended
    case notRequested
    case denied
    case unavailable
    case checking

    var title: String {
        switch self {
        case .granted: L.t("permission.state.granted")
        case .limited: L.t("permission.state.limited")
        case .unknown: L.t("permission.state.unknown")
        case .recommended: L.t("permission.state.recommended")
        case .notRequested: L.t("permission.state.notRequested")
        case .denied: L.t("permission.state.denied")
        case .unavailable: L.t("permission.state.unavailable")
        case .checking: L.t("permission.state.checking")
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

    static func permissions(
        fullDiskAccess: FullDiskAccessCheckResult,
        finderAutomationPermission: FinderAutomationPermission?
    ) -> [PermissionItem] {
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
                detail: automationDetail(for: finderAutomationPermission),
                systemImage: "wand.and.stars",
                state: permissionState(for: finderAutomationPermission)
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

    private static func permissionState(
        for automationPermission: FinderAutomationPermission?
    ) -> PermissionState {
        switch automationPermission {
        case nil:
            .checking
        case .granted:
            .granted
        case .notDetermined:
            .notRequested
        case .denied:
            .denied
        case .targetNotRunning, .unavailable:
            .unavailable
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

    private static func automationDetail(
        for automationPermission: FinderAutomationPermission?
    ) -> String {
        switch automationPermission {
        case nil:
            L.t("permission.automation.detail.checking")
        case .granted:
            L.t("permission.automation.detail.granted")
        case .notDetermined:
            L.t("permission.automation.detail.notRequested")
        case .denied:
            L.t("permission.automation.detail.denied")
        case .targetNotRunning:
            L.t("permission.automation.detail.finderUnavailable")
        case .unavailable:
            L.t("permission.automation.detail.unavailable")
        }
    }

    static func area(for category: CleanupCategory) -> CleanupArea {
        cleanupAreas.first { $0.category == category } ?? cleanupAreas[0]
    }
}
