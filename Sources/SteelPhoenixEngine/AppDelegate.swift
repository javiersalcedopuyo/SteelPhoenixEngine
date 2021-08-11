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
    private var window:   NSWindow?
    private var device:   MTLDevice?
    private var timer:    Timer?
    private var mRenderer: Renderer?

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

        window?.title = "Metal Renderer 🤘🏻"
        window?.contentViewController = ViewController()
        window?.makeKeyAndOrderFront(nil)

        self.device = MTLCreateSystemDefaultDevice()
        if device == nil { fatalError("NO GPU") }

        let view = MTKView(frame: rect, device: device)
        mRenderer = Renderer(mtkView: view)
        if mRenderer?.mView != nil
        {
            window?.contentViewController?.view = mRenderer!.mView
        }
        else
        {
            fatalError("NO METAL VIEW")
        }
    }

    func applicationWillTerminate(_ aNotification: Notification)
    {
        // Insert code here to tear down your application
    }
}