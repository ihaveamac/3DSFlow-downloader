3dsxtool extra/lpp-3ds.elf 3DSFlow-downloader.3dsx --smdh=3DSFlow-downloader.smdh --romfs=romfs/
rm 3DSFlow-downloader.zip
if [[ $1 ]]; then
    3dslink -a $1 3DSFlow-downloader.3dsx
else
    zip 3DSFlow-downloader.zip 3DSFlow-downloader.3dsx 3DSFlow-downloader.smdh 3DSFlow-downloader.xml
fi