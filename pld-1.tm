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
        if {!$exists} {
            $Db eval [readFile $::APPPATH/sql/create.sql]
            # TODO delete; this is for testing
            $Db transaction {
                $Db eval {INSERT INTO Lists (name) VALUES ('Pop/Beatles')}
                $Db eval {INSERT INTO Lists (name) VALUES ('Pop/ABBA')}
                set lid [$Db last_insert_rowid]
                $Db eval {INSERT INTO Tracks (filename)
                    VALUES ('/home/mark/Music/ABBA/CD2/09-One_of_Us.ogg')}
                set tid9 [$Db last_insert_rowid]
                $Db eval {INSERT INTO Tracks (filename)
                    VALUES ('/home/mark/Music/ABBA/CD2/02-Angeleyes.ogg')}
                set tid2 [$Db last_insert_rowid]
                $Db eval {INSERT INTO ListTracks (lid, tid, pos)
                    VALUES (:lid, :tid9, 9)}
                $Db eval {INSERT INTO ListTracks (lid, tid, pos)
                    VALUES (:lid, :tid2, 2)}
            }
        }
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

oo::define Pld method lists {} {
    set lists [list]
    $Db eval {SELECT lid, name FROM ListsView} {
        lappend lists [list $lid $name]
    }
    return $lists
}

oo::define Pld method last_item {} {
    set item [$Db eval {SELECT lid, tid FROM LastItem LIMIT 1}]
    if {![llength $item]} {
        set item [list 0 0]
    }
    return $item
}

oo::define Pld method tids_for_lid lid {
    set tracks [list]
    $Db eval {SELECT DISTINCT Tracks.tid, filename, secs
              FROM Tracks, ListTracks
              WHERE
                Tracks.tid IN (SELECT tid FROM ListTracks WHERE lid = :lid)
                AND Tracks.tid = ListTracks.tid
              ORDER BY pos} {
        lappend tracks [list $tid $filename $secs]
    }
    return $tracks
}

# API
#   current → lid tid # from LastItem table
#   pids_for_tid tid # playlists containing track in pos order
#   playlist_for_lid lid → playlist_item
#   playlist_insert name → lid # List → New
#   playlist_rename lid name # List → Rename
#   playlist_insert_tracks → list of tids # List → Add {Folder,Tracks}
#   playlist_merge lid other_lid # List → Merge List
#   playlist_delete lid # List → Delete
#   find_track pattern → list of tid # Track → Find
#   playlist_move_track_up lid tid # Track → Move Up
#   playlist_move_track_down lid tid # Track → Move Down
#   playlist_move_track_to_playlist new_lid old_lid tid # Track → Move to
#   playlist_copy_track_to_playlist new_lid old_lid tid # Track → Copy to
#   playlist_remove_tracks lid list of tids # remove from this playlist
#                                           # Track → Remove from
#   track_delete tid # delete the track and remove from all playlists
#       # Track → Delete
#   track_for_tid tid → track_item
#   track_update_secs tid secs
#   history # list of (lid, cid) pairs order hid DESC
#   history_insert lid tid
#   history_clear
#   history_remove lid tid
#   history_insert lid tid
#   bookmarks # list of (lid, cid) pairs order bid DESC
#   bookmarks_insert lid tid
#   bookmarks_clear
#   bookmarks_remove lid tid
#   bookmarks_insert lid tid

oo::define Pld method to_string {} { return "Pld \"$Filename\"" }
