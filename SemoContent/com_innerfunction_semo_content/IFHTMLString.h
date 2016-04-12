//
//  IFHTMLString.h
//  SemoContent
//
//  Created by Julian Goacher on 12/04/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IFHTMLString : NSObject <NSXMLParserDelegate> {
    NSString *_htmlString;
    NSMutableAttributedString *_attrString;
    NSMutableString *_string;
    NSDictionary *_style;
    NSDictionary *_tagHandlers;
    NSMutableArray *_styleStack;
}

@property (nonatomic, assign) BOOL inlineParagraphs;
@property (nonatomic, assign) CGFloat fontSize;
@property (nonatomic, strong) UIColor *fontColor;

- (id)initWithString:(NSString *)string;
- (void)parse;
- (NSAttributedString *)asAttributedString;
- (NSString *)asString;

@end
