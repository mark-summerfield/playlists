-- Copyright © 2025 Mark Summerfield. All Rights Reserved.

PRAGMA USER_VERSION = 1;

CREATE TABLE Tracks (
    tid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    filename TEXT NOT NULL,
    secs INTEGER DEFAULT 0 NOT NULL,

    CHECK(secs >= 0)
);

CREATE TABLE Playlists (
    pid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    name TEXT NOT NULL
);

CREATE TABLE Categories (
    cid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    name TEXT NOT NULL,
    pos INTEGER UNIQUE NOT NULL, -- position of category

    CHECK(pos >= 0)
);

CREATE TABLE PlaylistTracks (
    pid INTEGER NOT NULL,
    tid INTEGER NOT NULL,
    pos INTEGER UNIQUE NOT NULL, -- position of track within playlist

    PRIMARY KEY (pid, tid),
    FOREIGN KEY(pid) REFERENCES Playlists(pid),
    FOREIGN KEY(tid) REFERENCES Tracks(tid),
    CHECK(pos >= 0)
);

CREATE TABLE CategoryPlaylists (
    cid INTEGER NOT NULL,
    pid INTEGER NOT NULL,
    pos INTEGER UNIQUE NOT NULL, -- position of playlist within category

    PRIMARY KEY (cid, pid),
    FOREIGN KEY(cid) REFERENCES Categories(cid),
    FOREIGN KEY(pid) REFERENCES Playlists(pid),
    CHECK(pos >= 0)
);

CREATE TABLE History (
    hid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    pid INTEGER NOT NULL,
    tid INTEGER NOT NULL,

    UNIQUE(pid, tid),
    FOREIGN KEY(pid) REFERENCES Playlists(pid),
    FOREIGN KEY(tid) REFERENCES Tracks(tid)
);

CREATE TABLE Bookmarks (
    bid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    pid INTEGER NOT NULL,
    tid INTEGER NOT NULL,

    UNIQUE(pid, tid),
    FOREIGN KEY(pid) REFERENCES Playlists(pid),
    FOREIGN KEY(tid) REFERENCES Tracks(tid)
);

-- Tracks may be freely deleted.
CREATE TRIGGER DeleteTrackTrigger BEFORE DELETE ON Tracks FOR EACH ROW
    BEGIN
        DELETE FROM History WHERE tid = OLD.tid;
        DELETE FROM Bookmarks WHERE tid = OLD.tid;
        DELETE FROM PlaylistTracks WHERE tid = OLD.tid;
    END;

-- If we delete a playlist then we must remove it from CategoryPlaylists
-- and also remove any of its tracks from PlaylistTracks.
CREATE TRIGGER DeletePlaylistTrigger BEFORE DELETE ON Playlists
    FOR EACH ROW
    BEGIN
        DELETE FROM History WHERE pid = OLD.pid;
        DELETE FROM Bookmarks WHERE pid = OLD.pid;
        DELETE FROM PlaylistTracks WHERE pid = OLD.pid;
        DELETE FROM CategoryPlaylists WHERE pid = OLD.pid;
    END;

-- Categories may only be deleted if they have no playlists.
CREATE TRIGGER DeleteCategoryTrigger BEFORE DELETE ON Categories
FOR EACH ROW
    BEGIN
        SELECT CASE WHEN (SELECT COUNT(*) FROM CategoryPlaylists
                          WHERE cid = OLD.cid) > 0 THEN
            RAISE(ABORT, 'category in use so cannot delete')
        END;
    END;
