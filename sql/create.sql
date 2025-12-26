-- Copyright © 2025 Mark Summerfield. All Rights Reserved.

PRAGMA USER_VERSION = 5;

CREATE TABLE Categories (
    cid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    name TEXT UNIQUE NOT NULL
);

CREATE TABLE Lists (
    cid INTEGER DEFAULT 0 NOT NULL,
    lid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    name TEXT NOT NULL,

    FOREIGN KEY(cid) REFERENCES Categories(cid)
);

CREATE TABLE Tracks (
    tid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    filename TEXT NOT NULL,
    secs INTEGER DEFAULT 0 NOT NULL,
    name TEXT,
    artist TEXT,
    stars INTEGER DEFAULT 1 NOT NULL,

    CHECK(secs >= 0),
    CHECK(stars IN (0, 1, 2, 3)) -- poor okay good excellent
);

CREATE TABLE List_x_Tracks (
    lid INTEGER NOT NULL, -- lid → cid
    tid INTEGER NOT NULL,
    pos INTEGER UNIQUE DEFAULT 0 NOT NULL,

    PRIMARY KEY (lid, tid),
    FOREIGN KEY(lid) REFERENCES Lists(lid),
    FOREIGN KEY(tid) REFERENCES Tracks(tid)
);

-- Only ever has zero or one record: auto updated when history inserted.
CREATE TABLE LastItem (
    lid INTEGER NOT NULL, -- lid → cid
    tid INTEGER NOT NULL,

    PRIMARY KEY(lid, tid),
    FOREIGN KEY(lid) REFERENCES Lists(lid),
    FOREIGN KEY(tid) REFERENCES Tracks(tid)
);

CREATE TABLE Bookmarks (
    bid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    lid INTEGER NOT NULL, -- lid → cid
    tid INTEGER NOT NULL,

    UNIQUE(lid, tid),
    FOREIGN KEY(lid) REFERENCES Lists(lid),
    FOREIGN KEY(tid) REFERENCES Tracks(tid)
);

CREATE TABLE History (
    hid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    lid INTEGER NOT NULL, -- lid → cid
    tid INTEGER NOT NULL,

    UNIQUE(lid, tid),
    FOREIGN KEY(lid) REFERENCES Lists(lid),
    FOREIGN KEY(tid) REFERENCES Tracks(tid)
);

CREATE VIEW CategoriesTrimView AS
    SELECT cid, name,
        CASE 
            WHEN name LIKE 'The %' THEN SUBSTR(name, LENGTH('The ') + 1)
            ELSE name
        END AS tname FROM Categories;

CREATE VIEW ListsTrimView AS
    SELECT cid, lid, name,
        CASE 
            WHEN name LIKE 'The %' THEN SUBSTR(name, LENGTH('The ') + 1)
            ELSE name
        END AS tname FROM Lists;

CREATE VIEW CategoriesView AS
    SELECT cid, name FROM CategoriesTrimView ORDER BY LOWER(tname);

CREATE VIEW CategoryListsDataView AS
    SELECT cname AS category_name, lname AS list_name, lid FROM
        (SELECT cid, name AS cname, tname AS tcname
            FROM CategoriesTrimView),
        (SELECT cid AS lcid, lid, name AS lname, tname AS tlname
            FROM ListsTrimView)
        WHERE cid = lcid ORDER BY LOWER(tcname), LOWER(tlname);

CREATE VIEW CategoryListsMergeView AS
    SELECT cname AS category_name, lname AS list_name, lid FROM
        (SELECT cid, name AS cname, tname AS tcname
            FROM CategoriesTrimView),
        (SELECT cid AS lcid, lid, name AS lname, tname AS tlname
            FROM ListsTrimView)
        WHERE cid = lcid
            AND (SELECT COUNT(*) FROM List_x_Tracks
                 WHERE List_x_Tracks.lid = lid) > 0
        ORDER BY LOWER(tcname), LOWER(tlname);

CREATE VIEW ListsView AS
    SELECT lcid AS cid, lid, lname AS name FROM
        (SELECT cid, name AS cname, tname AS tcname
            FROM CategoriesTrimView),
        (SELECT cid AS lcid, lid, name AS lname, tname AS tlname
            FROM ListsTrimView)
        WHERE cid = lcid ORDER BY LOWER(tcname), LOWER(tlname);

CREATE VIEW BookmarksView AS
    SELECT lid, Tracks.tid, filename, name FROM Bookmarks, Tracks
        WHERE Tracks.tid = Bookmarks.tid ORDER BY bid DESC;

CREATE VIEW HistoryView AS
    SELECT lid, Tracks.tid, filename, name FROM History, Tracks
        WHERE Tracks.tid = History.tid ORDER BY hid DESC;

CREATE VIEW ListTracksView AS
    SELECT ListsTrimView.lid, Tracks.tid, Tracks.filename, Tracks.name
        FROM ListsTrimView, Tracks, List_x_Tracks, CategoriesTrimView
        WHERE ListsTrimView.lid = List_x_Tracks.lid
            AND Tracks.tid = List_x_Tracks.tid
            AND ListsTrimView.cid = CategoriesTrimView.cid
        ORDER BY LOWER(CategoriesTrimView.tname),
                 LOWER(ListsTrimView.tname), List_x_Tracks.pos;

-- Should always be empty.
CREATE VIEW OrphansView AS
    SELECT tid FROM Tracks WHERE tid NOT IN (SELECT tid FROM List_x_Tracks);

CREATE TRIGGER DeleteCategoryTrigger1 BEFORE DELETE ON Categories
    FOR EACH ROW WHEN OLD.cid = 0
    BEGIN
        SELECT RAISE(ABORT, 'cannot delete the Uncategorized category');
    END;

-- If a Category is deleted (excl. Uncategorized), move all its lists to the
-- Uncategorized category.
CREATE TRIGGER DeleteCategoryTrigger2 BEFORE DELETE ON Categories
    FOR EACH ROW
        WHEN OLD.cid != 0
    BEGIN
        UPDATE Lists SET cid = 0 WHERE cid = OLD.cid;
    END;

CREATE TRIGGER DeleteListTrigger1 BEFORE DELETE ON Lists
    FOR EACH ROW WHEN OLD.lid = 0
    BEGIN
        SELECT RAISE(ABORT, 'cannot delete the Unlisted list');
    END;

CREATE TRIGGER DeleteListTrigger2 BEFORE DELETE ON Lists
    FOR EACH ROW
        WHEN OLD.lid != 0
    BEGIN
        DELETE FROM List_x_Tracks WHERE lid = OLD.lid;
        DELETE FROM LastItem WHERE lid = OLD.lid;
        DELETE FROM Bookmarks WHERE lid = OLD.lid;
        DELETE FROM History WHERE lid = OLD.lid;
        DELETE FROM Tracks WHERE tid IN (SELECT tid FROM OrphansView);
    END;

CREATE TRIGGER InsertListTracksTrigger AFTER INSERT ON List_x_Tracks
    FOR EACH ROW WHEN NEW.pos = 0
    BEGIN
        UPDATE List_x_Tracks
            SET pos = (SELECT COALESCE(MAX(pos), 0) + 1 FROM List_x_Tracks)
            WHERE lid = NEW.lid AND tid = NEW.tid;
    END;

-- If we move a track from one list to another we must update its
-- history & bookmark & last item (if present).
CREATE TRIGGER UpdateListTracksTrigger AFTER UPDATE OF lid 
        ON List_x_Tracks
    FOR EACH ROW
    BEGIN
        UPDATE LastItem SET lid = NEW.lid
            WHERE lid = OLD.lid AND tid = OLD.tid;
        UPDATE Bookmarks SET lid = NEW.lid
            WHERE lid = OLD.lid AND tid = OLD.tid;
        UPDATE History SET lid = NEW.lid
            WHERE lid = OLD.lid AND tid = OLD.tid;
    END;

-- Tracks may be freely deleted. Better to move to Unlisted.
CREATE TRIGGER DeleteTrackTrigger BEFORE DELETE ON Tracks
    FOR EACH ROW
    BEGIN
        DELETE FROM List_x_Tracks WHERE tid = OLD.tid;
        DELETE FROM LastItem WHERE tid = OLD.tid;
        DELETE FROM Bookmarks WHERE tid = OLD.tid;
        DELETE FROM History WHERE tid = OLD.tid;
    END;

-- Guarantees we have only zero or one last item record.
CREATE TRIGGER InsertLastItemTrigger BEFORE INSERT ON LastItem
    FOR EACH ROW
    BEGIN
        DELETE FROM LastItem;
    END;

CREATE TRIGGER InsertHistoryTrigger2 BEFORE INSERT ON History
    FOR EACH ROW
    BEGIN
        DELETE FROM History WHERE lid = NEW.lid AND tid = NEW.tid;
    END;

-- Ensures that we keep at most one track per list in the history.
CREATE TRIGGER InsertHistoryTrigger AFTER INSERT ON History
    FOR EACH ROW
    BEGIN
        DELETE FROM LastItem;
        INSERT INTO LastItem (lid, tid) VALUES (NEW.lid, NEW.tid);
        DELETE FROM History WHERE lid = NEW.lid AND tid != NEW.tid;
    END;

INSERT INTO Categories (cid, name) VALUES (0, 'Uncategorized');
INSERT INTO Lists (cid, lid, name) VALUES (0, 0, 'Unlisted');
INSERT INTO Categories (cid, name) VALUES (1, 'Classical');
INSERT INTO Categories (cid, name) VALUES (2, 'Pop');
