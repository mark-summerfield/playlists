# Copyright © 2025 Mark Summerfield. All rights reserved.

package require sqlite3 3

oo::class create Pld {
    variable Filename
    variable Db
    variable MaxHistory
}

oo::define Pld initialize { variable N 0 }

oo::define Pld constructor {filename {max_history 26}} {
    classvariable N
    set Filename $filename
    set MaxHistory $max_history
    set Db Pldb#[incr N]
    set exists [file isfile $Filename]
    sqlite3 $Db $Filename
    $Db eval [readFile $::APPPATH/sql/prepare.sql] 
    $Db transaction {
        if {!$exists} {
            $Db eval [readFile $::APPPATH/sql/create.sql]
            # TODO delete; this is for testing
            $Db transaction {
                $Db eval {INSERT INTO Lists (cid, name)
                    VALUES (2, 'Beatles')}
                $Db eval {INSERT INTO Lists (cid, name)
                    VALUES (2, 'Blondie')}
                set lid2 [$Db last_insert_rowid]
                $Db eval {INSERT INTO Lists (cid, name)
                    VALUES (2, 'ABBA')}
                set lid [$Db last_insert_rowid]
                $Db eval {INSERT INTO Tracks (filename)
                    VALUES ('/home/mark/Music/ABBA/CD2/09-One_of_Us.ogg')}
                set tid9 [$Db last_insert_rowid]
                $Db eval {INSERT INTO Tracks (filename)
                    VALUES ('/home/mark/Music/ABBA/CD2/02-Angeleyes.ogg')}
                set tid2 [$Db last_insert_rowid]
                $Db eval {INSERT INTO List_x_Tracks (lid, tid)
                    VALUES (:lid, :tid9)}
                $Db eval {INSERT INTO List_x_Tracks (lid, tid)
                    VALUES (:lid, :tid2)}
                $Db eval {INSERT INTO LastItem (lid, tid)
                    VALUES (:lid, :tid9)}
                $Db eval {INSERT INTO Tracks (filename)
                    VALUES ('/home/mark/Music/Blondie/01-Atomic.ogg')}
                set tid9 [$Db last_insert_rowid]
                $Db eval {INSERT INTO Tracks (filename)
                    VALUES ('/home/mark/Music/Blondie/06-Denis.ogg')}
                set tid2 [$Db last_insert_rowid]
                $Db eval {INSERT INTO List_x_Tracks (lid, tid)
                    VALUES (:lid2, :tid9)}
                $Db eval {INSERT INTO List_x_Tracks (lid, tid)
                    VALUES (:lid2, :tid2)}
            }
        }
    }
}

oo::define Pld destructor {
    $Db eval {DELETE FROM History WHERE hid NOT IN
              (SELECT hid FROM HISTORY ORDER BY hid DESC LIMIT :MaxHistory)}
    $Db eval {VACUUM}
    $Db close
}

oo::define Pld method filename {} { return $Filename }

oo::define Pld method version {} { $Db eval {PRAGMA USER_VERSION} }

oo::define Pld method category_names {{casefold 0}} {
    set categories [list]
    $Db eval {SELECT name FROM CategoriesView} {
        lappend categories [expr {$casefold ? [string tolower $name] \
                                            : $name}]
    }
    return $categories
}

oo::define Pld method categories {} {
    set categories [list]
    $Db eval {SELECT cid, name FROM CategoriesView} {
        lappend categories [list $cid $name]
    }
    return $categories
}

oo::define Pld method cid_for_name name {
    $Db eval {SELECT cid FROM Categories WHERE name = :name LIMIT 1}
}

oo::define Pld method category_info cid {
    $Db eval {SELECT Categories.name AS name,
              (SELECT COUNT(*) FROM Lists WHERE cid = :cid) AS n
              FROM Categories WHERE cid = :cid LIMIT 1} {
        return [list $name $n]
    }
    list "" 0
}

oo::define Pld method category_name cid {
    $Db eval {SELECT name FROM Categories WHERE cid = :cid LIMIT 1}
}

oo::define Pld method category_list_count cid {
    $Db eval {SELECT COUNT(*) FROM Lists WHERE cid = :cid}
}

oo::define Pld method category_insert name {
    $Db eval {INSERT INTO Categories (name) VALUES (:name)}
    $Db last_insert_rowid
}

oo::define Pld method category_update {cid name} {
    $Db eval {UPDATE Categories SET name = :name WHERE cid = :cid}
}

oo::define Pld method category_delete cid {
    $Db eval {DELETE FROM Categories WHERE cid = :cid}
}

oo::define Pld method category_lists {cid {casefold 0}} {
    set lists [list]
    $Db eval {SELECT lid, name FROM ListsView WHERE cid = :cid} {
        lappend lists [list $lid [expr {$casefold ? [string tolower $name] \
                                                  : $name}]]
    }
    return $lists
}

oo::define Pld method category_list_names {cid {casefold 0}} {
    set names [list]
    $Db eval {SELECT name FROM ListsView WHERE cid = :cid} {
        lappend names [expr {$casefold ? [string tolower $name] : $name}]
    }
    return $names
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

oo::define Pld method lists {} {
    set lists [list]
    $Db eval {SELECT cid, lid, name FROM ListsView} {
        lappend lists [list $cid $lid $name]
    }
    return $lists
}

oo::define Pld method list_name lid {
    $Db eval {SELECT name FROM Lists WHERE lid = :lid LIMIT 1}
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

oo::define Pld method lid_for_cid_and_name {cid name} {
    $Db eval {SELECT lid FROM Lists WHERE name = :name AND cid = :cid
              LIMIT 1}
}

oo::define Pld method list_insert {cid name} {
    $Db eval {INSERT INTO Lists (cid, name) VALUES (:cid, :name)}
    $Db last_insert_rowid
}

oo::define Pld method list_update {cid lid name} {
    $Db eval {UPDATE Lists SET cid = :cid, name = :name WHERE lid = :lid}
}

oo::define Pld method list_update_category {cid lid} {
    $Db eval {UPDATE Lists SET cid = :cid WHERE lid = :lid}
}

oo::define Pld method list_delete lid {
    $Db transaction {
        $Db eval {DELETE FROM Lists WHERE lid = :lid}
        $Db eval {DELETE FROM History WHERE lid = :lid}
        $Db eval {DELETE FROM Bookmarks WHERE lid = :lid}
    }
}

oo::define Pld method last_item {} {
    set item [$Db eval {SELECT lid, tid FROM LastItem LIMIT 1}]
    if {![llength $item]} { set item [list 0 0] }
    return $item
}

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

oo::define Pld method history {} {
    set history [list]
    $Db eval {SELECT lid, tid, filename FROM HistoryView} {
        lappend history [list $lid $tid $filename]
    }
    return $history
}

oo::define Pld method history_insert {lid tid} {
    $Db transaction {
        $Db eval {DELETE FROM History WHERE lid = :lid AND tid = :tid}
        $Db eval {INSERT INTO History (lid, tid) VALUES (:lid, :tid)}
    }
}

oo::define Pld method history_delete {lid {tid 0}} {
    if {$tid} {
        $Db eval {DELETE FROM History WHERE lid = :lid AND tid = :tid}
    } else {
        $Db eval {DELETE FROM History WHERE lid = :lid}
    }
}

oo::define Pld method bookmarks {} {
    set bookmarks [list]
    $Db eval {SELECT lid, tid, filename FROM BookmarksView} {
        lappend bookmarks [list $lid $tid $filename]
    }
    return $bookmarks
}

oo::define Pld method bookmarks_delete {lid {tid 0}} {
    if {$tid} {
        $Db eval {DELETE FROM Bookmarks WHERE lid = :lid AND tid = :tid}
    } else {
        $Db eval {DELETE FROM Bookmarks WHERE lid = :lid}
    }
}

oo::define Pld method to_string {} { return "Pld \"$Filename\"" }
