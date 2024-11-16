timeout=1000
code=$1
sub_filter_str=${@:2}

# echo $@
# echo $code
# echo $sub_filter_str
sqlite3 javbus.sqlite3.db <<EOF
.timeout $timeout
$(cat sql/data-preview.sql)
FROM 
    JAV_DATA
LEFT JOIN JAV_DOWNLOAD
ON JAV_DOWNLOAD.name = JAV_DATA.code
WHERE code = '$code'
EOF

sqlite3 javbus.sqlite3.db <<EOF
.timeout $timeout
SELECT
    code,
    date,
    printf('%.2f', size / 1024 / 1024.0 / 1024.0) || 'GB',
    title,
    CHAR(10) || magnet
FROM 
    JAV_MAGNET
WHERE $sub_filter_str
and code = '$code' 
ORDER BY date DESC
LIMIT 3
EOF
