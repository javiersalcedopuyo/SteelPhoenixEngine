import Foundation
import AppKit

class WindowDelegate : NSObject, NSWindowDelegate
{
    // TODO: Make the renderer a member?

    func windowWillClose(_ notification: Notification)
    {
        NSLog("CLOSING APP!")
        // TODO: Clean-up ?
        exit(0)
    }

    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize
    {
        // TODO: Update renderer ?
        return frameSize
    }

    func windowDidMiniaturize(_ notification: Notification)
    {
        // TODO: Stop renderer ?
    }

    func windowDidDeminiaturize(_ notification: Notification)
    {
        // TODO: Restart renderer ?
    }
}
