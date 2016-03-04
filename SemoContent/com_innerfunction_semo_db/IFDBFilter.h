//
//  IFDBFilter.h
//  SemoContent
//
//  Created by Julian Goacher on 11/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFDB.h"

@interface IFDBFilter : NSObject {
    NSArray *_paramNames;
}

@property (nonatomic, strong) NSString *sql;
@property (nonatomic, strong) NSString *table;
@property (nonatomic, strong) NSDictionary *filters;
@property (nonatomic, strong) NSString *orderBy;
@property (nonatomic, strong) NSString *predicateOp;

- (NSArray *)applyTo:(IFDB *)db withParameters:(NSDictionary *)params;

@end
