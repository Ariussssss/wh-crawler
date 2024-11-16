cover_id=$1
# sqlite3 wh.sqlite3.db <<EOF
# SELECT key, str
# FROM WH_DATA
# WHERE id = '$cover_id'
# EOF

# read -r -p "Download? [y/N] " response
# case "$response" in
#     [nN][oO]|[nN])
# 	exit
# 	;;
#     "")
cover=$(sqlite3 wh.sqlite3.db <<EOF
SELECT str
FROM WH_DATA
WHERE id = '$cover_id'
AND key = 'src'
EOF
     )
echo "$cover $cover_id $@"
target=$(basename $cover)
target="/home/arius/wallpaper/$target"
echo $target

if [ -f "$target" ]; then
    echo "$target Cover exists"
else
    echo "$target Download cover"
    aria2c --header 'sec-ch-ua: "Google Chrome";v="117", "Not;A=Brand";v="8", "Chromium";v="117"' \
	   --header 'sec-ch-ua-mobile: ?0' \
	   --header 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.0.0 Safari/537.36' \
	   --header 'sec-ch-ua-platform: "Linux"' \
	   --header 'Referer: https://wallhaven.cc/' \
	   --all-proxy="http://127.0.0.1:7890" \
	   -d /home/arius/wallpaper  \
	   $cover
fi
# ;;
# esac
