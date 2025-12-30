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

oo::define Pld method list_first_for_cid cid {
    $Db eval {SELECT lid FROM ListsView WHERE cid = :cid LIMIT 1}
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
    $Db eval {SELECT category_name, list_name, lid
              FROM CategoryListsDataView WHERE lid != :ignore_lid} {
        lappend data [list $category_name $list_name $lid]
    }
    return $data
}

oo::define Pld method list_merge_data ignore_lid {
    set data [list]
    $Db eval {SELECT category_name, list_name, lid
              FROM CategoryListsMergeView WHERE lid != :ignore_lid} {
        lappend data [list $category_name $list_name $lid]
    }
    return $data
}

oo::define Pld method list_merge {to_lid from_lid} {
    set ListTracks [list]
    $Db transaction {
        set tids [list]
        $Db eval {SELECT tid FROM List_x_Tracks WHERE lid = :from_lid
                  ORDER BY pos} {
            lappend tids $tid
        }
        foreach tid $tids {
            $Db eval {INSERT OR IGNORE INTO List_x_Tracks (lid, tid)
                      VALUES (:to_lid, :tid)}
        }
    }
}

oo::define Pld method list_insert_tracks {lid tracks} {
    set ListTracks [list]
    $Db transaction {
        foreach track [lsort -dictionary $tracks] {
            lassign [ogg::metadata $track] secs title artist
            if {[set tid [$Db eval {SELECT tid FROM Tracks
                                    WHERE filename = :track}]] eq ""} {
                $Db eval {INSERT INTO Tracks (filename, secs, name, artist)
                          VALUES (:track, :secs, :title, :artist)}
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
    $Db eval {DELETE FROM Lists WHERE lid = :lid}
}

oo::define Pld method list_delete_unlisted_tracks {} {
    set ListTracks [list]
    $Db transaction {
        $Db eval {DELETE FROM List_x_Tracks WHERE lid = 0}
        $Db eval {DELETE FROM Tracks
                  WHERE tid IN (SELECT tid FROM OrphansView)}
    }
}

oo::define Pld method list_export_m3u8 {lid filename} {
    puts "list_export_m3u8 lid=$lid filename=$filename"
}

oo::define Pld method list_export_pls {lid filename} {
    puts "list_export_pls lid=$lid filename=$filename"
}

oo::define Pld method list_export_tsv {lid filename} {
    puts "list_export_tsv lid=$lid filename=$filename"
}
