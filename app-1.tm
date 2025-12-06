# Copyright © 2025 Mark Summerfield. All rights reserved.

package require about_form
package require config
package require config_form
package require misc
package require mplayer
package require ref
package require tooltip 2
package require ui

oo::singleton create App {
    variable Player
}

oo::define App constructor {} {
    ui::wishinit
    tk appname PlayTrack
    Config new ;# we need tk scaling done early
    set Player ""
    my make_ui
}

oo::define App method show {} {
    wm deiconify .
    set config [Config new]
    wm geometry . [$config geometry]
    raise .
    update
    after idle [callback on_startup]
}

oo::define App method on_startup {} {
    set config [Config new]
    if {[set filename [$config last_track]] ne ""} {
        my maybe_new_dir $filename
    }
}

oo::define App method make_ui {} {
    my prepare_ui
    set Player [Mplayer new]
    $Player set_debug 0
    puts "make_ui has_mplayer=[$Player has_mplayer] closed=[$Player closed] debug=[$Player debug]"
    my make_menubar
    my make_widgets
    my make_layout
    my make_bindings
}

oo::define App method prepare_ui {} {
    wm title . [tk appname]
    wm iconname . [tk appname]
    wm iconphoto . -default [ui::icon icon.svg]
    wm minsize . 320 180
    ttk::style configure List.Treeview.Item -indicatorsize 0
}

oo::define App method make_menubar {} {
    menu .menu
    menu .menu.file
    .menu add cascade -menu .menu.file -label File -underline 0
    .menu.file add command -command [callback on_file_open] -label Open… \
        -underline 0 -accelerator Ctrl+O -compound left \
        -image [ui::icon document-open.svg $::MENU_ICON_SIZE]
    .menu.file add separator
    .menu.file add command -command [callback on_config] -label Config… \
        -underline 0  -compound left \
        -image [ui::icon preferences-system.svg $::MENU_ICON_SIZE]
    .menu.file add command -command [callback on_about] -label About \
        -underline 0 -compound left \
        -image [ui::icon about.svg $::MENU_ICON_SIZE]
    .menu.file add separator
    .menu.file add command -command [callback on_quit] -label Quit \
        -underline 0 -accelerator Ctrl+Q  -compound left \
        -image [ui::icon quit.svg $::MENU_ICON_SIZE]
    menu .menu.history
    .menu add cascade -menu .menu.history -label History -underline 0
    my populate_history_menu
    menu .menu.bookmarks
    .menu add cascade -menu .menu.bookmarks -label Bookmarks -underline 0
    my populate_bookmarks_menu
    . configure -menu .menu
}

oo::define App method make_widgets {} {
    ttk::frame .mf
    ttk::label .mf.dirLabel -relief sunken
    ttk::treeview .mf.tv -selectmode browse -show tree -style List.Treeview
    my make_playbar
}

# TODO shortcuts F7 etc. (as per Go PlayTrack)
oo::define App method make_playbar {} {
    set tip tooltip::tooltip
    ttk::frame .mf.play
    ttk::button .mf.play.prevButton -command [callback on_play_prev] \
        -image [ui::icon media-skip-backward.svg $::MENU_ICON_SIZE]
    $tip .mf.play.prevButton "Play previous"
    ttk::button .mf.play.replayButton -command [callback on_play_replay] \
        -image [ui::icon edit-redo.svg $::MENU_ICON_SIZE]
    $tip .mf.play.prevButton Replay
    ttk::button .mf.play.playOrPauseButton \
        -command [callback on_play_or_pause] \
        -image [ui::icon media-playback-start.svg $::MENU_ICON_SIZE]
    $tip .mf.play.playOrPauseButton "Play or pause"
    ttk::button .mf.play.nextButton -command [callback on_play_next] \
        -image [ui::icon media-skip-forward.svg $::MENU_ICON_SIZE]
    $tip .mf.play.nextButton "Play next"
    ttk::progressbar .mf.play.progress -anchor center
    ttk::button .mf.play.volumeDownButton \
        -command [callback on_volume_down] \
        -image [ui::icon audio-volume-low.svg $::MENU_ICON_SIZE]
    $tip .mf.play.volumeDownButton "Reduce volume"
    ttk::button .mf.play.volumeUpButton -command [callback on_volume_up] \
        -image [ui::icon audio-volume-high.svg $::MENU_ICON_SIZE]
    $tip .mf.play.volumeUpButton "Increase volume"
}

oo::define App method make_layout {} {
    const opts "-pady 3 -padx 3"
    pack .mf.dirLabel -fill x -side top {*}$opts
    pack .mf.play -fill x -side bottom {*}$opts
    pack .mf.play.prevButton -side left {*}$opts
    pack .mf.play.replayButton -side left {*}$opts
    pack .mf.play.playOrPauseButton -side left {*}$opts
    pack .mf.play.nextButton -side left {*}$opts
    pack .mf.play.progress -fill both -expand 1 -side left {*}$opts
    pack .mf.play.volumeDownButton -side left {*}$opts
    pack .mf.play.volumeUpButton -side left {*}$opts
    pack .mf.tv -fill both -expand true
    pack .mf -fill both -expand true
}

oo::define App method make_bindings {} {
    bind . <<MplayerPos>> [callback on_pos %d]
    bind . <<MplayerDebug>> [callback on_debug %d]
    bind . <F3> [callback on_bookmarks_add]
    bind . <Control-b> [callback on_bookmarks_edit]
    bind . <Control-o> [callback on_file_open]
    bind . <Control-h> [callback on_history_edit]
    bind . <Control-q> [callback on_quit]
    bind . <Escape> [callback on_quit]
    wm protocol . WM_DELETE_WINDOW [callback on_quit]
}

oo::define App method populate_history_menu {} {
    .menu.history delete 0 end
    .menu.history add command -command [callback on_history_remove] \
        -label "Remove Current" -compound left \
        -image [ui::icon list-remove.svg $::MENU_ICON_SIZE]
    .menu.history add command -command [callback on_history_edit] \
        -label Edit… -accelerator Ctrl+H -compound left \
        -image [ui::icon list-edit.svg $::MENU_ICON_SIZE]
    .menu.history add separator
    set MAX [expr {1 + [scan Z %c]}]
    set i [scan A %c]
    set config [Config new]
    foreach filename [$config history] {
        set label [format "%c. %s" $i [humanize_filename $filename]]
        .menu.history add command -label $label -underline 0 \
            -command [callback file_open $filename]
        incr i
        if {$i == $MAX} { break }
    }
}

oo::define App method populate_bookmarks_menu {} {
    .menu.bookmarks delete 0 end
    .menu.bookmarks add command -command [callback on_bookmarks_add] \
        -label "Add Current" -accelerator F3 -compound left \
        -image [ui::icon list-add.svg $::MENU_ICON_SIZE]
    .menu.bookmarks add command -command [callback on_bookmarks_remove] \
        -label "Remove Current" -compound left \
        -image [ui::icon list-remove.svg $::MENU_ICON_SIZE]
    .menu.bookmarks add command -command [callback on_bookmarks_edit] \
        -label Edit… -accelerator Ctrl+B -compound left \
        -image [ui::icon list-edit.svg $::MENU_ICON_SIZE]
    .menu.bookmarks add separator
    set MAX [expr {1 + [scan Z %c]}]
    set i [scan A %c]
    set config [Config new]
    foreach filename [$config bookmarks] {
        set label [format "%c. %s" $i [humanize_filename $filename]]
        .menu.bookmarks add command -label $label -underline 0 \
            -command [callback file_open $filename]
        incr i
        if {$i == $MAX} { break }
    }
}

oo::define App method on_pos data {
    lassign $data pos total
    .mf.play.progress configure -value $pos -maximum $total \
        -text "[humanize_secs $pos]/[humanize_secs $total]"
}

oo::define App method on_debug data {
    puts "on_debug '$data'"
}

oo::define App method on_file_open {} {
    set filename [[Config new] last_track]
    const filetypes {{{Audio Files} {.mp3 .ogg}}}
    set dir [file home]/Music
    set dir [expr {[file exists $dir] ? $dir : "[file home]/music]"}]
    set dir [expr {$filename eq "" ? $dir : [file dirname $filename]}]
    set filename [tk_getOpenFile -parent . -filetypes $filetypes \
                  -initialdir $dir]
    if {$filename ne ""} {
        my file_open $filename
    }
}

oo::define App method on_history_remove {} {
    puts on_history_remove
}

oo::define App method on_history_edit {} {
    puts on_history_edit
}

oo::define App method on_bookmarks_add {} {
    puts on_bookmarks_add
}

oo::define App method on_bookmarks_remove {} {
    puts on_bookmarks_remove
}

oo::define App method on_bookmarks_edit {} {
    puts on_bookmarks_edit
}

oo::define App method on_volume_down {} {
    if {$Player ne ""} { $Player volume_down }
}

oo::define App method on_volume_up {} {
    if {$Player ne ""} { $Player volume_up }
}
oo::define App method on_config {} {
    set config [Config new]
    set ok [Ref new 0]
    set debug [Ref new [$Player debug]]
    set form [ConfigForm new $ok $debug]
    tkwait window [$form form]
    if {[$ok get]} {
        $Player set_debug [$debug get]
    }
}

oo::define App method on_about {} {
    AboutForm new "Play tracks" \
        https://github.com/mark-summerfield/playtrack-tcl
}

oo::define App method on_quit {} {
    $Player close 
    puts "on_quit has_mplayer=[$Player has_mplayer] closed=[$Player closed] debug=[$Player debug]"
    [Config new] save
    exit
}

oo::define App method file_open filename {
    [Config new] set_last_track $filename
    wm title . "[humanize_filename $filename] — [tk appname]"
    my maybe_new_dir $filename
    $Player play $filename
}

oo::define App method maybe_new_dir filename {
    if {[set dir [file dirname [file normalize $filename]]] ne \
            [.mf.dirLabel cget -text]} {
        .mf.dirLabel configure -text $dir
        # TODO
        # - clear treeview
        # - load treeview with music files for this file's folder
        # - select filename in the treeview
        puts "maybe_new_dir $dir $filename"
    }
}
