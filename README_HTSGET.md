# Example

#### Get download endpoint for a specific dataset variants/reads <br>

`$ curl https://htsget.temp.gdi.lu:4433:4433/variants/s3/lnds-b1mg-rd-synthetic-data`

 
Response:
```
{"htsget":{"format":"VCF","urls":[{"url":"https://download.temp.gdi.lu:4433/s3/lnds-b1mg-rd-synthetic-data","headers":{"Range":"bytes=0-28"}}]}}
```

#### Get the data using the access token 


`$ curl -L -H "Authorization: Bearer $JWT" https://download.temp.gdi.lu:4433/s3/lnds-b1mg-rd-syntheti`


Get the token from https://login.temp.gdi.lu:4433

It is the last one on the list, then export it:

`$ export JWT=............................`

Get the list of dataset you have access


`$ curl -L -H "Authorization: Bearer $JWT" https://download.temp.gdi.lu:4433/metadata/datasets`

If the list is empty then make an application to rems.temp.gdi.lu:4433

Get files in the dataset 
```
# with lnds-b1mg-rd-synthetic-data being the ID of the dataset 

$ curl -L -H "Authorization: Bearer $JWT" https://download.temp.gdi.lu:4433/metadata/datasets/lnds-b1mg-rd-synthetic-data/files
```

Get the fileId from the previous command and use it to get the file (eg: here we download File with ID GDI001F2)


`$ curl -L -H "Authorization: Bearer $JWT" https://download.temp.gdi.lu:4433/files/GDIF001F2 > test`