//
//  IFDB.h
//  SemoContent
//
//  Created by Julian Goacher on 07/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFDBHelper.h"
#import "IFService.h"

/**
 * A SQL database wrapper.
 * Provides methods for performing DB operations - queries, inserts, updates & deletes.
 */
@interface IFDB : NSObject <IFDBHelperDelegate, IFService> {
    IFDBHelper *_dbHelper;
    NSDictionary *_taggedTableColumns;
    NSDictionary *_tableColumnNames;
    NSMutableDictionary *_initialData;
}

/** The database name. */
@property (nonatomic, strong) NSString *name;
/** The current database schema version number. */
@property (nonatomic, strong) NSNumber *version;
/** Flag indicating whether to reset the database at startup. */
@property (nonatomic, assign) BOOL resetDatabase;
/** Database table schemas + initial data. */
@property (nonatomic, strong) NSDictionary *tables;

/** Begin a DB transaction. */
- (BOOL)beginTransaction;
/** Commit a DB transaction. */
- (BOOL)commitTransaction;
/** Rollback a DB transaction. */
- (BOOL)rollbackTransaction;
/** Get the name of the column with the specified tag from the named table. */
- (NSString *)getColumnWithTag:(NSString *)tag fromTable:(NSString *)table;
/** Get the record with the specified ID from the named table. */
- (NSDictionary *)readRecordWithID:(NSString *)identifier fromTable:(NSString *)table;
/** Perform a SQL query with the specified parameters. Returns the query result. */
- (NSArray *)performQuery:(NSString *)sql withParams:(NSArray *)params;
/** Perform an update on the database using the specified parameters. Returns YES if the update succeeded. */
- (BOOL)performUpdate:(NSString *)sql withParams:(NSArray *)params;
/** Insert a list of values into the named table. Each item of the list is inserted as a new record. Returns true if all records are inserted. */
- (BOOL)insertValueList:(NSArray *)valueList intoTable:(NSString *)table;
/** Insert values into the named table. Returns true if the record is inserted. */
- (BOOL)insertValues:(NSDictionary *)values intoTable:(NSString *)table;
/** Insert values into the named table. Returns true if the record is inserted. */
- (BOOL)insertValues:(NSDictionary *)values intoTable:(NSString *)table db:(id<PLDatabase>)db;
/** Update values in the table. Values must include a value for the ID column for the named table. Returns true if the record updated. */
- (BOOL)updateValues:(NSDictionary *)values inTable:(NSString *)table;
/** Merge a list of values into the named table. Records are inserted or updated as necessary. Returns true if all records were updated/inserted. */
- (BOOL)mergeValueList:(NSArray *)valueList intoTable:(NSString *)table;
/** Delete the identified records from the named table. */
- (BOOL)deleteIDs:(NSArray *)identifiers fromTable:(NSString *)table;
/**
 * Delete all records matching the specified where clause from the specified table.
 * Note: This is intended for use by the DB manifest processor as part of its garbage collection functionality,
 * so observers aren't notified after this operation - they will be notified after the following update.
 */
- (BOOL)deleteFromTable:(NSString *)table where:(NSString *)where;

@end
