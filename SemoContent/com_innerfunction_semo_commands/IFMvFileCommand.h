//
//  IFMvFileCommand.h
//  SemoContent
//
//  Created by Julian Goacher on 08/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFCommand.h"

/**
 * Command to move a file or directory on the local filesystem to another location.
 * Arguments: <from> <to>
 * - from:  The file path to move.
 * - to:    Where to move the file or directory to.
 */
@interface IFMvFileCommand : NSObject <IFCommand> {
    NSFileManager *_fileManager;
}

@end
