# Pentagon Surplus Property Data + Census Quickfacts

A variation of the cleanup and joining done for the NPR story, ["MRAPs And Bayonets: What We Know About The Pentagon's 1033 Program"](http://www.npr.org/2014/09/02/342494225/mraps-and-bayonets-what-we-know-about-the-pentagons-1033-program)

The original LESO data can be found at NPRviz's github repo: https://github.com/nprapps/leso/


## Draft cleanup instructions

### `FIPS_CountyName.txt`

##### Sample:

    00000 UNITED STATES
    01000 ALABAMA
    01001 Autauga County, AL
    01003 Baldwin County, AL
    01005 Barbour County, AL
    01007 Bibb County, AL
    01009 Blount County, AL

##### Problem:

This needs to be turned into a comma-delimited file. And the rows without actual counties, e.g. `01000 ALABAMA`, can be deleted for our eventual purpose.


##### Goal:

    FIPS,County,State
    01001,AUTAUGA COUNTY,AL
    01003,BALDWIN COUNTY,AL
    01005,BARBOUR COUNTY,AL
    01007,BIBB COUNTY,AL


##### Cleanup:

1. Use regex in a text editor

  __Find:__ `(\d{5}) (.+?), (.+)`

  __Replace__ `\1,\U\2,\3` (or: `$1,\U$2,$3`)

2. Use a regex to delete the rows that look like:

   ~~~
   00000 UNITED STATES
   01000 ALABAMA
   ~~~

  __Find:__ `^\d{5} .+\n`

  __Replace__ `[with nothing]`

3. Add a headers column:

    `FIPS,County,State`



### `DataDict.txt`
  
This file does not need to be cleaned, but we will refer to it later for `Data_Item`. It's not worth putting this directly into the database.

Sample:

    Data_Item                                     Item_Description                                   Unit Decimal  US_Total  Minimum   Maximum Source
    STATECOU  FIPS State and County code
    PST045213 Population, 2013 estimate                                                               ABS    0    316128839       90 316128839 CENSUS
    PST040210 Population, 2010 (April 1) estimates base                                               ABS    0    308747716       82 308747716 CENSUS
    PST120213 Population, percent change - April 1, 2010 to July 1, 2013                              PCT    1          2.4    -18.6      46.4 CENSUS
    POP010210 Population, 2010                                                                        ABS    0    308745538       82 308745538 CENSUS


#### psc-codes.csv

This is already in CSV format, so you can import it directly into Excel or a database.

##### Sample

    PSC CODE,PRODUCT AND SERVICE CODE NAME,START DATE,END DATE,PRODUCT AND SERVICE CODE FULL NAME,PRODUCT AND SERVICE CODE EXCLUDES,PRODUCT AND SERVICE CODE NOTES,PRODUCT AND SERVICE CODE INICLUDES
    10,WEAPONS,10/1/1979,,,,"This group includes combat weapons as well as weapon-like noncombat items, such as line throwing devices and pyrotechnic pistols.  Also included in this group are weapon neutralizing equipment, such as degaussers, and deception equipment, such as camouflage nets.  Excluded from this group are fire control and night devices classifiable in groups 12 or 58.",
    1000,,12/12/2003,10/1/2006,,,,
    1005,"GUNS, THROUGH 30MM",10/1/2011,,"Guns, through 30 mm","Turrets, Aircraft.",,"Machine guns; Brushes, Machine Gun and Pistol."
    1005,"GUNS, THROUGH 30 MM",10/15/1978,9/30/2011,"Guns, through 30 mm","Turrets, Aircraft.",,"Machine guns; Brushes, Machine Gun and Pistol."
    1010,"GUNS, OVER 30MM UP TO 75MM",10/1/2011,,"Guns, over 30 mm up to 75 mm",,,"Breech Mechanisms; Mounts Grenade Launchers for Integral-Cartridge Grenades, Single-Shot or Auto-Loading or Automatic-Firing."
    1010,"GUNS, OVER 30 MM UP TO 75 MM",10/15/1978,9/30/2011,"Guns, over 30 mm up to 75 mm",,,"Breech Mechanisms; Mounts Grenade Launchers for Integral-Cartridge Grenades, Single-Shot or Auto-Loading or Automatic-Firing."


##### Problem

There are duplicate rows for the same `PSC CODE`, e.g.

    1005,"GUNS, THROUGH 30MM",10/1/2011,,"Guns, through 30 mm","Turrets, Aircraft.",,"Machine guns; Brushes, Machine Gun and Pistol."
    1005,"GUNS, THROUGH 30 MM",10/15/1978,9/30/2011,"Guns, through 30 mm","Turrets, Aircraft.",,"Machine guns; Brushes, Machine Gun and Pistol."

The "unclean" part in this sample is the second row, as it shows what `1005` _used_ to correspond to, from 10/15/1978 to 9/30/2011. This can be fixed in either a spreadsheet or database:


__Spreadsheet__

- Import as CSV into a spreadsheet
- Sort by `END_DATE`
- Delete all rows with an actual `END_DATE`


__Database__

- Import as CSV
- Execute query:
 
    ~~~sql
    DELETE FROM `psc-codes.csv` WHERE END_DATE != '' AND END_DATE IS NOT NULL
    ~~~



