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
    my make_file_menu
    my make_category_menu
    my make_list_menu
    my make_track_menu
    my make_play_menu
    menu .menu.history
    .menu add cascade -menu .menu.history -label History -underline 0
    my populate_history_menu
    menu .menu.bookmarks
    .menu add cascade -menu .menu.bookmarks -label Bookmarks -underline 0
    my populate_bookmarks_menu
    . configure -menu .menu
}

oo::define App method make_file_menu {} {
    menu .menu.file
    .menu add cascade -menu .menu.file -label File -underline 0
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
}

oo::define App method make_category_menu {} {
    menu .menu.category
    .menu add cascade -menu .menu.category -label Category -underline 0
    .menu.category add command -command [callback on_category_new] \
        -label New… -underline 0 -compound left \
        -image [ui::icon category-new.svg $::MENU_ICON_SIZE]
    .menu.category add command -command [callback on_category_rename] \
        -label Rename… -underline 0 -compound left \
        -image [ui::icon category-rename.svg $::MENU_ICON_SIZE]
    .menu.category add command -command [callback on_category_expand_all] \
        -label "Expand All" -underline 0 -compound left \
        -image [ui::icon expand.svg $::MENU_ICON_SIZE]
    .menu.category add command \
        -command [callback on_category_collapse_all] \
        -label "Collapse All" -underline 0 -compound left \
        -image [ui::icon collapse.svg $::MENU_ICON_SIZE]
    .menu.category add separator
    .menu.category add command -command [callback on_category_delete] \
        -label Delete… -underline 0 -compound left \
        -image [ui::icon category-delete.svg $::MENU_ICON_SIZE]
}

oo::define App method make_list_menu {} {
    menu .menu.list
    .menu add cascade -menu .menu.list -label List -underline 0
    .menu.list add command -command [callback on_list_new] -label New… \
        -underline 0 -compound left \
        -image [ui::icon list-new.svg $::MENU_ICON_SIZE]
    .menu.list add command -command [callback on_list_edit] \
        -label Edit… -underline 0 -compound left \
        -image [ui::icon list-rename.svg $::MENU_ICON_SIZE]
    .menu.list add separator
    .menu.list add command -command [callback on_list_add_folder] \
        -label "Add Folder’s Tracks…" -underline 4 -compound left \
        -image [ui::icon list-add-folder.svg $::MENU_ICON_SIZE]
    .menu.list add command -command [callback on_list_add_tracks] \
        -label "Add Tracks…" -underline 4 -compound left \
        -image [ui::icon list-add-tracks.svg $::MENU_ICON_SIZE]
    .menu.list add command -command [callback on_list_merge] \
        -label "Merge Other List…" -underline 0 -compound left \
        -image [ui::icon list-merge.svg $::MENU_ICON_SIZE]
    .menu.list add separator
    .menu.list add command -command [callback on_list_delete] \
        -label Delete… -underline 0 -compound left \
        -image [ui::icon list-delete.svg $::MENU_ICON_SIZE]
}

oo::define App method make_track_menu {} {
    menu .menu.track
    .menu add cascade -menu .menu.track -label Track -underline 0
    .menu.track add command -command [callback on_track_rename] \
        -label Rename… -underline 0 -compound left \
        -image [ui::icon track-rename.svg $::MENU_ICON_SIZE]
    .menu.track add command -command [callback on_track_stars 3] \
        -label "3 Excellent" -underline 0 -compound left \
        -foreground $::STARS3 -image [ui::icon star3.svg $::MENU_ICON_SIZE]
    .menu.track add command -command [callback on_track_stars 2] \
        -label "2 Good" -underline 0 -compound left \
        -foreground $::STARS2 -image [ui::icon star2.svg $::MENU_ICON_SIZE]
    .menu.track add command -command [callback on_track_stars 1] \
        -label "1 Okay" -underline 0 -compound left \
        -foreground $::STARS1 -image [ui::icon star1.svg $::MENU_ICON_SIZE]
    .menu.track add command -command [callback on_track_stars 0] \
        -label "0 Poor" -underline 0 -compound left \
        -foreground $::STARS0 -image [ui::icon star0.svg $::MENU_ICON_SIZE]
    .menu.track add separator
    .menu.track add command -command [callback on_track_goto_current] \
        -label "Goto Current" -underline 0 -compound left \
        -accelerator Ctrl+G \
        -image [ui::icon track-find.svg $::MENU_ICON_SIZE]
    .menu.track add command -command [callback on_track_find] \
        -label Find… -underline 0 -accelerator Ctrl+F -compound left \
        -image [ui::icon track-find.svg $::MENU_ICON_SIZE]
    .menu.track add command -command [callback on_track_find_next] \
        -label "Find Next" -underline 5 -accelerator Ctrl+N -compound left \
        -image [ui::icon track-find.svg $::MENU_ICON_SIZE]
    .menu.track add separator
    .menu.track add command -command [callback on_track_copy_to_list] \
        -label "Copy to List…" -underline 0 -compound left \
        -image [ui::icon track-copy-to-list.svg $::MENU_ICON_SIZE]
    .menu.track add command -command [callback on_track_move_to_list] \
        -label "Move to List…" -underline 8 -compound left \
        -image [ui::icon track-move-to-list.svg $::MENU_ICON_SIZE]
    .menu.track add command -command [callback on_track_remove_from_list] \
        -label "Remove from List…" -underline 4 -compound left \
        -image [ui::icon track-remove-from-list.svg $::MENU_ICON_SIZE]
    .menu.track add command -label "Copy Name to Clipboard" \
        -underline 1 -compound left -command [callback on_track_copy_name] \
        -image [ui::icon edit-copy.svg $::MENU_ICON_SIZE]
    .menu.track add separator
    .menu.track add command -command [callback on_track_move_top] \
        -label "Move to Top" -underline 8 -compound left \
        -image [ui::icon go-top.svg $::MENU_ICON_SIZE]
    .menu.track add command -command [callback on_track_move_up] \
        -label "Move Up" -underline 5 -compound left \
        -image [ui::icon go-up.svg $::MENU_ICON_SIZE]
    .menu.track add command -command [callback on_track_move_down] \
        -label "Move Down" -underline 0 -compound left \
        -image [ui::icon go-down.svg $::MENU_ICON_SIZE]
    .menu.track add command -command [callback on_track_move_bottom] \
        -label "Move to Bottom" -underline 8 -compound left \
        -image [ui::icon go-bottom.svg $::MENU_ICON_SIZE]
    .menu.track add separator
    .menu.track add command -command [callback on_track_delete] \
        -label Delete… -underline 0 -compound left \
        -image [ui::icon track-delete.svg $::MENU_ICON_SIZE]
}

oo::define App method make_play_menu {} {
    menu .menu.play
    .menu add cascade -menu .menu.play -label Play -underline 0
    .menu.play add command -command [callback on_play_prev] \
        -label "Play Previous" -underline 8 -compound left -accelerator F2 \
        -image [ui::icon media-skip-backward.svg $::MENU_ICON_SIZE]
    .menu.play add command -command [callback on_play_replay] \
        -label Replay -underline 0 -compound left -accelerator F3 \
        -image [ui::icon edit-redo.svg $::MENU_ICON_SIZE]
    .menu.play add command -command [callback on_play_pause_resume] \
        -label Pause/Resume -underline 4 -compound left -accelerator F4 \
        -image [ui::icon media-playback-pause.svg $::MENU_ICON_SIZE]
    .menu.play add command -command [callback on_play] \
        -label Play -underline 0 -compound left -accelerator F5 \
        -image [ui::icon media-playback-start.svg $::MENU_ICON_SIZE]
    .menu.play add command -command [callback on_play_next] \
        -label "Play Next" -underline 5 -compound left -accelerator F6 \
        -image [ui::icon media-skip-forward.svg $::MENU_ICON_SIZE]
    .menu.play add separator
    .menu.play add command -command [callback on_volume_down] \
        -label "Reduce Volume" -underline 7 -compound left -accelerator F7 \
        -image [ui::icon audio-volume-low.svg $::MENU_ICON_SIZE]
    .menu.play add command -command [callback on_volume_up] \
        -label "Increase Volume" -underline 0 -compound left \
        -accelerator F8 \
        -image [ui::icon audio-volume-high.svg $::MENU_ICON_SIZE]
}

oo::define App method make_widgets {} {
    ttk::frame .mf
    ttk::panedwindow .mf.pw -orient horizontal
    set left [scrollutil::scrollarea .mf.pw.left]
    set ListTree [ttk::treeview .mf.pw.left.tv -selectmode browse \
        -show tree -striped 1]
    $left setwidget $ListTree
    .mf.pw add $left
    set ListTreeContextMenu [menu $ListTree.contextMenu]
    set right [scrollutil::scrollarea .mf.pw.right]
    set TrackTree [ttk::treeview .mf.pw.right.tv -selectmode browse \
        -show tree -style List.Treeview -striped 1]
    $right setwidget $TrackTree
    .mf.pw add $right
    $TrackTree tag configure 3 -foreground $::STARS3 \
        -image [ui::icon star3.svg $::MENU_ICON_SIZE]
    $TrackTree tag configure 2 -foreground $::STARS2 \
        -image [ui::icon star2.svg $::MENU_ICON_SIZE]
    $TrackTree tag configure 1 -foreground $::STARS1 \
        -image [ui::icon star1.svg $::MENU_ICON_SIZE]
    $TrackTree tag configure 0 -foreground $::STARS0 \
        -image [ui::icon star0.svg $::MENU_ICON_SIZE]
    set TrackTreeContextMenu [menu $TrackTree.contextMenu]
    $TrackTreeContextMenu add command -command [callback on_track_rename] \
        -label Rename… -underline 0 -compound left \
        -image [ui::icon track-rename.svg $::MENU_ICON_SIZE]
    $TrackTreeContextMenu add command -command [callback on_track_stars 3] \
        -label "3 Excellent" -underline 0 -compound left \
        -foreground $::STARS3 -image [ui::icon star3.svg $::MENU_ICON_SIZE]
    $TrackTreeContextMenu add command -command [callback on_track_stars 2] \
        -label "2 Good" -underline 0 -compound left \
        -foreground $::STARS2 -image [ui::icon star2.svg $::MENU_ICON_SIZE]
    $TrackTreeContextMenu add command -command [callback on_track_stars 1] \
        -label "1 Okay" -underline 0 -compound left \
        -foreground $::STARS1 -image [ui::icon star1.svg $::MENU_ICON_SIZE]
    $TrackTreeContextMenu add command -command [callback on_track_stars 0] \
        -label "0 Poor" -underline 0 -compound left \
        -foreground $::STARS0 -image [ui::icon star0.svg $::MENU_ICON_SIZE]
    $TrackTreeContextMenu add separator
    $TrackTreeContextMenu add command -label "Copy to List…" -underline 0 \
        -compound left -command [callback on_track_copy_to_list] \
        -image [ui::icon track-copy-to-list.svg $::MENU_ICON_SIZE]
    $TrackTreeContextMenu add command -label "Move to List…" -underline 0 \
        -compound left -command [callback on_track_move_to_list] \
        -image [ui::icon track-move-to-list.svg $::MENU_ICON_SIZE]
    $TrackTreeContextMenu add command -label "Copy Name to Clipboard" \
        -underline 1 -compound left -command [callback on_track_copy_name] \
        -image [ui::icon edit-copy.svg $::MENU_ICON_SIZE]
    my make_playbar
}

oo::define App method make_playbar {} {
    set tip tooltip::tooltip
    ttk::frame .mf.play
    ttk::button .mf.play.prevButton -command [callback on_play_prev] \
        -image [ui::icon media-skip-backward.svg $::MENU_ICON_SIZE] \
        -takefocus 0
    $tip .mf.play.prevButton "Play Previous • F2"
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
    $tip .mf.play.nextButton "Play Next • F6"
    ttk::progressbar .mf.play.progress -anchor center
    ttk::label .mf.play.statusLabel -relief sunken
    ttk::button .mf.play.moveTopButton -takefocus 0 \
        -command [callback on_track_move_top] \
        -image [ui::icon go-top.svg $::MENU_ICON_SIZE]
    $tip .mf.play.moveTopButton "Move Track to the Top"
    ttk::button .mf.play.moveUpButton -takefocus 0 \
        -command [callback on_track_move_up] \
        -image [ui::icon go-up.svg $::MENU_ICON_SIZE]
    $tip .mf.play.moveUpButton "Move Track Up"
    ttk::button .mf.play.moveDownButton -takefocus 0 \
        -command [callback on_track_move_down] \
        -image [ui::icon go-down.svg $::MENU_ICON_SIZE]
    $tip .mf.play.moveDownButton "Move Track Down"
    ttk::button .mf.play.moveBottomButton -takefocus 0 \
        -command [callback on_track_move_bottom] \
        -image [ui::icon go-bottom.svg $::MENU_ICON_SIZE]
    $tip .mf.play.moveBottomButton "Move Track to the Bottom"
    ttk::button .mf.play.volumeDownButton -takefocus 0 \
        -command [callback on_volume_down] \
        -image [ui::icon audio-volume-low.svg $::MENU_ICON_SIZE]
    $tip .mf.play.volumeDownButton "Reduce Volume • F7"
    ttk::button .mf.play.volumeUpButton -command [callback on_volume_up] \
        -image [ui::icon audio-volume-high.svg $::MENU_ICON_SIZE] \
        -takefocus 0
    $tip .mf.play.volumeUpButton "Increase Volume • F8"
}

oo::define App method make_layout {} {
    const opts "-pady 3 -padx 3"
    pack .mf.play -fill x -side bottom {*}$opts
    pack .mf.play.prevButton -side left {*}$opts
    pack .mf.play.replayButton -side left {*}$opts
    pack .mf.play.pauseButton -side left {*}$opts
    pack .mf.play.playButton -side left {*}$opts
    pack .mf.play.nextButton -side left {*}$opts
    pack .mf.play.progress -fill both -expand 1 -side left {*}$opts
    pack .mf.play.statusLabel -fill both -side left {*}$opts
    pack .mf.play.moveTopButton -side left {*}$opts
    pack .mf.play.moveUpButton -side left {*}$opts
    pack .mf.play.moveDownButton -side left {*}$opts
    pack .mf.play.moveBottomButton -side left {*}$opts
    pack .mf.play.volumeDownButton -side left {*}$opts
    pack .mf.play.volumeUpButton -side left {*}$opts
    pack .mf.pw -fill both -expand 1
    pack .mf -fill both -expand 1
}

oo::define App method make_bindings {} {
    bind . <<MplayerPos>> [callback on_pos %d]
    bind . <<MplayerStopped>> [callback on_done]
    bind . <<MplayerDebug>> [callback on_debug %d]
    bind $ListTree <<TreeviewSelect>> [callback on_list_select]
    bind $ListTree <<ContextMenu>> [callback on_list_context_menu %x %y]
    bind $TrackTree <<ContextMenu>> [callback on_track_context_menu %x %y]
    bind $TrackTree <Return> [callback on_play]
    bind $TrackTree <Double-1> [callback on_play]
    bind . <F2> [callback on_play_prev]
    bind . <F3> [callback on_play_replay]
    bind . <F4> [callback on_play_pause_resume]
    bind . <F5> [callback on_play]
    bind . <F6> [callback on_play_next]
    bind . <F7> [callback on_volume_down]
    bind . <F8> [callback on_volume_up]
    bind . <Control-a> [callback on_bookmarks_add]
    bind . <Control-f> [callback on_track_find]
    bind . <Control-g> [callback on_track_goto_current]
    bind . <Control-n> [callback on_track_find_next]
    bind . <Control-o> [callback on_file_open]
    bind . <Control-q> [callback on_quit]
    wm protocol . WM_DELETE_WINDOW [callback on_quit]
}

oo::define App method on_pos data {
    lassign $data pos total
    .mf.play.progress configure -value $pos -maximum $total \
        -text "[humanize_secs $pos]/[humanize_secs $total]"
    if {$GotSecs < 2} {
        incr GotSecs ;# Need to double-check in case of fast track change
        set ttid [$TrackTree selection]
        lassign [split $ttid :] lid tid
        set secs [$Pldb track_secs $tid]
        if {$secs != $total} {
            $Pldb track_update_secs $tid $total
            my populate_tracktree $lid $tid
            after idle [callback populate_history_menu]
        }
    }
}

oo::define App method on_done {} {
    if {[[Config new] auto_play_next]} {
        after 100
        my on_play_next
    }
}

oo::define App method on_debug data { puts "DBG: '$data'" }
