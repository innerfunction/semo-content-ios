//
//  IFDB.m
//  SemoContent
//
//  Created by Julian Goacher on 07/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import "IFDB.h"
#import "IFSemoContent.h"
#import "NSDictionary+IFValues.h"
#import "NSDictionary+IF.h"
#import "NSArray+IF.h"

static IFLogger *Logger;

@interface IFDB ()

/** Read a record from the specified table. */
- (NSDictionary *)readRecordWithID:(NSString *)identifier fromTable:(NSString *)table db:(id<PLDatabase>)db;
/** Read a record from the specified table. */
- (NSDictionary *)readRecordWithID:(NSString *)identifier idColumn:(NSString *)idColumn fromTable:(NSString *)table db:(id<PLDatabase>)db;
/** Read a single row from a query result set. */
- (NSDictionary *)readRowFromResultSet:(id<PLResultSet>)rs;
/** Update multiple record with the specified values in a table. */
- (BOOL)updateValues:(NSDictionary *)values inTable:(NSString *)table db:(id<PLDatabase>)db;
/** Update multiple record with the specified values in a table. */
- (BOOL)updateValues:(NSDictionary *)values idColumn:(NSString *)idColumn inTable:(NSString *)table db:(id<PLDatabase>)db;
/** Delete records with the specified IDs from the a table. */
- (BOOL)deleteIDs:(NSArray *)identifiers idColumn:(NSString *)idColumn fromTable:(NSString *)table;

@end

@interface IFDB (IFDBHelperDelegate)

- (NSString *)getCreateTableSQLForTable:(NSString *)tableName schema:(NSDictionary *)tableSchema;
- (NSArray *)getAlterTableSQLForTable:(NSString *)tableName schema:(NSDictionary *)tableSchema from:(int)oldVersion to:(int)newVersion;
- (void)dbInitialize:(id<PLDatabase>)db;
- (void)addInitialDataForTable:(NSString *)tableName schema:(NSDictionary *)tableSchema;

@end

@implementation IFDB

+ (void)initialize {
    Logger = [[IFLogger alloc] initWithTag:@"IFDB"];
}

- (id)init {
    self = [super init];
    if (self) {
        self.name = @"semo";
        self.version = @0;
        self.tables = @{};
        self.resetDatabase = NO;
        _initialData = [[NSMutableDictionary alloc] init];
    }
    return self;
}

#pragma mark - IFService

- (void)startService {
    _dbHelper = [[IFDBHelper alloc] initWithName:_name version:[_version intValue]];
    _dbHelper.delegate = self;
    if (_resetDatabase) {
        [Logger warn:@"Resetting database %@", _name];
        [_dbHelper deleteDatabase];
    }
    [_dbHelper getDatabase];
}

#pragma mark - properties

- (void)setTables:(NSDictionary *)tables {
    _tables = tables;
    // Build lookup of table column tags.
    NSMutableDictionary *taggedTableColumns = [[NSMutableDictionary alloc] init];
    // Build lookup of table column names.
    NSMutableDictionary *tableColumnNames = [[NSMutableDictionary alloc] init];
    for (id tableName in [tables allKeys]) {
        NSDictionary *tableSchema = [tables objectForKey:tableName];
        NSMutableDictionary *columnTags = [[NSMutableDictionary alloc] init];
        NSMutableSet *columnNames = [[NSMutableSet alloc] init];
        NSDictionary *columns = [tableSchema objectForKey:@"columns"];
        for (id columnName in [columns allKeys]) {
            NSDictionary *columnSchema = [columns objectForKey:columnName];
            NSString *tag = [columnSchema getValueAsString:@"tag"];
            if (tag) {
                [columnTags setObject:columnName forKey:tag];
            }
            [columnNames addObject:columnName];
        }
        [taggedTableColumns setObject:columnTags forKey:tableName];
        [tableColumnNames setObject:columnNames forKey:tableName];
    }
    _taggedTableColumns = taggedTableColumns;
    _tableColumnNames = tableColumnNames;
}

#pragma mark - Public/private methods

- (BOOL)beginTransaction {
    NSError *error = nil;
    id<PLDatabase> db = [_dbHelper getDatabase];
    BOOL ok = [db beginTransactionAndReturnError:&error];
    if (error) {
        [Logger error:@"beginTranslation failed %@", error];
    }
    return ok;
}

- (BOOL)commitTransaction {
    NSError *error = nil;
    id<PLDatabase> db = [_dbHelper getDatabase];
    BOOL ok = [db commitTransactionAndReturnError:&error];
    if (error) {
        [Logger error:@"commitTransaction failed %@", error];
    }
    return ok;
}

- (BOOL)rollbackTransaction {
    NSError *error = nil;
    id<PLDatabase> db = [_dbHelper getDatabase];
    BOOL ok = [db rollbackTransactionAndReturnError:&error];
    if (error) {
        [Logger error:@"rollbackTransaction failed %@", error];
    }
    return ok;
}

- (NSString *)getColumnWithTag:(NSString *)tag fromTable:(NSString *)table {
    NSDictionary *columns = [_taggedTableColumns valueForKey:table];
    return [columns valueForKey:tag];
}

- (NSDictionary *)readRecordWithID:(NSString *)identifier fromTable:(NSString *)table {
    id<PLDatabase> db = [_dbHelper getDatabase];
    return [self readRecordWithID:identifier fromTable:table db:db];
}

- (NSDictionary *)readRecordWithID:(NSString *)identifier fromTable:(NSString *)table db:(id<PLDatabase>)db {
    NSDictionary *result = nil;
    NSString *idColumn = [self getColumnWithTag:@"id" fromTable:table];
    if (idColumn) {
        result = [self readRecordWithID:identifier idColumn:idColumn fromTable:table db:db];
    }
    else {
        [Logger warn:@"No ID column found for table %@", table];
    }
    return result;
}

- (NSDictionary *)readRecordWithID:(NSString *)identifier idColumn:(NSString *)idColumn fromTable:(NSString *)table db:(id<PLDatabase>)db {
    NSDictionary *result = nil;
    if (identifier) {
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@=?", table, idColumn];
        NSArray *params = @[ identifier ];
        id<PLPreparedStatement> statement = [db prepareStatement:sql];
        [statement bindParameters:params];
        id<PLResultSet> rs = [statement executeQuery];
        if ([rs next]) {
            result = [self readRowFromResultSet:rs];
        }
        [rs close];
        [statement close];
    }
    else {
        [Logger warn:@"No identifier passed to readRecordWithID:"];
    }
    return result;
}

- (NSArray *)performQuery:(NSString *)sql withParams:(NSArray *)params {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    id<PLDatabase> db = [_dbHelper getDatabase];
    id<PLPreparedStatement> statement = [db prepareStatement:sql];
    [statement bindParameters:params];
    id<PLResultSet> rs = [statement executeQuery];
    while ([rs next]) {
        [result addObject:[self readRowFromResultSet:rs]];
    }
    [rs close];
    [statement close];
    return result;
}

- (BOOL)performUpdate:(NSString *)sql withParams:(NSArray *)params {
    id<PLDatabase> db = [_dbHelper getDatabase];
    id<PLPreparedStatement> statement = [db prepareStatement:sql];
    [statement bindParameters:params];
    BOOL result = [statement executeUpdate];
    [statement close];
    return result;
}

- (NSInteger)countInTable:(NSString *)table where:(NSString *)where {
    NSInteger count = 0;
    NSString *sql = [NSString stringWithFormat:@"SELECT count(*) AS count FROM %@ WHERE %@", table, where];
    NSArray *result = [self performQuery:sql withParams:@[]];
    if ([result count] > 0) {
        NSDictionary *record = [result objectAtIndex:0];
        count = [(NSNumber *)[record objectForKey:@"count"] integerValue];
    }
    return count;
}

- (NSDictionary *)readRowFromResultSet:(id<PLResultSet>)rs {
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    int colCount = [rs getColumnCount];
    for (int i = 0; i < colCount; i++) {
        if (![rs isNullForColumnIndex:i]) {
            NSString *name = [rs nameForColumnIndex:i];
            id value = [rs objectForColumnIndex:i];
            [result setObject:value forKey:name];
        }
    }
    return result;
}

- (BOOL)insertValueList:(NSArray *)valueList intoTable:(NSString *)table {
    id<PLDatabase> db = [_dbHelper getDatabase];
    BOOL result = YES;
    [self willChangeValueForKey:table];
    for (NSDictionary *values in valueList) {
        result &= [self insertValues:values intoTable:table db:db];
    }
    [self didChangeValueForKey:table];
    return result;
}

- (BOOL)insertValues:(NSDictionary *)values intoTable:(NSString *)table {
    id<PLDatabase> db = [_dbHelper getDatabase];
    [self willChangeValueForKey:table];
    BOOL result = [self insertValues:values intoTable:table db:db];
    [self didChangeValueForKey:table];
    return result;
}

- (BOOL)insertValues:(NSDictionary *)values intoTable:(NSString *)table db:(id<PLDatabase>)db {
    BOOL result = YES;
    values = [self filterValues:values forTable:table];
    NSArray *keys = [NSArray arrayWithDictionaryKeys:values];
    if ([keys count] > 0) {
        NSArray *params = [NSArray arrayWithItem:@"?" repeated:[keys count]];
        NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES (%@)", table, [keys joinWithSeparator:@","], [params joinWithSeparator:@","]];
        id<PLPreparedStatement> statement = [db prepareStatement:sql];
        [statement bindParameters:[NSArray arrayWithDictionaryValues:values forKeys:keys]];
        result = [statement executeUpdate];
        [statement close];
    }
    return result;
}

- (BOOL)updateValues:(NSDictionary *)values inTable:(NSString *)table {
    id<PLDatabase> db = [_dbHelper getDatabase];
    [self willChangeValueForKey:table];
    BOOL result = [self updateValues:values inTable:table db:db];
    if (result) {
        [self didChangeValueForKey:table];
    }
    else {
        NSString *idColumn = [self getColumnWithTag:@"id" fromTable:table];
        id identifier = [values valueForKey:idColumn];
        [Logger warn:@"Update failed %@ %@", table, identifier];
    }
    return result;
}

- (BOOL)updateValues:(NSDictionary *)values inTable:(NSString *)table db:(id<PLDatabase>)db {
    BOOL result = NO;
    NSString *idColumn = [self getColumnWithTag:@"id" fromTable:table];
    if (idColumn) {
        result = [self updateValues:values idColumn:idColumn inTable:table db:db];
    }
    else {
        [Logger warn:@"No ID column found for table %@", table];
    }
    return result;
}

- (BOOL)updateValues:(NSDictionary *)values idColumn:(NSString *)idColumn inTable:(NSString *)table db:(id<PLDatabase>)db {
    values = [self filterValues:values forTable:table];
    NSArray *keys = [NSArray arrayWithDictionaryKeys:values];
    NSMutableArray *fields = [[NSMutableArray alloc] initWithCapacity:[keys count]];
    NSMutableArray *params = [[NSMutableArray alloc] initWithCapacity:[keys count] + 1];
    for (id key in keys) {
        [fields addObject:[NSString stringWithFormat:@"%@=?", key]];
        [params addObject:[values valueForKey:key]];
    }
    id identifier = [values valueForKey:idColumn];
    [params addObject:identifier];
    NSString *sql = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE %@=?", table, [fields joinWithSeparator:@","], idColumn ];
    id<PLPreparedStatement> statement = [db prepareStatement:sql];
    [statement bindParameters:params];
    BOOL result = [statement executeUpdate];
    [statement close];
    return result;
}

- (BOOL)mergeValueList:(NSArray *)valueList intoTable:(NSString *)table {
    BOOL result = YES;
    NSString *idColumn = [self getColumnWithTag:@"id" fromTable:table];
    if (idColumn) {
        id<PLDatabase> db = [_dbHelper getDatabase];
        [self willChangeValueForKey:table];
        for (NSDictionary *values in valueList) {
            id identifier = [values valueForKey:idColumn];
            NSDictionary *record = [self readRecordWithID:identifier fromTable:table];
            if (record) {
                record = [record extendWith:values];
                result &= [self updateValues:record idColumn:idColumn inTable:table db:db];
            }
            else {
                result &= [self insertValues:values intoTable:table db:db];
            }
        }
        [self didChangeValueForKey:table];
    }
    else {
        [Logger warn:@"No ID column found for table", table];
    }
    return result;
}

- (BOOL)deleteIDs:(NSArray *)identifiers fromTable:(NSString *)table {
    BOOL result = NO;
    NSString *idColumn = [self getColumnWithTag:@"id" fromTable:table];
    if (idColumn) {
        result = [self deleteIDs:identifiers idColumn:idColumn fromTable:table];
    }
    else {
        [Logger warn:@"No ID column found for table %@", table];
    }
    return result;
}

- (BOOL)deleteIDs:(NSArray *)identifiers idColumn:(NSString *)idColumn fromTable:(NSString *)table {
    BOOL result = NO;
    if ([identifiers count]) {
        id<PLDatabase> db = [_dbHelper getDatabase];
        [self willChangeValueForKey:table];
        NSArray *params = [NSArray arrayWithItem:@"?" repeated:[identifiers count]];
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ IN (%@)", table, idColumn, [params joinWithSeparator:@","]];
        id<PLPreparedStatement> statement = [db prepareStatement:sql];
        [statement bindParameters:identifiers];
        result = [statement executeUpdate];
        [statement close];
        [self didChangeValueForKey:table];
    }
    return result;
}

- (BOOL)deleteFromTable:(NSString *)table where:(NSString *)where {
    id<PLDatabase> db = [_dbHelper getDatabase];
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@", table, where];
    return [db executeUpdate:sql];
}

- (NSDictionary *)filterValues:(NSDictionary *)values forTable:(NSString *)table {
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    NSSet *columnNames = [_tableColumnNames objectForKey:table];
    if (columnNames) {
        for (id name in [values keyEnumerator]) {
            if ([columnNames containsObject:name]) {
                [result setObject:[values objectForKey:name] forKey:name];
            }
        }
    }
    return result;
}

#pragma mark - IFDBHelperDelegate

- (void)onCreate:(id<PLDatabase>)db {
    for (NSString *tableName in [_tables allKeys]) {
        NSDictionary *tableSchema = [_tables objectForKey:tableName];
        NSString *sql = [self getCreateTableSQLForTable:tableName schema:tableSchema];
        [db executeUpdate:sql];
        [self addInitialDataForTable:tableName schema:tableSchema];
    }
    [self dbInitialize:db];
}

- (void)onUpgrade:(id<PLDatabase>)db from:(int)oldVersion to:(int)newVersion {
    [Logger info:@"Migrating DB from version %d to version %d", oldVersion, newVersion];
    NSNumber *_newVersion = [NSNumber numberWithInt:newVersion];
    for (NSString *tableName in [_tables allKeys]) {
        NSDictionary *tableSchema = [_tables objectForKey:tableName];
        NSInteger since = [[tableSchema getValueAsNumber:@"since" defaultValue:@0] integerValue];
        NSInteger until = [[tableSchema getValueAsNumber:@"until" defaultValue:_newVersion] integerValue];
        NSArray *sqls = nil;
        if (since < (NSInteger)oldVersion) {
            // Table exists since before the current DB version, so should exist in the current DB.
            if (until < (NSInteger)newVersion) {
                // Table not required in DB version being migrated to, so drop from database.
                NSString *sql = [NSString stringWithFormat:@"DROP TABLE %@ IF EXISTS", tableName];
                sqls = [NSArray arrayWithObject:sql];
            }
            else {
                // Modify table.
                sqls = [self getAlterTableSQLForTable:tableName schema:tableSchema from:oldVersion to:newVersion];
            }
        }
        else {
            // => since > oldVersion
            // Table shouldn't exist in the current database.
            if (until < (NSInteger)newVersion) {
                // Table not required in version being migrated to, so no action required.
                continue;
            }
            else {
                // Create table.
                sqls = [NSArray arrayWithObject:[self getCreateTableSQLForTable:tableName schema:tableSchema]];
                [self addInitialDataForTable:tableName schema:tableSchema];
            }
        }
        for (NSString *sql in sqls) {
            if (![db executeUpdate:sql]) {
                [Logger warn:@"%@ Failed to execute update %@", sql];
            }
        }
    }
    [self dbInitialize:db];
}

#pragma mark - IFDB (IFDBHelperDelegate)

- (void)dbInitialize:(id<PLDatabase>)db {
    [Logger info:@"%@ Initializing database..."];
    for (NSString *tableName in [_initialData allKeys]) {
        NSArray *data = [_initialData objectForKey:tableName];
        for (NSDictionary *values in data) {
            [self insertValues:values intoTable:tableName db:db];
        }
        id<PLResultSet> rs = [db executeQuery:[NSString stringWithFormat:@"select count() from %@", tableName]];
        int32_t count = 0;
        if ([rs next]) {
            count = [rs intForColumnIndex:0];
        }
        [rs close];
        [Logger info:@"%@ Initializing %@, inserted %d rows", tableName, count];
    }
    // Remove initial data from memory.
    _initialData = nil;
}

- (void)addInitialDataForTable:(NSString *)tableName schema:(NSDictionary *)tableSchema {
    if ([tableSchema getValueType:@"data"] == IFValueTypeList) {
        [_initialData setObject:[tableSchema objectForKey:@"data"] forKey:tableName];
    }
}

- (NSString *)getCreateTableSQLForTable:(NSString *)tableName schema:(NSDictionary *)tableSchema {
    NSMutableString *cols = [[NSMutableString alloc] init];
    NSDictionary *columns = [tableSchema valueForKey:@"columns"];
    for (NSString *colName in [columns allKeys]) {
        NSDictionary *colSchema = [columns objectForKey:colName];
        if ([cols length] > 0) {
            [cols appendString:@","];
        }
        [cols appendString:colName];
        [cols appendString:@" "];
        [cols appendString:[colSchema getValueAsString:@"type"]];
    }
    NSString *sql = [NSString stringWithFormat:@"CREATE TABLE %@ (%@)", tableName, cols ];
    return sql;
}

- (NSArray *)getAlterTableSQLForTable:(NSString *)tableName schema:(NSDictionary *)tableSchema from:(int)oldVersion to:(int)newVersion {
    NSNumber *_newVersion = [NSNumber numberWithInt:newVersion];
    NSMutableArray *sqls = [[NSMutableArray alloc] init];
    NSDictionary *columns = [tableSchema valueForKey:@"columns"];
    for (NSString *colName in [columns allKeys]) {
        NSDictionary *colSchema = [columns objectForKey:colName];
        NSInteger since = [[colSchema getValueAsNumber:@"since" defaultValue:@0] integerValue];
        NSInteger until = [[colSchema getValueAsNumber:@"until" defaultValue:_newVersion] integerValue];
        // If a column has been added since the current db version, and not disabled before the
        // version being migrated to, then alter the table schema to include the table.
        if (since > oldVersion && !(until < newVersion)) {
            NSString *type = [colSchema getValueAsString:@"type"];
            NSString *sql = [NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ %@", tableName, colName, type ];
            [sqls addObject:sql];
        }
    }
    return sqls;
}

@end
