# Copyright © 2025 Mark Summerfield. All rights reserved.

package require util

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
            -command [callback play_saved_track $lid $tid $filename 1 1]
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
            -command [callback play_saved_track $lid $tid $filename 1 0]
        incr i
        if {$i == $MAX} { break }
    }
}

oo::define App method populate_listtree {{sel_lid 0}} {
    $ListTree delete [$ListTree children {}]
    foreach cid [$Pldb cids] {
        lassign [$Pldb category_info $cid] name n
        lassign [util::n_s $n] n s
        $ListTree insert {} end -id C$cid -text "$name \[$n list$s\]"
    }
    foreach row [$Pldb lists] {
        lassign $row cid lid name
        lassign [$Pldb list_tracks_info $lid] n secs
        set secs [expr {$secs ? " · [humanize_secs $secs]" : ""}]
        lassign [util::n_s $n] n s
        if {!$sel_lid} { set sel_lid $lid }
        $ListTree insert C$cid end -id L$lid \
            -text "$name \[$n track$s$secs\]"
    }
    if {$ListTreeExpanded} { my on_category_expand_all }
    select_tree_item $ListTree L$sel_lid
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
        my resize_tracktree
        select_tree_item $TrackTree $lid:$sel_tid
        focus $TrackTree
    } else {
        focus $ListTree
    }
}

oo::define App method resize_tracktree {} {
    set width0 [font measure TkDefaultFont 999.]
    set width2 [font measure TkDefaultFont 1h59m59sW]
    set width1 [expr {[winfo width $TrackTree] - ($width0 + $width2)}]
    $TrackTree column #0 -width $width0 -stretch 0 -anchor e
    $TrackTree column 0 -width $width1 -stretch 1 -anchor w
    $TrackTree column 1 -width $width2 -stretch 0 -anchor e
}
