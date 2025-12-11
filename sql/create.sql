-- Copyright © 2025 Mark Summerfield. All Rights Reserved.

PRAGMA USER_VERSION = 1;

-- name may be of form Category/Name or plain Name
CREATE TABLE Playlists (
    pid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    name TEXT NOT NULL
);

CREATE TABLE Tracks (
    tid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    filename TEXT NOT NULL,
    secs INTEGER DEFAULT 0 NOT NULL,

    CHECK(secs >= 0)
);

-- Only ever has one record: auto updated when history inserted.
CREATE TABLE LastItem (
    pid INTEGER NOT NULL,
    tid INTEGER NOT NULL,

    PRIMARY KEY(pid, tid),
    FOREIGN KEY(pid) REFERENCES Playlists(pid),
    FOREIGN KEY(tid) REFERENCES Tracks(tid)
);

CREATE TABLE PlaylistTracks (
    pid INTEGER NOT NULL,
    tid INTEGER NOT NULL,
    pos INTEGER NOT NULL, -- position of track (within playlist)

    UNIQUE(pid, pos),
    PRIMARY KEY (pid, tid),
    FOREIGN KEY(pid) REFERENCES Playlists(pid),
    FOREIGN KEY(tid) REFERENCES Tracks(tid),
    CHECK(pos >= 0)
);

CREATE TABLE Bookmarks (
    bid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    pid INTEGER NOT NULL,
    tid INTEGER NOT NULL,

    UNIQUE(pid, tid),
    FOREIGN KEY(pid) REFERENCES Playlists(pid),
    FOREIGN KEY(tid) REFERENCES Tracks(tid)
);

CREATE TABLE History (
    hid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    pid INTEGER NOT NULL,
    tid INTEGER NOT NULL,

    UNIQUE(pid, tid),
    FOREIGN KEY(pid) REFERENCES Playlists(pid),
    FOREIGN KEY(tid) REFERENCES Tracks(tid)
);

CREATE VIEW PlaylistsView AS
    SELECT (pid, name) FROM Playlists ORDER BY LOWER(name);

CREATE VIEW BookmarksView AS
    SELECT (pid, tid) FROM Bookmarks ORDER BY bid DESC;

CREATE VIEW HistoryView AS
    SELECT (pid, tid) FROM History ORDER BY hid DESC;

-- Guarantees we have only one last item record
CREATE TRIGGER InsertLastItemTrigger BEFORE DELETE ON LastItem
    FOR EACH ROW
    BEGIN
        DELETE FROM LastItem;
    END;

CREATE TRIGGER InsertHistoryTrigger AFTER INSERT ON History
    FOR EACH ROW
    BEGIN
        DELETE FROM LastItem;
        INSERT INTO LastItem (pid, tid) VALUES (NEW.pid, NEW.tid);
    END;

-- Tracks may be freely deleted. Better to move to Uncategorized.
CREATE TRIGGER DeleteTrackTrigger BEFORE DELETE ON Tracks
    FOR EACH ROW
    BEGIN
        DELETE FROM History WHERE tid = OLD.tid;
        DELETE FROM Bookmarks WHERE tid = OLD.tid;
        DELETE FROM PlaylistTracks WHERE tid = OLD.tid;
    END;

-- If we delete a playlist then we must remove any of its tracks from
-- PlaylistTracks; Uncategorized may not be deleted.
CREATE TRIGGER DeletePlaylistTrigger1 BEFORE DELETE ON Playlists
    FOR EACH ROW
        WHEN OLD.pid != 0
    BEGIN
        DELETE FROM History WHERE pid = OLD.pid;
        DELETE FROM Bookmarks WHERE pid = OLD.pid;
        DELETE FROM PlaylistTracks WHERE pid = OLD.pid;
    END;

CREATE TRIGGER DeletePlaylistTrigger2 BEFORE DELETE ON Playlists
    FOR EACH ROW
        WHEN OLD.pid = 0
    BEGIN
        SELECT RAISE(ABORT, 'cannot delete the Uncategorized playlist');
    END;

-- If we move a track from one playlist to another we must update its
-- history & bookmark (if present).
CREATE TRIGGER UpdatePlaylistTracksTrigger AFTER UPDATE OF pid 
        ON PlaylistTracks
    FOR EACH ROW
    BEGIN
        UPDATE Bookmarks SET pid = NEW.pid
            WHERE pid = OLD.pid AND tid = OLD.tid;
        UPDATE History SET pid = NEW.pid
            WHERE pid = OLD.pid AND tid = OLD.tid;
    END;

-- If we delete a track from its last playlist it must be moved to the
-- Uncategorized playlist (unless it is already there).
CREATE TRIGGER DeletePlaylistTracksTrigger AFTER DELETE ON PlaylistTracks
    FOR EACH ROW
        WHEN (SELECT COUNT(*) FROM PlaylistTracks WHERE tid = OLD.tid) = 0
              AND OLD.pid != 0
    BEGIN
        INSERT INTO PlaylistTracks (pid, tid) VALUES (0, OLD.tid);
    END;

INSERT INTO Playlists (pid, name) VALUES (0, 'Uncategorized');
INSERT INTO Playlists (name) VALUES ('Ad-hoc Favourites');
