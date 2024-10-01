

/* 
Get the latest file from:
https://microdata.worldbank.org/index.php/catalog/6164/get-microdata

https://microdata.worldbank.org/index.php/catalog/6164/download/101275
*/

cd "$data_in/WBMFP"
copy "https://microdata.worldbank.org/index.php/catalog/6164/download/101275" "BGD_RTFP_mkt_2007_2024-09-02.zip", replace
unzipfile "BGD_RTFP_mkt_2007_2024-09-02.zip", replace

import delimited "BGD_RTFP_mkt_2007_2024-09-02.csv", clear