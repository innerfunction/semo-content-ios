//
//  IFRmFileCommand.h
//  SemoContent
//
//  Created by Julian Goacher on 08/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFCommand.h"

/**
 * Command to remove a file or directory from the local filesystem.
 * Arguments: <path>
 * - path:  Path to the file or directory to remove.
 */
@interface IFRmFileCommand : NSObject <IFCommand>

@end
