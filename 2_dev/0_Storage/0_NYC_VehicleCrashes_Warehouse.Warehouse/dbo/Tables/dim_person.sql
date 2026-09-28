CREATE TABLE [dbo].[dim_person] (
    [person_key]          BIGINT        IDENTITY NOT NULL,
    [person_type]         VARCHAR (50)  NULL,
    [person_sex]          VARCHAR (10)  NULL,
    [ejection]            VARCHAR (50)  NULL,
    [emotional_status]    VARCHAR (50)  NULL,
    [bodily_injury]       VARCHAR (100) NULL,
    [position_in_vehicle] VARCHAR (100) NULL,
    [safety_equipment]    VARCHAR (100) NULL,
    [ped_location]        VARCHAR (100) NULL,
    [ped_action]          VARCHAR (100) NULL,
    [ped_role]            VARCHAR (50)  NULL
);


GO