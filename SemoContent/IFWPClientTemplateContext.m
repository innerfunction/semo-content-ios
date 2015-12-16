//
//  IFWPClientTemplateContext.m
//  SemoContent
//
//  Created by Julian Goacher on 15/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import "IFWPClientTemplateContext.h"
#import "NSString+IF.h"

@implementation IFWPClientTemplateContext

- (id)initWithParent:(IFWPSchemeHandler *)parent {
    self = [super init];
    if (self) {
        _parent = parent;
        _fileManager = [NSFileManager defaultManager];
    }
    return self;
}

- (id)valueForKeyPath:(NSString *)keyPath {
    NSArray *pathComponents = [keyPath split:@"."];
    if ([pathComponents count] == 2 && [@"attachment" isEqualToString:[pathComponents objectAtIndex:0]]) {
        // The template placeholder is in the form {attachment.x}, where 'x' is an attachment post ID.
        // Read the attachment data from the posts DB and base on its 'location' value, return one of
        // the following:
        // * packaged:   Attachment file is packaged with the app; return file: URL pointing at the
        //               file under the packaged content path.
        // * downloaded: Attachment file has been downloaded from the server; return a file: URL
        //               pointing at the file under the content path.
        // * server:     Attachment file hasn't been downloaded and is still on the server; return its
        //               server URL.
        NSString *attachmentID = [pathComponents objectAtIndex:1];
        NSDictionary *attachment = [_parent.postDB readRecordWithID:attachmentID fromTable:@"posts"];
        NSString *location = [attachment valueForKey:@"location"];
        NSString *filename = [attachment valueForKey:@"filename"];
        NSString *url = [attachment valueForKey:@"url"];
        if ([@"packaged" isEqualToString:location]) {
            NSString *path = [_parent.packagedContentPath stringByAppendingPathComponent:filename];
            url = [NSString stringWithFormat:@"file://%@", path];
        }
        else if ([@"downloaded" isEqualToString:location]) {
            NSString *path = [_parent.contentPath stringByAppendingPathComponent:filename];
            if ([_fileManager fileExistsAtPath:path]) {
                url = [NSString stringWithFormat:@"file://%@", path];
            }
            else {
                // File probably removed by system to free disk space. The attachment URL will be
                // returned instead, meaning that the webview can attempt to download the file from
                // the server if a connection is available.
                // TODO: Start a download of the file through the content protocol. Note that if
                // the webview was able to download the file then the protocol should be able to
                // load from the cache.
            }
        }
        // Else location == 'server' or other. Use the attachment URL to download from server.
        return url;
    }
    return [super valueForKeyPath:keyPath];
}

@end
