#
# Another simple gtk3 vte-based terminal
# Based on the post:
# https://vincent.bernat.ch/en/blog/2017-write-own-terminal
#

import gintro/[gtk, glib, gobject, gio, vte, gdkpixbuf, pango]
import os
import strutils
import parsecfg

proc handler() {.noconv.} = quit(0)

proc getSettings(): Config =
    let home = getEnv("HOME")

    let configdir = joinPath(home, ".config", "garlicterm")
    if not existsDir(configdir):
        createDir(configdir)

    let configfile = joinPath(configdir, "garlicterm.ini")

    if not existsFile(configfile):
        var conf = newConfig()
        conf.setSectionKey("Window", "width", "680")
        conf.setSectionKey("Window", "height", "390")
        conf.setSectionKey("Window", "icon", "")

        conf.setSectionKey("Background", "source", "")
        conf.setSectionKey("Background", "preserve_aspect_ratio", "false")
        conf.setSectionKey("Background", "opacity", "1.0")

        conf.setSectionKey("Font", "size", "9")
        conf.setSectionKey("Font", "family", "Source Code Pro")

        conf.writeConfig(configfile)

    return loadConfig(configfile)
    


proc newApp(settings: Config) =

    let win_width: int = parseInt(settings.getSectionValue("Window", "width"))
    let win_height: int = parseInt(settings.getSectionValue("Window", "height"))
    let icon_file = settings.getSectionValue("Window", "icon")
    let background_file = settings.getSectionValue("Background", "source")
    let preserve_aspect_ratio_conf = settings.getSectionValue("Background", "preserve_aspect_ratio")
    let preserve_aspect_ratio: bool = if preserve_aspect_ratio_conf == "true": true else: false
    let font_size: int = parseInt(settings.getSectionValue("Font", "size"))
    let font_family = settings.getSectionValue("Font", "family")
    let opacity: float = parseFloat(settings.getSectionValue("Background", "opacity"))

    let window = newWindow()

    proc app_exit(win: Window) = mainQuit()
    window.connect("destroy", app_exit)

    window.title = "GarlicTerm"
    window.defaultSize = (win_width, win_height)

    if len(icon_file) > 0 and existsFile(icon_file):
        let iconpixbuf: gdkpixbuf.Pixbuf = gdkpixbuf.newPixbufFromFileAtScale(icon_file, 16, 16, true)
        window.setIcon(iconpixbuf)

    let terminal = newTerminal()

    discard terminal.setEncoding("UTF-8")

    let font = terminal.getFont()
    font.setFamily(font_family)
    font.setSize(font_size * pango.SCALE)

    terminal.setOpacity(opacity)

    if not existsEnv("SHELL"):
        echo "Terminal Error: SHELL environment variable doesn\'t exist!"
        quit(QuitFailure)

    let shell = getEnv("SHELL")
    var argv: seq[string]
    var envv: seq[string]

    argv.add(shell)
    
    proc update_title(widget: vte.Terminal, window: Window) =
        window.set_title(widget.get_window_title())

    proc exit_terminal(widget: Terminal, status: int) = quit(0)

    terminal.connect("window-title-changed", update_title, window)
    terminal.connect("child-exited", exit_terminal)

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
        argv,
        envv,
        {SpawnFlag.leaveDescriptorsOpen},
        nil,
        nil,
        pid,
        nil
    ):
        echo "Terminal Error!"
        quit(QuitFailure)

    let scroller = newScrolledWindow()
    scroller.setHexpand(true)
    scroller.setVexpand(true)
    scroller.add(terminal)

    if len(background_file) > 0 and existsFile(background_file):
        let overlay = newOverlay()
        let background = newImage()
        let pixbuf: gdkpixbuf.Pixbuf = gdkpixbuf.newPixbufFromFileAtScale(
            background_file,
            win_width,
            win_height,
            preserve_aspect_ratio)
        background.setFromPixbuf(pixbuf)
        overlay.add(background)
        overlay.addOverlay(scroller)
        window.add(overlay)

    else:
        window.add(scroller)

    # proc resize_window(widget: Window) =
    #     var
    #         width: int
    #         height: int
    #     widget.get_size(width, height)
    #     echo width, ' ', height
    # window.connect("check-resize", resize_window)

    showAll(window)
    
proc main =
    setControlCHook(handler)

    gtk.init()
    newApp(getSettings())
    gtk.main()

main()
