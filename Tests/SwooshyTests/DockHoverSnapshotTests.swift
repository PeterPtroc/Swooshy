import CoreGraphics
import Testing
@testable import Swooshy

struct DockHoverSnapshotTests {
    private func target(
        dockItemName: String,
        processIdentifier: pid_t
    ) -> DockApplicationTarget {
        DockApplicationTarget(
            dockItemName: dockItemName,
            resolvedApplicationName: dockItemName,
            processIdentifier: processIdentifier,
            bundleIdentifier: "com.example.\(dockItemName.lowercased())",
            aliases: [dockItemName]
        )
    }

    @Test
    func hoveredCandidateReturnsMatchingDockItem() {
        let finder = DockHoverCandidate(
            target: target(dockItemName: "Finder", processIdentifier: 100),
            frame: CGRect(x: 0, y: 0, width: 32, height: 32)
        )
        let safari = DockHoverCandidate(
            target: target(dockItemName: "Safari", processIdentifier: 101),
            frame: CGRect(x: 40, y: 0, width: 32, height: 32)
        )
        let snapshot = DockHoverSnapshot(candidates: [finder, safari])

        #expect(snapshot.hoveredCandidate(at: CGPoint(x: 16, y: 16)) == finder)
        #expect(snapshot.hoveredCandidate(at: CGPoint(x: 56, y: 16)) == safari)
    }

    @Test
    func approximateDockRegionUsesCandidateBounds() {
        let snapshot = DockHoverSnapshot(
            candidates: [
                DockHoverCandidate(
                    target: target(dockItemName: "Finder", processIdentifier: 100),
                    frame: CGRect(x: 0, y: 0, width: 32, height: 32)
                ),
                DockHoverCandidate(
                    target: target(dockItemName: "Safari", processIdentifier: 101),
                    frame: CGRect(x: 48, y: 0, width: 32, height: 32)
                ),
            ]
        )

        #expect(snapshot.containsApproximateDockRegion(CGPoint(x: 12, y: 12)))
        #expect(snapshot.containsApproximateDockRegion(CGPoint(x: 60, y: 12)))
        #expect(snapshot.containsApproximateDockRegion(CGPoint(x: 40, y: 12)))
        #expect(snapshot.containsApproximateDockRegion(CGPoint(x: 120, y: 12)) == false)
    }

    @Test
    func emptySnapshotDoesNotReportDockRegionOrHits() {
        let snapshot = DockHoverSnapshot(candidates: [])

        #expect(snapshot.containsApproximateDockRegion(CGPoint(x: 1, y: 1)) == false)
        #expect(snapshot.hoveredCandidate(at: CGPoint(x: 1, y: 1)) == nil)
    }
}
