//
//  IFGetURLCommand.h
//  SemoContent
//
//  Created by Julian Goacher on 08/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFCommand.h"

/**
 * A command to get the contents of a URL and write it to a file.
 * Takes the arguments: <url> <filename> <retries>
 * - url:       The URL to fetch.
 * - filename:  The name of the file to write the result to.
 * - retries:   The number of retries left. If the command fails (e.g. due to a connection timeout)
 *              then it will automatically schedule a retry, up to a specified maximum number of retries.
 */
@interface IFGetURLCommand : NSObject <IFCommand, NSURLConnectionDataDelegate>  {
    QPromise *_promise;
    NSString *_url;
    NSString *_filename;
    NSInteger _remainingRetries;
    NSFileHandle *_fileHandle;
}

@property (nonatomic, assign) NSInteger maxRetries;

@end
