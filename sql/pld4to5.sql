-- Copyright © 2025 Mark Summerfield. All Rights Reserved.

CREATE TRIGGER InsertHistoryTrigger2 BEFORE INSERT ON History
    FOR EACH ROW
    BEGIN
        DELETE FROM History WHERE lid = NEW.lid AND tid = NEW.tid;
    END;

PRAGMA USER_VERSION = 5;
