timeout=1000
of=${1:-0}
st=${2:-0}
meta=${3:-''}
total=30

meta_str=''
cnt=0
for m in $meta
do
    cnt=$((cnt + 1))
    # echo $m
    if [ -z "$meta_str" ] ; then
	meta_str="str = '$m'"
    else
	meta_str="$meta_str or str = '$m'"
    fi
done

if [ -z "$meta_str" ] ; then
    meta_str='1=1'
fi

st_str="ORDER BY date DESC"
if [ "$st" -gt 1 ]; then
    st_str="ORDER BY fav DESC"
elif [ "$st" -gt 0 ]; then
    st_str="ORDER BY view DESC"
fi


echo "$meta_str, $cnt, page: $((of / total)), offset: $of"

prefix=$(cat <<EOF
.timeout $timeout
EOF
)

subfix() {
    key=$1
    col=${2:-'A.str'}
    echo $(cat<<EOF
SELECT $col
FROM (SELECT rowid, id, str FROM WH_DATA WHERE key = '$key') A
LEFT JOIN (SELECT id, num as fav FROM WH_DATA WHERE key = 'favorite') F
ON A.id = F.id
LEFT JOIN (SELECT id, num as view FROM WH_DATA WHERE key = 'view') V
ON A.id = V.id
LEFT JOIN (SELECT id, str as date_str, num as date FROM WH_DATA WHERE key = 'upload') D
ON A.id = D.id
WHERE ('$meta' = '' OR A.id IN (
      SELECT A.id FROM (
          SELECT id, count() s
	  FROM WH_DATA
	  WHERE $meta_str
	  GROUP BY id
      )
      WHERE s >= $cnt
))
$st_str
LIMIT $total
OFFSET $of
EOF
)
}
subfix=$(cat <<EOF

EOF
)
cs=$(subfix 'thumb')
# echo $(cat <<EOF
covers=$(sqlite3 wh.sqlite3.db <<EOF
$prefix
$cs
EOF
)

# echo $(cat <<EOF
# $prefix
# SELECT code
# $subfix
# EOF
# )
cover_list=$(sh ./sql/download-cover.sh $covers)


cs=$(subfix 'tag' "printf('%03d', ROW_NUMBER() OVER () - $of - 24) AS row_number, A.id, substr(date_str, 1, 10) ,  'Views: '|| printf('%6d', view), 'Fav: ' || printf('%6d', fav), A.str")

sqlite3 wh.sqlite3.db <<EOF | while IFS="|" read -r num i d v f tag; do
$prefix
$cs
EOF
     echo -e "$num zer://wh-$i $d \e[1;37;45m$v\e[0m \e[1;37;46m$f\e[0m $tag"
done

# echo "$cover_list"
gridW=5
gridH=6

W=300
H=200
LW=$(($W * $gridW))
LH=$(($H * ($gridH + 1)))
# pwd
# echo $cover_list
cmd=$(cat <<EOF
feh --geometry +3000+60 -i --index-info '' --thumb-width $W --thumb-height $H \
   --limit-width $LW --limit-height $LH --zoom 170 $cover_list

EOF
    )
# echo $cmd
eval $cmd
echo ''
if read -q "choice?Stop?"; then
    echo $choice
else
    cmd="source \"$0\" $((of + total)) $st \"$meta\""
    print -s "$cmd"
    eval $cmd
fi
