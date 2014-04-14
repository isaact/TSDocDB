TSDocDB
========
A simple, flexible db system built on top of the powerful [Tokyo Cabinet](http://fallabs.com/tokyocabinet/) embedded database system. TSDocDB adds an objective-c wrapper to tokyo cabinet and provides many conveniences to allow rapid deployment in your iOS os OSX application. TSDocDB is a more flexible approach to dealing data problems than the usual RDBMS way and supports powerful full-text searching abilities. This code is currently being used in some production OSX and iOS applications with tight memory constraints.

Sample Apps
===========
Included in the project are sample OSX and iOS apps that demonstrate the power of the database system and present a detailed how-to guide. Both applications use a [GeoNames](http://www.geonames.org/) datasource and allow the user to see every city on the planet with a population > 15k (about 23,000 cities in all). Both also allow the user full text searching on the city and country name.

Adding To Your Project
======================

Using the static lib (iOS)
---------------------------
1. Download the source
2. Add TSDocDB.xcodeproj to your workspace or project
3. Add $(BUILT_PRODUCTS_DIR) to the "User Header Search Paths" and set it to recursive for both your [project](TSDocDB/raw/master/capProject.png) and [target](TSDocDB/raw/master/capTarget.png).
4. Make sure "Always Search User Paths" is set to true.
5. Link you app binary to libTSDocDB.iOS.a, libz.1.2.3.dylib and libbz2.1.0.5.dylib
6. In your class file include TSDB.h
7. Create a new class object that implements the TSDBDefinitionsDelegate protocol. See the sample app(`CityDBDelegate`) for an example of how to do this.

Using the static lib (OSX)
----------------------------
1. Download the source
2. Add TSDocDB.xcodeproj to your workspace or project
3. Add $(BUILT_PRODUCTS_DIR) to the "User Header Search Paths" and set it to recursive for both your [project](TSDocDB/raw/master/capProject.png) and [target](TSDocDB/raw/master/capTarget.png).
4. Make sure "Always Search User Paths" is set to true.
5. Link you app binary to libTSDocDB.OSX.a, libz.1.2.3.dylib and libbz2.1.0.5.dylib 
6. In your class file include TSDB.h
7. Create a new class object that implements the TSDBDefinitionsDelegate protocol. See the sample app(`CityDBDelegate`) for an example of how to do this.

TSDocDB Classes
===============	

##[TSDB](https://github.com/isaact/TSDocDB/blob/master/TSDB.markdown)

TSDB is the main object you'll be using in you application. Each TSDB object represents a connection to a tokyo cabinet database. Multiple connections to the same db are allowed. [More info here](https://github.com/isaact/TSDocDB/blob/master/TSDB.markdown)

##TSDBDefinitionsDelegate(Protocol)

You will need to create a class that implements this protocol. TSDB uses this delegate object to determine the different types of rows your application will use and what columns should be indexed. See the sample app(`CityDBDelegate`) to see how to make a proper TSDBDefinitionsDelegate object.

By default rows are represented as NSDictionary objects. Keys must be NSString objects or they must respond to the stringValue message. Values may be NSString, NSNumber, NSDictionary or NSArray. The last two will be serialized before being stored in the db.

If you want search queries to return model objects instead, implement the method `-(id)TSModelObjectForData:(NSDictionary *)rowData andRowType:(NSString *)rowType;` in the delegate object. TSDB will call this method to create the model object out of the raw data and return that in the search result.



##TSDBManager

TSDBManager is used by TSDB to perform low level db operations such as creation of tokyo cabinet dbs. You can use the class method of this object `[TSDBManager closeAll];` to close down all open databases in your `applicationWillTerminate:` method.

##TSDBQuery

A predefined search list object, use this object to create/maintain "Smart List/Folder" style lists in your application.


