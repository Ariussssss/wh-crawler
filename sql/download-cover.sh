cover_list=''
covers=$@

max_jobs=24
current_jobs=0

for cover in $covers
do
    target=$(basename $cover)
    target="./cover/$target"
    # echo $target
    cover_list="$cover_list $target"

    if [ -f "$target" ]; then
	# echo "$target Cover exists"
	continue
    else
	# echo "$target Download cover"
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

echo $cover_list
