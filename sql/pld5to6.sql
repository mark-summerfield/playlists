-- Copyright © 2025 Mark Summerfield. All Rights Reserved.

DROP VIEW ListTracksView;

CREATE VIEW ListTracksView AS
    SELECT ListsTrimView.lid, Tracks.tid, Tracks.filename, Tracks.name,
           Tracks.artist
        FROM ListsTrimView, Tracks, List_x_Tracks, CategoriesTrimView
        WHERE ListsTrimView.lid = List_x_Tracks.lid
            AND Tracks.tid = List_x_Tracks.tid
            AND ListsTrimView.cid = CategoriesTrimView.cid
        ORDER BY LOWER(CategoriesTrimView.tname),
                 LOWER(ListsTrimView.tname), List_x_Tracks.pos;

PRAGMA USER_VERSION = 6;
