## Senate Lobbying disclosures


A one-liner to fetch and unzip all at once (using the pup HTML commandline parser):

~~~bash
curl -s http://www.senate.gov/legislative/Public_Disclosure/database_download.htm … | \
pup 'a attr{href}' | grep '.zip' | xargs wget && unzip '*.zip'
~~~
