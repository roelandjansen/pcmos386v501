erase cdlmos.exe
copy cdlink.mos cdlink.sys
pkzip cdlmos admin.exe cdlink.sys cdstat.com license.doc cdlink.doc
zip2exe cdlmos.zip -j
erase cdlmos.zip
