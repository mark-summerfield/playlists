-- Copyright © 2025 Mark Summerfield. All Rights Reserved.

DROP TRIGGER IF EXISTS InsertHistoryTrigger;

-- Ensures that we keep at most one track per list in the history.
CREATE TRIGGER InsertHistoryTrigger AFTER INSERT ON History
    FOR EACH ROW
    BEGIN
        DELETE FROM LastItem;
        INSERT INTO LastItem (lid, tid) VALUES (NEW.lid, NEW.tid);
        DELETE FROM History WHERE lid = NEW.lid AND tid != NEW.tid;
    END;

PRAGMA USER_VERSION = 4;
