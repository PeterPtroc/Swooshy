import CoreGraphics
import Testing
@testable import Swooshy

struct WindowLayoutEngineTests {
    private let engine = WindowLayoutEngine()
    private let visibleFrame = CGRect(x: 0, y: 0, width: 1440, height: 900)

    @Test
    func leftHalfUsesLeftSideOfVisibleFrame() {
        let frame = engine.targetFrame(
            for: .leftHalf,
            currentWindowFrame: CGRect(x: 100, y: 100, width: 800, height: 600),
            currentVisibleFrame: visibleFrame
        )

        #expect(frame == CGRect(x: 0, y: 0, width: 720, height: 900))
    }

    @Test
    func rightHalfUsesRightSideOfVisibleFrame() {
        let frame = engine.targetFrame(
            for: .rightHalf,
            currentWindowFrame: CGRect(x: 100, y: 100, width: 800, height: 600),
            currentVisibleFrame: visibleFrame
        )

        #expect(frame == CGRect(x: 720, y: 0, width: 720, height: 900))
    }

    @Test
    func maximizeUsesEntireVisibleFrame() {
        let frame = engine.targetFrame(
            for: .maximize,
            currentWindowFrame: CGRect(x: 100, y: 100, width: 800, height: 600),
            currentVisibleFrame: visibleFrame
        )

        #expect(frame == visibleFrame)
    }

    @Test
    func centerUsesEntireVisibleFrame() {
        let frame = engine.targetFrame(
            for: .center,
            currentWindowFrame: CGRect(x: 100, y: 100, width: 800, height: 600),
            currentVisibleFrame: visibleFrame
        )

        #expect(frame == visibleFrame)
    }

    @Test
    func nonLayoutActionsPreserveCurrentFrame() {
        let currentWindowFrame = CGRect(x: 100, y: 100, width: 800, height: 600)

        for action in [
            WindowAction.minimize,
            .closeWindow,
            .quitApplication,
            .cycleSameAppWindowsForward,
            .cycleSameAppWindowsBackward,
        ] {
            let frame = engine.targetFrame(
                for: action,
                currentWindowFrame: currentWindowFrame,
                currentVisibleFrame: visibleFrame
            )

            #expect(frame == currentWindowFrame)
        }
    }

    @Test
    func screenContainingMostPrefersScreenContainingWindowMidpoint() {
        let leftScreen = CGRect(x: 0, y: 0, width: 1728, height: 1117)
        let rightScreen = CGRect(x: 1728, y: 0, width: 1728, height: 1117)
        let rightHalfOnRightScreen = CGRect(x: 2592, y: 0, width: 864, height: 1117)

        let resolvedScreen = engine.screenContainingMost(
            of: rightHalfOnRightScreen,
            in: [leftScreen, rightScreen]
        )

        #expect(resolvedScreen == rightScreen)
    }

    @Test
    func screenContainingMostFallsBackToNearestScreenWhenNoOverlapExists() {
        let leftScreen = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let rightScreen = CGRect(x: 1440, y: 0, width: 1440, height: 900)
        let offScreenWindow = CGRect(x: 3000, y: 200, width: 400, height: 300)

        let resolvedScreen = engine.screenContainingMost(
            of: offScreenWindow,
            in: [leftScreen, rightScreen]
        )

        #expect(resolvedScreen == rightScreen)
    }
}
