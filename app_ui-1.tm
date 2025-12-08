# Copyright © 2025 Mark Summerfield. All rights reserved.

package require mplayer
package require scrollutil_tile 2
package require tooltip 2

oo::define App method make_ui {} {
    my prepare_ui
    set Player [Mplayer new]
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
    set sa [scrollutil::scrollarea .mf.sa]
    set TrackView [ttk::treeview .mf.sa.tv -selectmode browse -show tree \
                   -style List.Treeview -striped 1]
    $sa setwidget $TrackView
    my make_playbar
}

oo::define App method make_playbar {} {
    set tip tooltip::tooltip
    ttk::frame .mf.play
    ttk::button .mf.play.prevButton -command [callback on_play_prev] \
        -image [ui::icon media-skip-backward.svg $::MENU_ICON_SIZE] \
        -takefocus 0
    $tip .mf.play.prevButton "Play previous • F2"
    ttk::button .mf.play.replayButton -command [callback on_play_replay] \
        -image [ui::icon edit-redo.svg $::MENU_ICON_SIZE] -takefocus 0
    $tip .mf.play.replayButton "Replay • F3"
    ttk::button .mf.play.pauseButton -takefocus 0 \
        -command [callback on_play_pause_resume] \
        -image [ui::icon media-playback-pause.svg $::MENU_ICON_SIZE]
    $tip .mf.play.pauseButton "Pause/Resume • F4"
    ttk::button .mf.play.playButton -takefocus 0 \
        -command [callback on_play] \
        -image [ui::icon media-playback-start.svg $::MENU_ICON_SIZE]
    $tip .mf.play.playButton "Play • F5"
    ttk::button .mf.play.nextButton -command [callback on_play_next] \
        -image [ui::icon media-skip-forward.svg $::MENU_ICON_SIZE] \
        -takefocus 0
    $tip .mf.play.nextButton "Play next • F6"
    ttk::progressbar .mf.play.progress -anchor center
    ttk::button .mf.play.volumeDownButton -takefocus 0 \
        -command [callback on_volume_down] \
        -image [ui::icon audio-volume-low.svg $::MENU_ICON_SIZE]
    $tip .mf.play.volumeDownButton "Reduce volume • F7"
    ttk::button .mf.play.volumeUpButton -command [callback on_volume_up] \
        -image [ui::icon audio-volume-high.svg $::MENU_ICON_SIZE] \
        -takefocus 0
    $tip .mf.play.volumeUpButton "Increase volume • F8"
}

oo::define App method make_layout {} {
    const opts "-pady 3 -padx 3"
    pack .mf.dirLabel -fill x -side top {*}$opts
    pack .mf.play -fill x -side bottom {*}$opts
    pack .mf.play.prevButton -side left {*}$opts
    pack .mf.play.replayButton -side left {*}$opts
    pack .mf.play.pauseButton -side left {*}$opts
    pack .mf.play.playButton -side left {*}$opts
    pack .mf.play.nextButton -side left {*}$opts
    pack .mf.play.progress -fill both -expand 1 -side left {*}$opts
    pack .mf.play.volumeDownButton -side left {*}$opts
    pack .mf.play.volumeUpButton -side left {*}$opts
    pack .mf.sa -fill both -expand true
    pack .mf -fill both -expand true
}

oo::define App method make_bindings {} {
    bind . <<MplayerPos>> [callback on_pos %d]
    bind . <<MplayerDebug>> [callback on_debug %d]
    bind $TrackView <Return> [callback on_play]
    bind $TrackView <Double-1> [callback on_play]
    bind . <F2> [callback on_play_prev]
    bind . <F3> [callback on_play_replay]
    bind . <F4> [callback on_play_pause_resume]
    bind . <F5> [callback on_play]
    bind . <F6> [callback on_play_next]
    bind . <F7> [callback on_volume_down]
    bind . <F8> [callback on_volume_up]
    bind . <Control-a> [callback on_bookmarks_add]
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
            -command [callback play_track $filename]
        incr i
        if {$i == $MAX} { break }
    }
}

oo::define App method populate_bookmarks_menu {} {
    .menu.bookmarks delete 0 end
    .menu.bookmarks add command -command [callback on_bookmarks_add] \
        -label "Add Current" -accelerator Ctrl+A -compound left \
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
            -command [callback play_track $filename]
        incr i
        if {$i == $MAX} { break }
    }
}

oo::define App method on_pos data {
    lassign $data pos total
    .mf.play.progress configure -value $pos -maximum $total \
        -text "[humanize_secs $pos]/[humanize_secs $total]"
}

oo::define App method on_debug data { puts "DBG: '$data'" }
