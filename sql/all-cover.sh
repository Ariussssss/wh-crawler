covers=$(sqlite3 wh.sqlite3.db <<EOF
SELECT str FROM WH_DATA
WHERE key = 'thumb'
EOF
)

total=$(sqlite3 wh.sqlite3.db <<EOF
SELECT count() FROM WH_DATA
WHERE key = 'thumb'
EOF
)

# echo $(cat <<EOF
# $prefix
# SELECT code
# $subfix
# EOF
# )
cover_list=''
max_jobs=24
current_jobs=0

cnt=0
for cover in $covers
do
    cnt=$((cnt + 1))
    prefix="$cnt/$total"
    target=$(basename $cover)
    target="./cover/$target"
    # echo $target
    cover_list="$cover_list $target"

    if [ -f "$target" ]; then
	echo "$prefix $target Cover exists"
	continue
    else
	echo "$prefix $target Download cover"
	aria2c --header 'sec-ch-ua: "Google Chrome";v="117", "Not;A=Brand";v="8", "Chromium";v="117"' \
	       --header 'sec-ch-ua-mobile: ?0' \
	       --header 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.0.0 Safari/537.36' \
	       --header 'sec-ch-ua-platform: "Linux"' \
	       --header 'Referer: https://wallhaven.cc/' \
	       --all-proxy="http://127.0.0.1:7890" \
	       -d ./cover \
	       -q \
	       $cover &
	((current_jobs++))

	if [[ $current_jobs -ge $max_jobs ]]; then
            wait -n
            ((current_jobs--))
	fi
    fi
done

wait
du -h -d 1
echo 'sleeping...'
sleep 30
sh "$0"
# echo $cover_list

