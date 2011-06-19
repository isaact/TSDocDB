TSDocDB
========
A simple, flexible db system built on top of the powerful [Tokyo Cabinet](http://fallabs.com/tokyocabinet/) embedded database system. TSDocDB adds an objective-c wrapper to tokyo cabinet and provides many conveniences to allow rapid deployment in your iOS os OSX application. See the included sample app for a detailed use case.

TSDocDB is a more flexible approach to dealing data problems than the usual RDBMS way and supports powerful full-text searching abilities. This code is currently being used in some production OSX and iOS applications with tight memory constraints.


TSDocDB Classes
===============	

##[TSDB](TSDocDB/blob/master/TSDB.markdown)

TSDB is the main object you'll be using in you application. Each TSDB object represents a connection to a tokyo cabinet database. Multiple connections to the same db are allowed. [More info here](TSDocDB/blob/master/TSDB.markdown)

##TSDBDefinitionsDelegate(Protocol)

You will need to create a class that implements this protocol. TSDB uses this delegate object to determine the different types of rows your application will use and what columns should be indexed. See the sample app(`CityDBDelegate`) to see how to make a proper TSDBDefinitionsDelegate object.

By default rows are represented as NSDictionary objects. If you want search queries to return model objects instead, implement the method `-(id)TSModelObjectForData:(NSDictionary *)rowData andRowType:(NSString *)rowType;` in the delegate object. TSDB will call this method to create the model object out of the raw data and return that in the search result.

##TSDBManager

TSDBManager is used by TSDB to perform low level db operations such as creation of tokyo cabinet dbs. You can use the class method of this object `[TSDBManager closeAll];` to close down all open databases in your `applicationWillTerminate:` method.

##TSDBQuery

A predefined search list object, use this object to create/maintain "Smart List/Folder" style lists in your application.

Adding To Your Project
======================

Using the static lib (iOS)
---------------------------
1. Download the source
2. Add TSDocDB.xcodeproj to your workspace or project
3. Add $(BUILT_PRODUCTS_DIR) to the "User Header Search Paths" and set it to recursive
4. Make sure "Always Search User Paths" is set to true.
5. Link you app binary to libTSDocDB.iOS.a, libz.1.2.3.dylib and libbz2.1.0.5.dylib
6. In your class file include TSDB.h
7. Create a new class object that implements the TSDBDefinitionsDelegate protocol. See the sample app(`CityDBDelegate`) for an example of how to do this.

Using the static lib (OSX)
----------------------------
1. Download the source
2. Add TSDocDB.xcodeproj to your workspace or project
3. Add $(BUILT_PRODUCTS_DIR) to the "User Header Search Paths" and set it to recursive
4. Make sure "Always Search User Paths" is set to true.
5. Link you app binary to libTSDocDB.OSX.a, libz.1.2.3.dylib and libbz2.1.0.5.dylib 
6. In your class file include TSDB.h
7. Create a new class object that implements the TSDBDefinitionsDelegate protocol. See the sample app(`CityDBDelegate`) for an example of how to do this.

