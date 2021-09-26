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
    private var mWindow:   NSWindow?
    private var mWinDel:   WindowDelegate?
    private var mDevice:   MTLDevice?
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

        mWinDel = WindowDelegate()
        mWindow = NSWindow(contentRect: rect,
                           styleMask:   [.miniaturizable,
                                         .closable,
                                         .resizable,
                                         .titled],
                           backing:     .buffered,
                           defer:       false)

        mWindow?.title                 = "Metal Renderer 🤘🏻"
        mWindow?.contentViewController = ViewController()
        mWindow?.delegate              = mWinDel

        mWindow?.makeKeyAndOrderFront(nil)

        self.mDevice = MTLCreateSystemDefaultDevice()
        if mDevice == nil { fatalError("NO GPU") }

        let view = MTKView(frame: rect, device: mDevice)
        mRenderer = Renderer(mtkView: view)
        if mRenderer?.mView != nil
        {
            mWindow?.contentViewController?.view = mRenderer!.mView
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
