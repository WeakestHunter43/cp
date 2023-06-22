nc=2
echo -e "\e[1;33mAll Download Script ClassPlus server app\e[0m"
#read -p "Token: " token
token="eyJhbGciOiJIUzM4NCIsInR5cCI6IkpXVCJ9.eyJpZCI6MTI4MjQxNTksIm9yZ0lkIjo0MTc1LCJ0eXBlIjoxLCJtb2JpbGUiOiI5MTk4ODU1MTA3NzAiLCJuYW1lIjoiU3Jpa2FudGgiLCJlbWFpbCI6InNyaWthbnRoY2hhbmRyYWdpcmkwMzdAZ21haWwuY29tIiwiaXNJbnRlcm5hdGlvbmFsIjowLCJkZWZhdWx0TGFuZ3VhZ2UiOiJFTiIsImNvdW50cnlDb2RlIjoiSU4iLCJjb3VudHJ5SVNPIjoiOTEiLCJ0aW1lem9uZSI6IkdNVCs1OjMwIiwiaXNEaXkiOmZhbHNlLCJmaW5nZXJwcmludElkIjoiNDAxZDVhMjkxNGVlYWZiMDMwNDNlOTM3MDhlYjhlNTAiLCJpYXQiOjE2ODYyMzM3NjgsImV4cCI6MTY4NjgzODU2OH0.rVNenKHtbIk8I24IYHcUlit1nYFwGTcqLMFAdWiV25eAIE58sLVewH5PPrfTgdTX"
read -p "Do you want to Download whole batch(y/n): " w
case "$w" in
  "y" | "Y" )
     read -p "Enter Course Id: " crs
     crs=${crs:-0}
     read -p "Enter  Resolution Quality(>=240p): " r
     r=${r:-240p}
     read -p "Enter Folder Name: " dname
     dname=${dname:-CLASSPLUS}
     curl -sS -X GET -H "Api-Version: 35" -H "Host:api.classplusapp.com" -H "x-access-token:$token" -H "mobile-agent: Mobile-Android" "https://api.classplusapp.com/v2/course/content/get?courseId=$crs&folderId=0" > mfolderid.json
     fl=$(cat mfolderid.json | jq -r '.status')
     if [ "$fl" == "failure" ]
     then
      echo "Error"
      exit
     fi
     cat mfolderid.json | jq -r '.data.courseContent[] | select(.contentType == 2)' | jq '. | select(.isLocked == 0)' | jq -r '.|.name,.url' > tmp.txt
     cat mfolderid.json | jq -r '.data.courseContent[] | select(.contentType == 1)' | jq -r '.|.name,.id' > fn.txt
     ;;
  "n" | "N" )
     read -p "Enter Course Id: " crs
     crs=${crs:-0}
     read -p "Enter Folder Id: " xxx
     xxx=${xxx:-0}
     read -p "Enter  Resolution Quality(>=240p): " r
     r=${r:-0}
     read -p "Enter Folder Name: " dname
     dname=${dname:-CLASSPLUS}
     curl -sS -X GET -H "Api-Version: 35" -H "Host:api.classplusapp.com" -H "x-access-token:$token" -H "mobile-agent: Mobile-Android" "https://api.classplusapp.com/v2/course/content/get?courseId=$crs&folderId=$xxx" > mfolderid.json
     fl=$(cat mfolderid.json | jq -r '.status')
     echo
     if [ "$fl" == "failure" ]
     then
      echo "Error"
      exit
     fi
     cat mfolderid.json | jq -r '.data.courseContent[] | select(.contentType == 2)' | jq '. | select(.isLocked == 0)' | jq -r '.|.name,.url' > tmp.txt
     cat mfolderid.json | jq -r '.data.courseContent[] | select(.contentType == 1)' | jq -r '.|.name,.id' > fn.txt
     ;;
  *)
     echo "Select Y or N"
     exit
esac
find ./$crs -name "*.json" > zzz.txt
xargs rm -rf < zzz.txt
dnm=$(echo $dname | sed -e 's/[[:punct:]]/_/g' | tr '_' ' ' | xargs | sed 's/ /_/g')
nlo=$(sed -n '$=' tmp.txt)
if [ -z "$nlo" ]
then
 echo -e "\e[1;31mNo Free video In this Folder\e[0m"
else
 nlr=$(($nlo/$nc))
 echo No of video present: $nlr
 ft=1
 lt=$nlr
 count=$ft
 st=$(expr '(' $ft '*' 2 ')' - 1)
 end=$(expr '(' $lt '*' 2 ')' - 1)
 for i in $(eval echo {$st..$end..2})
 do
    echo $count
    nm=$(echo $i)p
    w=1
    j=$(($i+$w))p
    url=$(sed -n $j tmp.txt)
    name=$(sed -n $nm tmp.txt | sed -e 's/[[:punct:]]/_/g' | tr '_' ' ' | xargs | sed 's/ /_/g')
    curl -sS -X GET -H "Api-Version: 22" -H "Host:api.classplusapp.com" -H "x-access-token:$token" -H "mobile-agent: Mobile-Android" "https://api.classplusapp.com/cams/uploader/video/jw-signed-url?url=$url" > link.json
    furl=$(cat link.json | jq -r '.url')
    if [ "$furl" == "null" ] || [ "$furl" == "" ];
    then
    echo -e "\e[1;31mSkipping, Video is Not Downloadable: \e[1;36m$name\e[0m"
     drmc=$(cat link.json | jq -r '.drmUrls.manifestUrl')
     if [ "$drmc" == "null" ]
     then
      echo
     else
      echo
      echo "DRM Video Data:"
      echo
      cat link.json | jq -r '.drmUrls|"mpd link","----",.manifestUrl,"\n","licns Url","----",.licenseUrl'
      mkdir -p $crs
      echo $name >> $crs/drm.txt
      cat link.json | jq -r '.drmUrls|"mpd link","----",.manifestUrl,"\n","licns Url","----",.licenseUrl,"\n\n"' >> $crs/drm.txt
    fi
    else
     echo $name
     echo $furl
     #yt-dlp -N 5 -S "res:$r" --no-check-certificate -S "res:$r" -o "$crs/$name.mp4" "$furl"
     streamlink --stream-sorting-excludes ">$r" --stream-segment-threads 5 "$furl" best -o "$crs/$name.hls" --force-progress
     echo 
     echo "Converting HLS to MP4 ---------->"
     ffpb -i "$crs/$name.hls" -c:v copy -bsf:a aac_adtstoasc "$crs/$name.mp4"
     rm -rf "$crs/$name.hls"
     echo ""
    fi
    count=$(($count+$w))
 done
fi
echo -e "\e[1;35mName Folder Available\e[0m"
cat fn.txt
fnt=$(sed -n '$=' fn.txt)
if [ -z "$fnt" ]
then
 echo -e "\e[1;31No Folder Inside\e[0m"
else
 fnvr=$(($fnt/$nc))
 echo -e "\e[1;35mNo of Folder: $fnvr\e[0m"
 ft=1
 lt=$fnvr
 count1=1
 st1=$(expr '(' $ft '*' 2 ')' - 1)
 end1=$(expr '(' $lt '*' 2 ')' - 1)
 for i in $(eval echo {$st1..$end1..2})
 do
    mkdir -p $crs
    echo $count1
    nm=$(echo $i)p
    w=1
    j=$(($i+$w))p
    furl=$(sed -n $j fn.txt)
    echo $furl
    name=$(sed -n $nm fn.txt | sed -e 's/[[:punct:]]/_/g' | tr '_' ' ' | xargs | sed 's/ /_/g')
    echo $name
    mkdir -p "$crs/$name"
    curl -sS -X GET -H "Api-Version: 22" -H "Host:api.classplusapp.com" -H "x-access-token:$token" -H "mobile-agent: Mobile-Android" "https://api.classplusapp.com/v2/course/content/get?courseId=$crs&folderId=$furl" > "$crs/$name/$furl".json
    count1=$(($count1+$w))
 done
fi
find ./$crs -name "*.json" > tmp0.txt
rs=$(cat tmp0.txt | wc -l)
if [ $rs -ne 0 ]
then
  rs=99
else
  rs=0
fi
until [ $rs -eq 0 ]; do
 echo "test"
 #if [ $rs -eq 0 ]
 #then
 # break
 #fi
 find ./$crs -name "*.json" > tmp0.txt
 endx=$(cat tmp0.txt |wc -l)
 st2=1
 end2=$endx
 for i in $(eval echo {$st2..$end2..1})
 do
  nm=$(echo $i)p
  fname=$(sed -n $nm tmp0.txt)
  cat "$fname" | jq '.data.courseContent[] | select(.contentType == 2)' | jq '. | select(.isLocked == 0)' | jq -r '.|.name,.url' > tmpx.txt
  cat "$fname" | jq '.data.courseContent[] | select(.contentType == 1)' | jq -r '.|.name,.id' > fnx.txt
  nlo=$(sed -n '$=' tmpx.txt)
  if [ -z "$nlo" ]
  then
   echo -e "\e[1;31mNo Free video In this Folder\e[0m"
  else
   nlr=$(($nlo/$nc))
   echo No of video present: $nlr
   ft=1
   lt=$nlr
   count=$ft
   st=$(expr '(' $ft '*' 2 ')' - 1)
   end=$(expr '(' $lt '*' 2 ')' - 1)
   for i in $(eval echo {$st..$end..2})
   do
    echo $count
    nm=$(echo $i)p
    w=1
    j=$(($i+$w))p
    url=$(sed -n $j tmpx.txt)
    name=$(sed -n $nm tmpx.txt | sed -e 's/[[:punct:]]/_/g' | tr '_' ' ' | xargs | sed 's/ /_/g')
    curl -sS -X GET -H "Api-Version: 22" -H "Host:api.classplusapp.com" -H "x-access-token:$token" -H "mobile-agent: Mobile-Android" "https://api.classplusapp.com/cams/uploader/video/jw-signed-url?url=$url" > link.json
    furl=$(cat link.json | jq -r '.url')
    if [ "$furl" == "null" ] || [ "$furl" == "" ];
    then
     echo -e "\e[1;31mSkipping, Video is Not Downloadable: \e[1;36m$name\e[0m"
     drmc=$(cat link.json | jq -r '.drmUrls.manifestUrl')
     if [ "$drmc" == "null" ]
     then
      echo
     else
      echo
      echo "DRM Video Data:"
      echo
      cat link.json | jq -r '.drmUrls|"mpd link","----",.manifestUrl,"\n","licns Url","----",.licenseUrl'
      fname2=$(echo ${fname%/*})
      mkdir -p $fname2
      echo $name >> $fname2/drm.txt
      cat link.json | jq -r '.drmUrls|"mpd link","----",.manifestUrl,"\n","licns Url","----",.licenseUrl,"\n\n"' >> $fname2/drm.txt
    fi
    else
     echo $fname
     fname2=$(echo ${fname%/*})
     echo $fname2
     echo $furl
     #yt-dlp -N 5 -S "res:$r" --no-check-certificate -S "res:$r" -o "$fname2/$name.mp4" "$furl"
     streamlink --stream-sorting-excludes ">$r" --stream-segment-threads 5 "$furl" best -o "$fname2/$name.hls" --force-progress
     echo
     echo "Converting HLS to MP4 ---------->"
     ffpb -i "$fname2/$name.hls" -c:v copy -bsf:a aac_adtstoasc "$fname2/$name.mp4"
     rm -rf "$fname2/$name.hls"
     echo ""
    fi
    count=$(($count+$w))
   done
  fi
  echo -e "\e[1;35mName Folder Available\e[0m"
  cat fnx.txt
  fnt=$(sed -n '$=' fnx.txt)
  if [ -z "$fnt" ]
  then
   echo -e "\e[1;31mNo Folder Inside\e[0m"
  else
   fnvr=$(($fnt/$nc))
   echo -e "\e[1;35mNo of Folder: $fnvr\e[0m"
   ft=1
   lt=$fnvr
   count1=1
   st1=$(expr '(' $ft '*' 2 ')' - 1)
   end1=$(expr '(' $lt '*' 2 ')' - 1)
   for i in $(eval echo {$st1..$end1..2})
   do
    echo $count1
    nm=$(echo $i)p
    w=1
    j=$(($i+$w))p
    furl=$(sed -n $j fnx.txt)
    echo $furl
    name=$(sed -n $nm fnx.txt | sed -e 's/[[:punct:]]/_/g' | tr '_' ' ' | xargs | sed 's/ /_/g')
    echo $name
    echo $fname
    fname2=$(echo ${fname%/*})
    echo $fname2
    mkdir -p "$fname2/$name"
    curl -sS -X GET -H "Api-Version: 22" -H "Host:api.classplusapp.com" -H "x-access-token:$token" -H "mobile-agent: Mobile-Android" "https://api.classplusapp.com/v2/course/content/get?courseId=$crs&folderId=$furl" > "$fname2/$name/$furl".json
    count1=$(($count1+$w))
   done
  fi
  rm -rfv $fname
 done
 find ./$crs -name "*.json" > tmp0.txt
 rs=$(cat tmp0.txt | wc -l)
 #rs=0
done
mv ./$crs $dnm
tree ./$dnm
rm -rf mfolderid.json
rm -rf fn.txt
rm -rv tmp.txt
rm -rf tmp0.txt
rm -rf tmpx.txt
rm -rf fnx.txt
rm -rf link.json
