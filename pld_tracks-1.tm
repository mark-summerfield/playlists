# Copyright © 2025 Mark Summerfield. All rights reserved.

package require lambda 1

oo::define Pld method track_exists {lid tid} {
    $Db eval {SELECT COUNT(*) FROM List_x_Tracks
              WHERE lid = :lid AND tid = :tid}
}

oo::define Pld method tracks_for_lid lid {
    set tracks [list]
    $Db eval {SELECT Tracks.tid, filename, name, artist, secs
              FROM Tracks, List_x_Tracks
              WHERE Tracks.tid IN (SELECT tid FROM List_x_Tracks
                                   WHERE lid = :lid)
                AND Tracks.tid = List_x_Tracks.tid
                AND List_x_Tracks.lid = :lid
              ORDER BY pos} {
        lappend tracks [list $tid $filename $name $artist $secs]
    }
    return $tracks
}

oo::define Pld method track_names tid {
    $Db eval {SELECT filename, name FROM Tracks WHERE tid = :tid LIMIT 1}
}

oo::define Pld method track_for_tid tid {
    set track [$Db eval {SELECT filename, secs FROM Tracks
                         WHERE tid = :tid LIMIT 1}]
    if {![llength $track]} { set track [list "" 0] }
    return $track
}

oo::define Pld method track_secs tid {
    set secs [$Db eval {SELECT secs FROM Tracks WHERE tid = :tid LIMIT 1}]
    if {![llength $secs]} { return 0 }
    lindex $secs 0
}

oo::define Pld method track_update_secs {tid secs} {
    set ListTracks [list]
    $Db eval {UPDATE Tracks SET secs = :secs WHERE tid = :tid}
}

oo::define Pld method track_update_name {tid name} {
    set ListTracks [list]
    $Db eval {UPDATE Tracks SET name = :name WHERE tid = :tid}
}

oo::define Pld method track_move_up {lid tid} {
    set ListTracks [list]
    $Db transaction {
        set pos [$Db eval {SELECT pos FROM List_x_Tracks
                           WHERE lid = :lid AND tid = :tid LIMIT 1}]
        $Db eval {SELECT tid AS prev_tid, MAX(pos) AS prev_pos
                  FROM List_x_Tracks WHERE lid = :lid AND pos < :pos} {
        }
        if {$prev_pos eq ""} { return } ;# already first
        $Db eval {UPDATE List_x_Tracks SET pos = -1
                  WHERE lid = :lid AND tid = :prev_tid}
        $Db eval {UPDATE List_x_Tracks SET pos = :prev_pos
                  WHERE lid = :lid AND tid = :tid}
        $Db eval {UPDATE List_x_Tracks SET pos = :pos
                  WHERE lid = :lid AND tid = :prev_tid}
    }
}

oo::define Pld method track_move_down {lid tid} {
    set ListTracks [list]
    $Db transaction {
        set pos [$Db eval {SELECT pos FROM List_x_Tracks
                           WHERE lid = :lid AND tid = :tid LIMIT 1}]
        $Db eval {SELECT tid AS next_tid, MIN(pos) AS next_pos
                  FROM List_x_Tracks WHERE lid = :lid AND pos > :pos} {
        }
        if {$next_pos eq ""} { return } ;# already last
        $Db eval {UPDATE List_x_Tracks SET pos = -1
                  WHERE lid = :lid AND tid = :next_tid}
        $Db eval {UPDATE List_x_Tracks SET pos = :next_pos
                  WHERE lid = :lid AND tid = :tid}
        $Db eval {UPDATE List_x_Tracks SET pos = :pos
                  WHERE lid = :lid AND tid = :next_tid}
    }
}

oo::define Pld method track_copy {tid lid} {
    set ListTracks [list]
    $Db eval {INSERT OR IGNORE INTO List_x_Tracks (lid, tid)
              VALUES (:lid, :tid)}
}

oo::define Pld method track_move {tid new_lid old_lid} {
    set ListTracks [list]
    $Db transaction {
        $Db eval {INSERT OR IGNORE INTO List_x_Tracks (lid, tid)
                  VALUES (:new_lid, :tid)}
        $Db eval {DELETE FROM List_x_Tracks
                  WHERE lid = :old_lid AND tid = :tid}
    }
}

oo::define Pld method track_remove {tid lid} {
    set ListTracks [list]
    $Db transaction {
        $Db eval {DELETE FROM LastItem WHERE tid = :tid AND lid = :lid}
        $Db eval {DELETE FROM Bookmarks WHERE tid = :tid AND lid = :lid}
        $Db eval {DELETE FROM History WHERE tid = :tid AND lid = :lid}
        $Db eval {DELETE FROM List_x_Tracks WHERE tid = :tid AND lid = :lid}
    }
}

oo::define Pld method track_delete tid {
    set ListTracks [list]
    $Db eval {DELETE FROM Tracks WHERE tid = :tid}
}
