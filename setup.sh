pkg update -y
termux-setup-storage
pkg install curl jq python ffmpeg tree -y
pip install yt-dlp
pkg install libxml2 libxslt -y
CFLAGS="-O0" pip install lxml
pip install streamlink
pip install ffpb
