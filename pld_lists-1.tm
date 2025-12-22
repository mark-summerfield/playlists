# Copyright © 2025 Mark Summerfield. All rights reserved.

package require db
package require ogg

oo::define Pld method lid_for_cid_and_name {cid name} {
    $Db eval {SELECT lid FROM Lists WHERE name = :name AND cid = :cid
              LIMIT 1}
}

oo::define Pld method lists {} {
    set lists [list]
    $Db eval {SELECT cid, lid, name FROM ListsView} {
        lappend lists [list $cid $lid $name]
    }
    return $lists
}

oo::define Pld method list_name lid {
    db::first [$Db eval {SELECT name FROM Lists WHERE lid = :lid LIMIT 1}]
}

oo::define Pld method list_tracks_info lid {
    $Db eval {SELECT COUNT(*) AS n, SUM(secs) as secs
              FROM List_x_Tracks, Tracks
              WHERE List_x_Tracks.tid = Tracks.tid
              AND List_x_Tracks.lid = :lid} {
        if {!$n} { set secs 0 }
        return [list $n $secs]
    }
    list 0 0
}

oo::define Pld method list_info lid {
    $Db eval {SELECT Lists.name AS name, Categories.cid AS cid,
                     Categories.name AS category,
                     (SELECT COUNT(*) FROM List_x_Tracks
                      WHERE lid = :lid) AS n FROM Lists, Categories
              WHERE lid = :lid AND Lists.cid = Categories.cid LIMIT 1} {
        return [list $name $cid $category $n]
    }
    list "" 0 "" 0
}

oo::define Pld method list_category_data ignore_lid {
    set data [list]
    $Db eval {SELECT Categories.name AS category_name,
                     Lists.name AS list_name, Lists.lid AS lid
              FROM Categories, Lists
              WHERE Categories.cid = Lists.cid AND Lists.lid != :ignore_lid
              ORDER BY LOWER(list_name), LOWER(category_name) } {
        lappend data [list $category_name $list_name $lid]
    }
    return $data
}

oo::define Pld method list_merge_data ignore_lid {
    set data [list]
    $Db eval {SELECT Categories.name AS category_name,
                     Lists.name AS list_name, Lists.lid AS lid
              FROM Categories, Lists
              WHERE Categories.cid = Lists.cid
              AND (SELECT COUNT(*) FROM List_x_Tracks
                   WHERE List_x_Tracks.lid = Lists.lid) > 0
              AND Lists.lid != :ignore_lid
              ORDER BY LOWER(list_name), LOWER(category_name) } {
        lappend data [list $category_name $list_name $lid]
    }
    return $data
}

oo::define Pld method list_merge {to_lid from_lid} {
    set ListTracks [list]
    $Db transaction {
        set tids [list]
        $Db eval {SELECT tid FROM List_x_Tracks
                  WHERE lid = :from_lid
                  AND tid NOT IN (SELECT tid FROM List_x_Tracks
                                  WHERE lid = :to_lid)} {
            lappend tids $tid
        }
        foreach tid $tids {
            $Db eval {INSERT INTO List_x_Tracks (lid, tid)
                      VALUES (:to_lid, :tid)}
        }
    }
}

oo::define Pld method list_insert_tracks {lid tracks} {
    set ListTracks [list]
    $Db transaction {
        foreach track $tracks {
            set secs [ogg::duration_in_secs $track]
            if {[set tid [$Db eval {SELECT tid FROM Tracks
                                    WHERE filename = :track}]] eq ""} {
                $Db eval {INSERT INTO Tracks (filename, secs)
                          VALUES (:track, :secs)}
                set tid [$Db last_insert_rowid]
            }
            $Db eval {INSERT OR IGNORE INTO List_x_Tracks (lid, tid)
                      VALUES (:lid, :tid)}
        }
    }
}

oo::define Pld method list_insert {cid name} {
    set ListTracks [list]
    $Db eval {INSERT INTO Lists (cid, name) VALUES (:cid, :name)}
    $Db last_insert_rowid
}

oo::define Pld method list_update {cid lid name} {
    set ListTracks [list]
    $Db eval {UPDATE Lists SET cid = :cid, name = :name WHERE lid = :lid}
}

oo::define Pld method list_update_category {cid lid} {
    set ListTracks [list]
    $Db eval {UPDATE Lists SET cid = :cid WHERE lid = :lid}
}

oo::define Pld method list_delete lid {
    set ListTracks [list]
    $Db transaction {
        $Db eval {DELETE FROM Bookmarks WHERE lid = :lid}
        $Db eval {DELETE FROM History WHERE lid = :lid}
        $Db eval {DELETE FROM List_x_Tracks WHERE lid = :lid}
        $Db eval {DELETE FROM Lists WHERE lid = :lid}
    }
}

oo::define Pld method list_delete_unlisted_tracks {} {
    set ListTracks [list]
    $Db transaction {
        $Db eval {DELETE FROM LastItem WHERE lid = 0}
        $Db eval {DELETE FROM Bookmarks WHERE lid = 0}
        $Db eval {DELETE FROM History WHERE lid = 0}
        $Db eval {DELETE FROM Tracks WHERE tid IN
                  (SELECT tid FROM List_x_Tracks WHERE lid = 0)}
        $Db eval {DELETE FROM List_x_Tracks WHERE lid = 0}
    }
}
