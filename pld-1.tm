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
#   current → pid tid # from LastItem table
#   pids_for_tid tid # playlists containing track in pos order
#   tids_for_pid pid # tracks in playlist in pos order
#   playlist_for_pid pid → playlist_item
#   playlist_insert name → pid # List → New
#   playlist_rename pid name # List → Rename
#   playlist_insert_tracks → list of tids # List → Add {Folder,Tracks}
#   playlist_merge pid other_pid # List → Merge List
#   playlist_delete pid # List → Delete
#   find_track pattern → list of tid # Track → Find
#   playlist_move_track_up pid tid # Track → Move Up
#   playlist_move_track_down pid tid # Track → Move Down
#   playlist_move_track_to_playlist new_pid old_pid tid # Track → Move to
#   playlist_copy_track_to_playlist new_pid old_pid tid # Track → Copy to
#   playlist_remove_tracks pid list of tids # remove from this playlist
#                                           # Track → Remove from
#   track_delete tid # delete the track and remove from all playlists
#       # Track → Delete
#   track_for_tid tid → track_item
#   track_update_secs tid secs
#   history # list of (pid, cid) pairs order hid DESC
#   history_insert pid tid
#   history_clear
#   history_remove pid tid
#   history_insert pid tid
#   bookmarks # list of (pid, cid) pairs order bid DESC
#   bookmarks_insert pid tid
#   bookmarks_clear
#   bookmarks_remove pid tid
#   bookmarks_insert pid tid

oo::define Pld method to_string {} { return "Pld \"$Filename\"" }
