//
//  UIWebView+WebViewAdditions.m
//  Foxbrowser
//
//  Created by simon on 03.07.12.
//  Copyright (c) 2012 Simon Grätzer. All rights reserved.
//

#import "UIWebView+WebViewAdditions.h"
#import "NSURL+IFUnicodeURL.h"
#import "UIImage+Scaling.h"
#import "SGDimensions.h"


@implementation UIWebView (WebViewAdditions)

// Filetypes supported by a webview
+ (NSArray *)fileTypes {
    return @[ @"xls", @"key.zip", @"numbers.zip", @"pdf", @"ppt", @"doc" ];
}

- (CGSize)windowSize
{
    CGSize size;
    size.width = [[self stringByEvaluatingJavaScriptFromString:@"window.innerWidth"] integerValue];
    size.height = [[self stringByEvaluatingJavaScriptFromString:@"window.innerHeight"] integerValue];
    return size;
}

- (CGPoint)scrollOffset
{
    CGPoint pt;
    pt.x = [[self stringByEvaluatingJavaScriptFromString:@"window.pageXOffset"] integerValue];
    pt.y = [[self stringByEvaluatingJavaScriptFromString:@"window.pageYOffset"] integerValue];
    return pt;
}

- (NSString *)title {
    NSString *htmlTitle = [self stringByEvaluatingJavaScriptFromString:@"document.title"];
    if (!htmlTitle.length) {
        htmlTitle = self.request.URL.absoluteString;
        NSString *ext = [htmlTitle pathExtension];
        if ([[UIWebView fileTypes] containsObject:ext]) {
            htmlTitle = [htmlTitle lastPathComponent];
        }
    }
    return htmlTitle;
}

- (NSString *)location {
    return [self stringByEvaluatingJavaScriptFromString:@"window.location.toString()"];;
}

- (void)setLocationHash:(NSString *)location {
    if (!location)
        location = @"";
    [self stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.location.hash = '%@'", location]];
}

- (void)clearContent {
    [self stringByEvaluatingJavaScriptFromString:@"document.documentElement.innerHTML = ''"];
}

- (void)disableContextMenu {
    [self stringByEvaluatingJavaScriptFromString:@"document.body.style.webkitTouchCallout='none';"];
}

#pragma mark - Screenshot stuff

- (UIImage *)screenshot {
    UIImage *viewImage = nil;
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, YES, 0.0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (self.layer && ctx) {
        [self.layer renderInContext:ctx];
        viewImage = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
    return viewImage;
}

- (void)saveScreenTo:(NSString *)path {
    UIImage *screen = [self screenshot];
    if (screen.size.height > screen.size.width) {
        screen = [screen cutImageToSize:CGSizeMake(screen.size.width, screen.size.height)];
    }
    
    screen = [screen scaleProportionalToSize:CGSizeMake(kSGPanelWidth, kSGPanelHeigth)];
    if (screen) {
        NSData *data = UIImagePNGRepresentation(screen);
        [data writeToFile:path atomically:NO];
#ifdef DEBUG
        NSLog(@"Write screenshot to: %@", path);
#endif
    }
}

+ (NSString *)screenshotPath {
    NSString* path = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
    return [path stringByAppendingPathComponent:@"Screenshots"];
}

+ (NSString *)pathForURL:(NSURL *)url {
    NSString* path = [self screenshotPath];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:NULL];
    }
    
    return [[path stringByAppendingPathComponent:url.host] stringByAppendingPathExtension:@"png"];
}

#pragma mark - Tag stuff

- (NSDictionary *)tagsForPosition:(CGPoint)pt {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"JSTools" ofType:@"js"];
    NSString *jsCode = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    [self stringByEvaluatingJavaScriptFromString:jsCode];
    
    // get the Tags at the touch location
    NSString *tagString = [self stringByEvaluatingJavaScriptFromString:
                      [NSString stringWithFormat:@"MyAppGetHTMLElementsAtPoint(%i,%i);",(NSInteger)pt.x,(NSInteger)pt.y]];
    
    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithCapacity:2];
    NSArray *tags = [tagString componentsSeparatedByString:@","];
    for (NSString *tag in tags) {
        NSRange start = [tag rangeOfString:@"["];
        if (start.location != NSNotFound) {
            NSString *tagname = [tag substringToIndex:start.location];
            NSRange end = [tag rangeOfString:@"]"];
            NSString *urlString = [tag substringWithRange:NSMakeRange(start.location + 1, end.location - start.location - 1)];
            [info setObject:urlString forKey:tagname];
        }
    }
    
    return info;
}

@end