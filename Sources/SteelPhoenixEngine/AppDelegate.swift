import Cocoa
import MetalKit
import SimpleLogs

let WIDTH  = 800
let HEIGHT = 600

class ViewController : NSViewController
{
    public var metalView: MTKView?

    override func loadView()
    {
        let rect = NSRect(x: 0, y: 0, width: WIDTH, height: HEIGHT)
        view = self.metalView ?? NSView(frame: rect)
    }
}

class MyMetalView: MTKView
{
    typealias MouseEventClosure   = (Float, Float) -> Void
    typealias ScrollEventClosure  = (Float) -> Void

    public var onMouseDrag: MouseEventClosure?
    public var onScroll:    ScrollEventClosure?
    public var onKeyDown:   KeyDownEventclosure?

    override var acceptsFirstResponder: Bool { return true }

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

        self.mDevice = MTLCreateSystemDefaultDevice()
        if mDevice == nil { fatalError("NO GPU") }

        let view = MyMetalView(frame: rect, device: mDevice)
        let viewController = ViewController()
        viewController.metalView = view
        view.becomeFirstResponder()

        mWinDel = WindowDelegate()
        mWindow = NSWindow(contentRect: rect,
                           styleMask:   [.miniaturizable,
                                         .closable,
                                         .resizable,
                                         .titled],
                           backing:     .buffered,
                           defer:       false)

        mWindow?.title                 = "Metal Renderer 🤘🏻"
        mWindow?.contentViewController = viewController
        mWindow?.delegate              = mWinDel

        mWindow?.makeKeyAndOrderFront(self)

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
        // TODO: keyPressCallback()
        func dragClosure(x: Float, y: Float) { mRenderer?.mouseDragCallback(deltaX: x, deltaY: y) }
        func scrollClosure(s: Float) { mRenderer?.scrollCallback(scroll: s) }
        view.onMouseDrag = dragClosure(x:y:)
        view.onScroll    = scrollClosure(s:)
    }


    func applicationWillTerminate(_ aNotification: Notification)
    {
        // Insert code here to tear down your application
    }
}
