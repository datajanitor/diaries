# Dallas Crime Reports

The city of Dallas, Texas puts all of their crime incident reports on a FTP site. The one inconvenient part of that is that the reports are zipped with this naming convention:

    OFFENSE_[Month]_[Day]_[Year]

e.g.

  ftp://66.97.146.93/OFFENSE_10_8_2013.zip


The immediate takeaway is that, from 2010 to 2014, there could be 1,200+ zip files to manually download and unpack (previous years are all combined into a single ZIP).

This mini-project shows how to iterate across a FTP list and download the files, saving us from an interminable hell of point-and-click/dragging.
