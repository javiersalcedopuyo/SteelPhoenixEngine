import Cocoa
import MetalKit
import SimpleLogs

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

class MyWindow: NSWindow
{
    typealias MouseEventClosure  = (Float, Float) -> Void
    typealias ScrollEventClosure = (Float) -> Void

    public var onMouseDrag: MouseEventClosure?
    public var onScroll:    ScrollEventClosure?

    override func mouseDragged(with event: NSEvent)
    {
        let deltaX = Float( event.deltaX )
        let deltaY = Float( event.deltaY )

        self.onMouseDrag?(deltaX, deltaY)
    }

    override func scrollWheel(with event: NSEvent)
    {
        let scrollY = Float( event.deltaY )
        self.onScroll?(scrollY)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate
{
    private var mWindow:   MyWindow?
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
        mWindow = MyWindow(contentRect: rect,
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

        // TODO: Extract setInputCallbacks()
        func dragClosure(x: Float, y: Float) { mRenderer?.mouseDragCallback(deltaX: x, deltaY: y) }
        func scrollClosure(s: Float) { mRenderer?.scrollCallback(scroll: s) }
        mWindow?.onMouseDrag = dragClosure(x:y:)
        mWindow?.onScroll    = scrollClosure(s:)
    }


    func applicationWillTerminate(_ aNotification: Notification)
    {
        // Insert code here to tear down your application
    }
}
