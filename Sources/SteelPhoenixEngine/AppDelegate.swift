import Cocoa
import MetalKit

let WIDTH  = 800
let HEIGHT = 600

class ViewController : NSViewController
{
    override func loadView()
    {
        let rect = NSRect(x: 0, y: 0, width: WIDTH, height: HEIGHT)
        view = NSView(frame: rect)
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.red.cgColor
    }
}

class AppDelegate: NSObject, NSApplicationDelegate
{
    private var window: NSWindow?
    private var renderer: Renderer?

    // Initialize the app
    func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        let windowSize = NSSize(width: WIDTH, height: HEIGHT)
        let screenSize = NSScreen.main?.frame.size ?? .zero

        let rect = NSMakeRect(screenSize.width/2  - windowSize.width/2,
                              screenSize.height/2 - windowSize.height/2,
                              windowSize.width,
                              windowSize.height)

        window = NSWindow(contentRect: rect,
                          styleMask:   [.miniaturizable,
                                        .closable,
                                        .resizable,
                                        .titled],
                          backing:     .buffered,
                          defer:       false)

        window?.title = "Hello Triangle!"
        window?.contentViewController = ViewController()
        window?.makeKeyAndOrderFront(nil)

        self.renderer = Renderer(w: WIDTH, h: HEIGHT)
        if renderer?.view != nil
        {
            window?.contentViewController?.view = renderer!.view
        }
        else
        {
            fatalError("NO METAL VIEW")
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        print("App cerrada!")
    }
}