# Copyright © 2025 Mark Summerfield. All rights reserved.

package require lambda 1

oo::define Pld method track_exists {lid tid} {
    $Db eval {SELECT COUNT(*) FROM List_x_Tracks
              WHERE lid = :lid AND tid = :tid}
}

oo::define Pld method tracks_for_lid lid {
    set tracks [list]
    $Db eval {SELECT Tracks.tid, filename, secs FROM Tracks, List_x_Tracks
              WHERE Tracks.tid IN (SELECT tid FROM List_x_Tracks
                                   WHERE lid = :lid)
                AND Tracks.tid = List_x_Tracks.tid
                AND List_x_Tracks.lid = :lid
              ORDER BY LOWER(filename)} {
        lappend tracks [list $tid $filename $secs]
    }
    return $tracks
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
    $Db eval {UPDATE Tracks SET secs = :secs WHERE tid = :tid}
}

oo::define Pld method track_delete tid {
    $Db transaction {
        $Db eval {DELETE FROM LastItem WHERE tid = :tid}
        $Db eval {DELETE FROM Bookmarks WHERE tid = :tid}
        $Db eval {DELETE FROM History WHERE tid = :tid}
        $Db eval {DELETE FROM List_x_Tracks WHERE tid = :tid}
        $Db eval {DELETE FROM Tracks WHERE tid = :tid}
    }
}
