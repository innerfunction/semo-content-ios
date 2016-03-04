//
//  IFUnzipCommand.h
//  SemoContent
//
//  Created by Julian Goacher on 08/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFCommand.h"

/**
 * Command to unzip a zip archive.
 * Arguments: <zip> <to>
 * - zip:   The path to a zip archive file.
 * - to:    The path to a directory to unzip the archive's contents into.
 */
@interface IFUnzipCommand : NSObject <IFCommand>

@end
