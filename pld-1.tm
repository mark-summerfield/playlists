# Copyright © 2025 Mark Summerfield. All rights reserved.

package require sqlite3 3

oo::class create Pld {
    variable Filename
    variable Db
    variable MaxHistory
}

package require pld_categories
package require pld_lists
package require pld_tracks

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

oo::define Pld method last_item {} {
    set item [$Db eval {SELECT lid, tid FROM LastItem LIMIT 1}]
    if {![llength $item]} { set item [list 0 0] }
    return $item
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
