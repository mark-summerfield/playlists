# Copyright © 2025 Mark Summerfield. All rights reserved.

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
    .menu.list add command -command [callback on_list_export] \
        -label Export… -underline 1 -compound left \
        -image [ui::icon export.svg $::MENU_ICON_SIZE]
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
    .menu.track add command -command [callback on_track_toggle_circled] \
        -label "Toggle Circled" -underline 0 -compound left \
        -image [ui::icon circled.svg $::MENU_ICON_SIZE]
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
    .menu.play add command -command [callback on_play_skip_back] \
        -label "Skip Back" -underline 0 -compound left \
        -accelerator Shift+F2 \
        -image [ui::icon media-seek-backward-symbolic.svg $::MENU_ICON_SIZE]
    .menu.play add command -command [callback on_play_replay] \
        -label Replay -underline 0 -compound left -accelerator F3 \
        -image [ui::icon edit-redo.svg $::MENU_ICON_SIZE]
    .menu.play add command -command [callback on_play_pause_resume] \
        -label Pause/Resume -underline 4 -compound left -accelerator F4 \
        -image [ui::icon media-playback-pause.svg $::MENU_ICON_SIZE]
    .menu.play add command -command [callback on_play] \
        -label Play -underline 0 -compound left -accelerator F5 \
        -image [ui::icon media-playback-start.svg $::MENU_ICON_SIZE]
    .menu.play add command -command [callback on_play_skip_forward] \
        -label "Skip Forward" -underline 0 -compound left \
        -accelerator Shift+F6 \
        -image [ui::icon media-seek-backward-symbolic.svg $::MENU_ICON_SIZE]
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

