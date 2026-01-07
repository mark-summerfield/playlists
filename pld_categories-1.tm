# Copyright © 2025 Mark Summerfield. All rights reserved.

package require db

oo::define Pld method cids {} {
    set cids [list]
    $Db eval {SELECT cid FROM CategoriesView} { lappend cids $cid }
    return $cids
}

oo::define Pld method cid_for_lid lid {
    $Db eval {SELECT cid FROM Lists WHERE lid = :lid LIMIT 1}
}

oo::define Pld method cid_for_name name {
    $Db eval {SELECT cid FROM Categories WHERE name = :name LIMIT 1}
}

oo::define Pld method category_name cid {
    $Db onecolumn {SELECT name FROM Categories WHERE cid = :cid LIMIT 1}
}

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

oo::define Pld method category_info cid {
    $Db eval {SELECT Categories.name AS name,
              (SELECT COUNT(*) FROM Lists WHERE cid = :cid) AS n
              FROM Categories WHERE cid = :cid LIMIT 1} {
        return [list $name $n]
    }
    list "" 0
}

oo::define Pld method category_secs cid {
    $Db eval {SELECT COALESCE(SUM(secs), 0) AS secs FROM Tracks WHERE tid IN
              (SELECT tid FROM List_x_Tracks WHERE lid IN
               (SELECT lid FROM Lists WHERE cid = :cid))}
}

oo::define Pld method category_list_count cid {
    $Db eval {SELECT COUNT(*) FROM Lists WHERE cid = :cid}
}

oo::define Pld method category_insert name {
    set ListTracks [list]
    $Db eval {INSERT INTO Categories (name) VALUES (:name)}
    $Db last_insert_rowid
}

oo::define Pld method category_update {cid name} {
    set ListTracks [list]
    $Db eval {UPDATE Categories SET name = :name WHERE cid = :cid}
}

oo::define Pld method category_delete cid {
    set ListTracks [list]
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
