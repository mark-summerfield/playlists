-- Copyright © 2025 Mark Summerfield. All Rights Reserved.

PRAGMA USER_VERSION = 1;

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

    CHECK(secs >= 0)
);

CREATE TABLE List_x_Tracks (
    lid INTEGER NOT NULL, -- lid → cid
    tid INTEGER NOT NULL,

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

CREATE VIEW CategoriesView AS
    SELECT cid, name FROM Categories ORDER BY LOWER(name);

CREATE VIEW ListsView AS
    SELECT Lists.cid, Lists.lid, Lists.name FROM Lists, Categories
        WHERE Lists.cid = Categories.cid
        ORDER BY LOWER(Categories.name), LOWER(Lists.name);

CREATE VIEW BookmarksView AS
    SELECT lid, Tracks.tid, filename FROM Bookmarks, Tracks
        WHERE Tracks.tid = Bookmarks.tid ORDER BY bid DESC;

CREATE VIEW HistoryView AS
    SELECT lid, Tracks.tid, filename FROM History, Tracks
        WHERE Tracks.tid = History.tid ORDER BY hid DESC;

CREATE VIEW ListTracksView AS
    SELECT Lists.lid, Tracks.tid, Tracks.filename
        FROM Lists, Tracks, List_x_Tracks, Categories
        WHERE Lists.lid = List_x_Tracks.lid
            AND Tracks.tid = List_x_Tracks.tid
            AND Lists.cid = Categories.cid
        ORDER BY LOWER(Categories.name), LOWER(Lists.name),
                 LOWER(Tracks.filename);

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

-- If we delete a list then we must remove any of its tracks from
-- List_x_Tracks; the Unlisted list may not be deleted.
CREATE TRIGGER DeleteListTrigger1 BEFORE DELETE ON Lists
    FOR EACH ROW WHEN OLD.lid = 0
    BEGIN
        SELECT RAISE(ABORT, 'cannot delete the Unlisted list');
    END;

CREATE TRIGGER DeleteListTrigger2 BEFORE DELETE ON Lists
    FOR EACH ROW
        WHEN OLD.lid != 0
    BEGIN
        UPDATE List_x_Tracks SET lid = 0 WHERE lid = OLD.lid;
        DELETE FROM LastItem WHERE lid = OLD.lid;
        DELETE FROM Bookmarks WHERE lid = OLD.lid;
        DELETE FROM History WHERE lid = OLD.lid;
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

-- Guarantees we have only zero or one last item record
CREATE TRIGGER InsertLastItemTrigger BEFORE INSERT ON LastItem
    FOR EACH ROW
    BEGIN
        DELETE FROM LastItem;
    END;

CREATE TRIGGER InsertHistoryTrigger AFTER INSERT ON History
    FOR EACH ROW
    BEGIN
        DELETE FROM LastItem;
        INSERT INTO LastItem (lid, tid) VALUES (NEW.lid, NEW.tid);
    END;

INSERT INTO Categories (cid, name) VALUES (0, 'Uncategorized');
INSERT INTO Lists (cid, lid, name) VALUES (0, 0, 'Unlisted');
INSERT INTO Categories (cid, name) VALUES (1, 'Classical');
INSERT INTO Categories (cid, name) VALUES (2, 'Pop');
