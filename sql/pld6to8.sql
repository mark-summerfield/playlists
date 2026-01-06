-- Copyright © 2025 Mark Summerfield. All Rights Reserved.

DROP TABLE IF EXISTS Circled;

CREATE TABLE Circled (
    cid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    lid INTEGER NOT NULL, -- lid → cid
    tid INTEGER NOT NULL,

    UNIQUE(lid, tid),
    FOREIGN KEY(lid) REFERENCES Lists(lid),
    FOREIGN KEY(tid) REFERENCES Tracks(tid)
);

DROP TRIGGER IF EXISTS InsertCircledTrigger2;

CREATE TRIGGER InsertCircledTrigger2 BEFORE INSERT ON Circled
    FOR EACH ROW
    BEGIN
        DELETE FROM Circled WHERE lid = NEW.lid AND tid = NEW.tid;
    END;

DROP TRIGGER IF EXISTS InsertCircledTrigger;

-- Ensures that we have at most one circled track per list.
CREATE TRIGGER InsertCircledTrigger AFTER INSERT ON Circled
    FOR EACH ROW
    BEGIN
        DELETE FROM Circled WHERE lid = NEW.lid AND tid != NEW.tid;
    END;

DROP TRIGGER IF EXISTS DeleteListTrigger2;

CREATE TRIGGER DeleteListTrigger2 BEFORE DELETE ON Lists
    FOR EACH ROW
        WHEN OLD.lid != 0
    BEGIN
        DELETE FROM List_x_Tracks WHERE lid = OLD.lid;
        DELETE FROM LastItem WHERE lid = OLD.lid;
        DELETE FROM Circled WHERE lid = OLD.lid;
        DELETE FROM Bookmarks WHERE lid = OLD.lid;
        DELETE FROM History WHERE lid = OLD.lid;
        DELETE FROM Tracks WHERE tid IN (SELECT tid FROM OrphansView);
    END;

DROP TRIGGER IF EXISTS UpdateListTracksTrigger;

-- If we move a track from one list to another we must update its
-- history & bookmark & last item (if present).
CREATE TRIGGER UpdateListTracksTrigger AFTER UPDATE OF lid 
        ON List_x_Tracks
    FOR EACH ROW
    BEGIN
        UPDATE LastItem SET lid = NEW.lid
            WHERE lid = OLD.lid AND tid = OLD.tid;
        UPDATE Circled SET lid = NEW.lid
            WHERE lid = OLD.lid AND tid = OLD.tid;
        UPDATE Bookmarks SET lid = NEW.lid
            WHERE lid = OLD.lid AND tid = OLD.tid;
        UPDATE History SET lid = NEW.lid
            WHERE lid = OLD.lid AND tid = OLD.tid;
    END;

DROP TRIGGER IF EXISTS DeleteTrackTrigger;

-- Tracks may be freely deleted. Better to move to Unlisted.
CREATE TRIGGER DeleteTrackTrigger BEFORE DELETE ON Tracks
    FOR EACH ROW
    BEGIN
        DELETE FROM List_x_Tracks WHERE tid = OLD.tid;
        DELETE FROM LastItem WHERE tid = OLD.tid;
        DELETE FROM Circled WHERE tid = OLD.tid;
        DELETE FROM Bookmarks WHERE tid = OLD.tid;
        DELETE FROM History WHERE tid = OLD.tid;
    END;

PRAGMA USER_VERSION = 8;
