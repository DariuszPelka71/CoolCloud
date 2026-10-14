-- Descriptive tags shown to users for browsing and search.
-- Kind: 0 = Descriptive, 1 = Safety (matches CoolClouds.Domain.TagKind)

MERGE INTO Tags AS target
USING (VALUES
    (NEWID(), N'funny',    0),
    (NEWID(), N'spooky',   0),
    (NEWID(), N'cute',     0),
    (NEWID(), N'animal',   0),
    (NEWID(), N'portrait', 0),
    (NEWID(), N'creature', 0),
    (NEWID(), N'sunset',   0)
) AS source (Id, Name, Kind)
ON target.Name = source.Name AND target.Kind = source.Kind
WHEN NOT MATCHED THEN
    INSERT (Id, Name, Kind) VALUES (source.Id, source.Name, source.Kind);
