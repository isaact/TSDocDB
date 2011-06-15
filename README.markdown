TSDocDB
========
A simple, flexible db system built on top of the powerful [Tokyo Cabinet](http://fallabs.com/tokyocabinet/) embedded database system. TSDocDB adds an objective-c wrapper to tokyo cabinet and provides many conveniences to allow rapid deployment in your iOS os OSX application. See the included sample app for a detailed use case.

The Objects
===========

##[TSDB](blob/master/TSDB.markdown)

TSDB is the main object you will be using in you application. Each TSDB object represents a connection to a tokyo cabinet database. Multiple connections to the same db are allowed.

##TSDBManager

TSDBManager is used by TSDB to perform low level db operations such as creation of tokyo cabinet dbs. You can use the class method of this object `[TSDBManager closeAll];` to close down all open databases in your `applicationWillTerminate:` method.

##TSDBQuery

A predefined search list object, use this object to create/maintain "Smart List/Folder" style lists in your application.



