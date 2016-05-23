//
//  IFDBFilter.m
//  SemoContent
//
//  Created by Julian Goacher on 11/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import "IFDBFilter.h"
#import "IFRegExp.h"
#import "NSString+IF.h"

@implementation IFDBFilter

- (id)init {
    self = [super init];
    if (self) {
        _predicateOp = @"AND";
    }
    return self;
}

- (void)setSql:(NSString *)sql {
    // Extract parameter names from the SQL string. Parameter names appear as ?xxx in the SQL.
    NSMutableArray *paramNames = [[NSMutableArray alloc] init];
    IFRegExp *re = [[IFRegExp alloc] initWithPattern:@"\\?(\\w+)(.*)"];
    NSArray *groups = [re match:sql];
    while ([groups count]) {
        [paramNames addObject:[groups objectAtIndex:1]];
        groups = [re match:[groups objectAtIndex:2]];
    }
    _paramNames = paramNames;
    // Replace all argument placeholders with just '?' in the SQL.
    _sql = [sql replaceAllOccurrences:@"\\?\\w+" with:@"?"];
}

- (NSArray *)applyTo:(IFDB *)db withParameters:(NSDictionary *)params {
    // Prepare the SQL. If the filter has been configured using table/filters/orderBy properties then
    // _sql won't be set on first call.
    if (!_sql && _table) {
        NSMutableArray *terms = [[NSMutableArray alloc] init];
        [terms addObject:@"SELECT * FROM"];
        [terms addObject:_table];
        if (_filters) {
            [terms addObject:@"WHERE"];
            // Regex pattern for detecting filter values that contain a predicate.
            IFRegExp *predicatePattern = [[IFRegExp alloc] initWithPattern:@"^\\s*(=|<|>|LIKE\\s|NOT\\s)"];
            BOOL insertPredicateOp = NO;
            for (NSString *filterName in [_filters keyEnumerator]) {
                if (insertPredicateOp) {
                    [terms addObject:_predicateOp];
                }
                [terms addObject:filterName];
                id filterValue = [_filters valueForKey:filterName];
                if ([filterValue isKindOfClass:[NSArray class]]) {
                    // Use a WHERE ... IN (...) to query for an array of values.
                    filterValue = [(NSArray *)filterValue componentsJoinedByString:@","];
                    [terms addObject:[NSString stringWithFormat:@"IN (%@)", filterValue]];
                }
                else {
                    // Convert a non-string filter value to a string.
                    if (![filterValue isKindOfClass:[NSString class]]) {
                        filterValue = [filterValue description];
                    }
                    if ([predicatePattern matches:filterValue]) {
                        [terms addObject:filterValue];
                    }
                    else if ([filterValue hasPrefix:@"?"]) {
                        // ? prefix indicates a parameterized value; don't quote in the SQL.
                        [terms addObject:[NSString stringWithFormat:@"= %@", filterValue]];
                    }
                    else {
                        // Escape single quotes in the value.
                        filterValue = [filterValue replaceAllOccurrences:@"'" with:@"\\'"];
                        [terms addObject:[NSString stringWithFormat:@"= '%@'", filterValue]];
                    }
                }
                insertPredicateOp = YES;
            }
        }
        if (_orderBy) {
            [terms addObject:@"ORDER BY"];
            [terms addObject:_orderBy];
        }
        self.sql = [terms componentsJoinedByString:@" "];
    }
    // If still no SQL then the filter hasn't been configured correctly.
    if (!_sql) {
        return @[];
    }
    // Construct parameters for the SQL query.
    NSMutableArray *sqlParams = [[NSMutableArray alloc] init];
    for (NSString *paramName in _paramNames) {
        id value = [params valueForKey:paramName];
        if (value != nil) {
            [sqlParams addObject:value];
        }
        else {
            [sqlParams addObject:[NSNull null]];
        }
    }
    // Execute the SQL and return the result.
    NSArray *result = [db performQuery:_sql withParams:sqlParams];
    return result;
}

@end
