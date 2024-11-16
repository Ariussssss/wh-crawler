SELECT
    CHAR(10) || 
    CASE	
        WHEN JAV_DOWNLOAD.url IS NULL THEN 'NEW '
        ELSE 'DONE'
    END AS column2,
    release_date,
    title || CHAR(10),
    REPLACE(actress, CHAR(10), ','),
    duration, studio, label, director,
    CHAR(10) || REPLACE(genre, CHAR(10), ','),
    CHAR(10) || JAV_DOWNLOAD.url
    -- CHAR(10) ||  COALESCE(JAV_DOWNLOAD.url, 'not download')
