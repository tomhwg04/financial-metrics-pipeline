CREATE TABLE config.source_priority(
    source varchar(40) PRIMARY KEY,
    [priority] int NOT NULL,
    is_active bit NOT NULL DEFAULT(1),
    [description] varchar(255),
    CONSTRAINT UQ_source_priority_priority UNIQUE (priority),
    CONSTRAINT CK_source_priority_priority_positive CHECK(priority > 0)
);