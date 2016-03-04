//
//  IFWPDataWebviewFormatter.m
//  SemoContent
//
//  Created by Julian Goacher on 14/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import "IFWPDataWebviewFormatter.h"

@implementation IFWPDataWebviewFormatter

- (id)formatData:(id)data {
    // TODO: Should return a dictionary in format suitable for configuring a web view
    //return data;
    NSDictionary *_data = (NSDictionary *)data;
    return @{
        @"contentURL":  [_data valueForKey:@"contentURL"],
        // TODO: Should just modify wp: handler to return content instead of postHTML?
        // That way no filter is required.
        @"content":     [_data valueForKey:@"postHTML"]
    };
}

@end
