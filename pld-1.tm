# Copyright © 2025 Mark Summerfield. All rights reserved.

package require sqlite3 3

oo::class create Pld {
    variable Filename
    variable Db
}

oo::define Pld initialize { variable N 0 }

oo::define Pld constructor filename {
    classvariable N
    set Filename $filename
    set Db Pldb#[incr N]
    set exists [file isfile $Filename]
    sqlite3 $Db $Filename
    $Db eval [readFile $::APPPATH/sql/prepare.sql] 
    $Db transaction {
        if {!$exists} { $Db eval [readFile $::APPPATH/sql/create.sql] }
    }
}

oo::define Pld destructor {
    $Db eval {DELETE FROM History WHERE hid NOT IN
              (SELECT hid FROM HISTORY ORDER BY hid DESC LIMIT 100)}
    $Db eval {VACUUM}
    $Db close
}

oo::define Pld method filename {} { return $Filename }

oo::define Pld method version {} { $Db eval {PRAGMA USER_VERSION} }

oo::define Pld method db {} { return $Db }

# API
#   current → cid pid tid # from LastItem table
#   cids # categories in pos order
#   pids_for_cid cid # playlists in category in pos order
#   pids_for_tid tid # playlists containing track in pos order
#   tids_for_pid pid # tracks in playlist in pos order
#   cid_for_pid pid # category for playlist
#   category_delete cid
#   category_for_cid
#   category_insert name → cid
#   category_rename cid name
#   category_move_down cid
#   category_move_playlist_down cid pid
#   category_move_playlist_up cid pid
#   category_move_up cid
#   playlist_change_category pid cid
#   playlist_delete pid
#   playlist_for_pid pid
#   playlist_insert name → pid
#   playlist_rename pid name
#   playlist_insert_tracks → list of tids
#   playlist_move_track_down pid tid
#   playlist_move_track_up pid tid
#   playlist_remove_tracks pid list of tids
#   track_delete tid
#   track_for_tid tid
#   track_update_secs tid secs
#   history # list of (pid, cid) pairs order hid DESC
#   history_insert pid tid
#   history_clear
#   history_delete pid tid
#   history_insert pid tid
#   bookmarks # list of (pid, cid) pairs order bid DESC
#   bookmarks_insert pid tid
#   bookmarks_clear
#   bookmarks_delete pid tid
#   bookmarks_insert pid tid

oo::define Pld method to_string {} { return "Pld \"$Filename\"" }
