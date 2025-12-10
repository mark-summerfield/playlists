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
    $Db eval {VACUUM}
    $Db close
}

oo::define Pld method filename {} { return $Filename }

oo::define Pld method version {} { $Db eval {PRAGMA USER_VERSION} }

oo::define Pld method db {} { return $Db }

#oo::define Pld method dates {} {
#    set dates [$Db eval {SELECT created, updated FROM Dates}]
#    if {![llength $dates]} {
#        set dates [list 0 0]
#    }
#    return $dates
#}
#
#oo::define Pld method item_positions {} {
#    set positions [list]
#    $Db eval {SELECT iid, pos FROM ItemPositionsView} {
#        set position [ItemPosition new $iid $pos]
#        lappend positions $position
#    }
#    return $positions
#}
#
#oo::define Pld method set_item_positions positions {
#    $Db transaction {
#        $Db eval {DELETE FROM ItemPositions}
#        foreach position $positions {
#            set iid [$position iid]
#            set pos [$position pos]
#            $Db eval {INSERT INTO ItemPositions (iid, pos)
#                      VALUES (:iid, :pos)}
#        }
#    }
#}
#
#oo::define Pld method todo {} {
#    set tktz [$Db eval {SELECT tktz FROM Todos WHERE tid = 1 LIMIT 1}]
#    if {![llength $tktz]} { return 0 }
#    lindex $tktz 0
#}
#
#oo::define Pld method update_todo tktz {
#    $Db eval {INSERT OR REPLACE INTO Todos (tid, tktz) VALUES (1, :tktz)}
#}
#
#oo::define Pld method search_items {} {
#    set items [list]
#    $Db eval {SELECT iid, tktz, DATE(day) AS day
#              FROM Items WHERE hidden = FALSE ORDER BY iid DESC} {
#        lappend items [BasicItem new $iid $tktz $day]
#    }
#    return $items
#}
#
#oo::define Pld method clone_item iid {
#    $Db eval {INSERT INTO Items (tktz, day)
#              SELECT tktz, day FROM Items WHERE iid = :iid}
#    $Db last_insert_rowid
#}
#
#oo::define Pld method item_dates iid {
#    $Db eval {SELECT DATE(created) AS created, DATE(updated) AS updated
#              FROM Items WHERE iid = :iid LIMIT 1} {
#        return [list $created $updated]
#    }
#}
#
#oo::define Pld method is_note iid {
#    $Db eval {SELECT IIF(day = 0, TRUE, FALSE) AS is_note FROM items
#              WHERE iid = :iid}
#}
#
#oo::define Pld method note iid {
#    $Db eval {SELECT iid, tktz, DATETIME(created) AS created, hidden,
#                DATETIME(updated) AS updated
#              FROM Items WHERE iid = :iid LIMIT 1} {
#        set note [Item new $iid $tktz "" $hidden $created $updated]
#    }
#    if {![info exists note]} { return }
#    return $note
#}
#
#oo::define Pld method notes {} {
#    set notes [list]
#    $Db eval {SELECT iid, tktz, DATETIME(created) AS created,
#                DATETIME(updated) AS updated FROM NotesView
#              ORDER BY DESC(updated)} {
#        set note [Item new $iid $tktz 0 0 $created $updated]
#        lappend notes $note
#    }
#    return $notes
#}
#
#oo::define Pld method event iid {
#    $Db eval {SELECT iid, tktz, DATE(day) AS day, hidden,
#                DATETIME(created) AS created, DATETIME(updated) AS updated
#                FROM Items WHERE iid = :iid LIMIT 1} {
#        set event [Item new $iid $tktz $day $hidden $created $updated]
#    }
#    if {![info exists event]} { return }
#    return $event
#}
#
#oo::define Pld method events {} {
#    set events [list]
#    $Db eval {SELECT iid, tktz, DATE(day) AS day,
#                DATETIME(created) AS created, DATETIME(updated) AS updated
#              FROM EventsView ORDER BY day} {
#        set event [Item new $iid $tktz $day 0 $created $updated]
#        lappend events $event
#    }
#    return $events
#}
#
#oo::define Pld method events_ongoing {} {
#    set events [list]
#    $Db eval {SELECT iid, tktz, DATE(day) AS day FROM OngoingEventsView
#              ORDER BY day} {
#        lappend events [BasicItem new $iid $tktz $day]
#    }
#    return $events
#}
#
#oo::define Pld method events_today {} {
#    set events [list]
#    $Db eval {SELECT iid, tktz, DATE(day) AS day FROM TodaysEventsView
#              ORDER BY day} {
#        lappend events [BasicItem new $iid $tktz $day]
#    }
#    return $events
#}
#
#oo::define Pld method events_tomorrow {} {
#    set events [list]
#    $Db eval {SELECT iid, tktz, DATE(day) AS day FROM TomorrowsEventsView
#              ORDER BY day} {
#        lappend events [BasicItem new $iid $tktz $day]
#    }
#    return $events
#}
#
#oo::define Pld method events_this_week {} {
#    set events [list]
#    $Db eval {SELECT iid, tktz, DATE(day) AS day FROM WeeksEventsView
#              ORDER BY day} {
#        lappend events [BasicItem new $iid $tktz $day]
#    }
#    return $events
#}
#
#oo::define Pld method events_this_month {} {
#    set events [list]
#    $Db eval {SELECT iid, tktz, DATE(day) AS day FROM MonthsEventsView
#              ORDER BY day} {
#        lappend events [BasicItem new $iid $tktz $day]
#    }
#    return $events
#}
#
#oo::define Pld method events_future {} {
#    set events [list]
#    $Db eval {SELECT iid, tktz, DATE(day) AS day FROM FutureEventsView
#              ORDER BY day} {
#        lappend events [BasicItem new $iid $tktz $day]
#    }
#    return $events
#}
#
#oo::define Pld method hidden {} {
#    set hiddens [list]
#    $Db eval {SELECT iid, tktz, DATE(day) AS day FROM HiddenItemsView} {
#        lappend hiddens [BasicItem new $iid $tktz $day]
#    }
#    return $hiddens
#}
#
#oo::define Pld method add_note tktz {
#    $Db eval {INSERT INTO Items (tktz) VALUES (:tktz)}
#    $Db last_insert_rowid
#}
#
#oo::define Pld method update_note {iid tktz} {
#    $Db eval {UPDATE Items SET tktz = :tktz WHERE iid = :iid}
#}
#
## day is Julianday throughout
#oo::define Pld method add_event {tktz day} {
#    $Db eval {INSERT INTO Items (tktz, day) VALUES (:tktz, :day)}
#    $Db last_insert_rowid
#}
#
#oo::define Pld method update_event {iid tktz day} {
#    $Db eval {UPDATE Items SET tktz = :tktz, day = :day
#              WHERE iid = :iid}
#}
#
#oo::define Pld method convert_to_event {iid day} {
#    $Db eval {UPDATE Items SET day = :day WHERE iid = :iid}
#}
#
#oo::define Pld method convert_to_note iid {
#    $Db eval {UPDATE Items SET day = 0 WHERE iid = :iid}
#}
#
#oo::define Pld method is_item_hidden iid {
#    $Db eval {SELECT hidden FROM Items WHERE iid = :iid}
#}
#
#oo::define Pld method hide_item iid {
#    $Db eval {UPDATE Items SET hidden = TRUE WHERE iid = :iid}
#}
#
#oo::define Pld method unhide_item iid {
#    $Db eval {UPDATE Items SET hidden = FALSE WHERE iid = :iid}
#}
#
#oo::define Pld method delete_item iid {
#    $Db transaction {
#        $Db eval {DELETE FROM ItemPositions WHERE iid = :iid}
#        $Db eval {DELETE FROM Items WHERE iid = :iid}
#    }
#}

oo::define Pld method to_string {} { return "Pld \"$Filename\"" }
