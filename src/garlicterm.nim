
#
# Another simple gtk3 vte-based terminal
#

import gintro/[gtk, glib, gobject, gio, vte, gdkpixbuf, pango]
import os
import strutils
import parsecfg

let environ = getEnviron()

proc handler() {.noconv.} = quit(0)

proc getSettings(): Config =
    let home = environ.environGetenv("HOME")

    let configdir = joinPath(home, ".config", "garlicterm")
    if not existsDir(configdir):
        createDir(configdir)

    let configfile = joinPath(configdir, "garlicterm.ini")

    if not existsFile(configfile):
        var dict = newConfig()
        dict.setSectionKey("Window", "width", "680")
        dict.setSectionKey("Window", "height", "390")
        dict.setSectionKey("Window", "icon", "")

        dict.setSectionKey("Background", "source", "")
        dict.setSectionKey("Background", "preserve_aspect_ratio", "false")
        dict.setSectionKey("Background", "opacity", "1.0")

        dict.setSectionKey("Font", "size", "9")
        dict.setSectionKey("Font", "family", "Source Code Pro")

        dict.writeConfig(configfile)

    return loadConfig(configfile)


proc newApp(dict: Config) =

    let win_width: int = parseInt(dict.getSectionValue("Window", "width"))
    let win_height: int = parseInt(dict.getSectionValue("Window", "height"))
    let icon_file = dict.getSectionValue("Window", "icon")
    let background_file = dict.getSectionValue("Background", "source")
    let preserve_aspect_ratio_conf = dict.getSectionValue("Background", "preserve_aspect_ratio")
    let preserve_aspect_ratio: bool = if preserve_aspect_ratio_conf == "true": true else: false
    let font_size: int = parseInt(dict.getSectionValue("Font", "size"))
    let font_family = dict.getSectionValue("Font", "family")
    let opacity: float = parseFloat(dict.getSectionValue("Background", "opacity"))

    let window = newWindow()

    proc app_exit(win: Window) = mainQuit()
    window.connect("destroy", app_exit)

    window.title = "GarlicTerm"
    window.defaultSize = (win_width, win_height)

    if len(icon_file) > 0 and existsFile(icon_file):
        let iconpixbuf: gdkpixbuf.Pixbuf = gdkpixbuf.newPixbufFromFileAtScale(icon_file, 16, 16, true)
        window.setIcon(iconpixbuf)

    let terminal = newTerminal()
    
    let shell = environ.environGetenv("SHELL")
    var cmd: array[2, cstring] = [shell.cstring, cast[cstring](0)]

    discard terminal.setEncoding("UTF-8")

    let font = terminal.getFont()
    font.setFamily(font_family)
    font.setSize(font_size * pango.SCALE)

    terminal.setOpacity(opacity)

#[
    proc spawnSync(
        workingDirectory: string = "";
        argv: cstringArray;
        envp: cstringArray;
        flags: SpawnFlags;
        childSetup: SpawnChildSetupFunc;
        userData: pointer;
        standardOutput: var uint8Array;
        standardError: var uint8Array;
        exitStatus: var int
    )
]#

    var pid = 0
    if not terminal.spawnSync(
        cast[PtyFlags](0),
        "",
        cast[cstringArray](unsafeaddr(cmd)),
        nil,
        {SpawnFlag.leaveDescriptorsOpen},
        nil,
        nil,
        pid,
        nil
    ):
        echo "Terminal Error!"
        quit(QuitFailure)
        # mainQuit()

    proc exit_terminal(widget: Terminal, status: int) = mainQuit()

    proc update_title(widget: Terminal, window: Window) =
        window.set_title(widget.get_window_title())

    terminal.connect("window-title-changed", update_title, window)
    terminal.connect("child-exited", exit_terminal)

    let scroller = newScrolledWindow()
    scroller.setHexpand(true)
    scroller.setVexpand(true)
    scroller.add(terminal)
    # var width = scroller.getAllocatedWidth()
    # var height = scroller.getAllocatedHeight()

    if len(background_file) > 0 and existsFile(background_file):
        let overlay = newOverlay()
        let background = newImage()
        let pixbuf: gdkpixbuf.Pixbuf = gdkpixbuf.newPixbufFromFileAtScale(background_file, win_width, win_height, preserve_aspect_ratio)
        background.setFromPixbuf(pixbuf)
        overlay.add(background)

        overlay.addOverlay(scroller)
        window.add(overlay)

    else:
        window.add(scroller)

    # proc resize_window(widget: ApplicationWindow) =
    #     echo "Test Resize"
    # 
    # window.connect("check-resize", resize_window)

    window.showAll

proc main =
    setControlCHook(handler)

    gtk.init()
    newApp(getSettings())
    gtk.main()
  

main()