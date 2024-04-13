
del x-bkemugid/Img/ANDOS.IMG
copy "x-bkemugid\Img\ANDOS_.IMG " "x-bkemugid\Img\ANDOS.IMG"
bkdecmd a x-bkemugid/Img/ANDOS.IMG HWYENC.BIN
bkdecmd a x-bkemugid/Img/ANDOS.IMG HWYSCR.LZS
bkdecmd a x-bkemugid/Img/ANDOS.IMG HWYENC.LZS

start x-bkemugid\BK_x64.exe /B hwyenc.bin /C BK-0011M_FDD
