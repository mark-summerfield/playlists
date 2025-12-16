# Copyright © 2025 Mark Summerfield. All rights reserved.

oo::define App method populate_history_menu {} {
    .menu.history delete 0 end
    .menu.history add command -command [callback on_history_remove] \
        -label "Remove Current" -compound left \
        -image [ui::icon history-remove.svg $::MENU_ICON_SIZE]
    .menu.history add separator
    set MAX [expr {1 + [scan Z %c]}]
    set i [scan A %c]
    foreach tuple [$Pldb history] {
        lassign $tuple lid tid filename
        set label [format "%c. %s" $i [humanize_trackname $filename]]
        .menu.history add command -label $label -underline 0 \
            -command [callback play_db_track $lid $tid $filename 1]
        incr i
        if {$i == $MAX} { break }
    }
}

oo::define App method populate_bookmarks_menu {} {
    .menu.bookmarks delete 0 end
    .menu.bookmarks add command -command [callback on_bookmarks_add] \
        -label "Add Current" -accelerator Ctrl+A -compound left \
        -image [ui::icon bookmark-add.svg $::MENU_ICON_SIZE]
    .menu.bookmarks add command -command [callback on_bookmarks_remove] \
        -label "Remove Current" -compound left \
        -image [ui::icon bookmark-remove.svg $::MENU_ICON_SIZE]
    .menu.bookmarks add separator
    set MAX [expr {1 + [scan Z %c]}]
    set i [scan A %c]
    foreach tuple [$Pldb bookmarks] {
        lassign $tuple lid tid filename
        set label [format "%c. %s" $i [humanize_trackname $filename]]
        .menu.bookmarks add command -label $label -underline 0 \
            -command [callback play_db_track $lid $tid $filename 1]
        incr i
        if {$i == $MAX} { break }
    }
}

oo::define App method populate_listtree {{sel_lid 0}} {
    $ListTree delete [$ListTree children {}]
    foreach row [$Pldb categories] {
        lassign $row cid name
        $ListTree insert {} end -id C$cid -text $name
    }
    foreach row [$Pldb lists] {
        lassign $row cid lid name
        if {!$sel_lid} { set sel_lid $lid }
        $ListTree insert C$cid end -id L$lid -text $name
    }
    if {$sel_lid} { select_tree_item $ListTree L$sel_lid }
}

oo::define App method populate_tracktree {lid {sel_tid 0}} {
    $TrackTree delete [$TrackTree children {}]
    set n 0
    foreach row [$Pldb tracks_for_lid $lid] {
        lassign $row tid filename secs
        set secs [expr {$secs ? [humanize_secs $secs] : ""}]
        $TrackTree insert {} end -id $lid:$tid -text [incr n]. \
            -values [list [humanize_trackname $filename] $secs]
        if {!$sel_tid} { set sel_tid $tid }
    }
    if {$n} {
        select_tree_item $TrackTree $lid:$sel_tid
        focus $TrackTree
    } else {
        focus $ListTree
    }
}
