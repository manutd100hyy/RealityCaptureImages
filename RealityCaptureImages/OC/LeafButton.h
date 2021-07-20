//
//  LeafButton.h
//  LeafButton
//
//  Created by Wang on 14-7-16.
//  Copyright (c) 2014年 Wang. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef enum {
    LeafButtonTypeCamera,
    LeafButtonTypeVideo,
//    LeafButtonTypeRecord//录音
}LeafButtonType;
typedef enum {
    LeafButtonStateNormal,
    LeafButtonStateSelected
}LeafButtonState;
@class LeafButton;
typedef  void(^ClickedBlock)(LeafButton *button);
@interface LeafButton : UIView
@property (nonatomic,assign) LeafButtonType type;
@property (nonatomic,assign) LeafButtonState state;
@property (nonatomic,strong) void (^clickedBlock)(LeafButton *button);

CG_INLINE NSString* generateFilePath(NSString* filename, NSString* dirPath) {
    NSString* retFileName = nil;
    
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* docDirectory = [paths objectAtIndex:0];
    
    if (dirPath) {
        NSString *dataPath = [docDirectory stringByAppendingPathComponent:dirPath];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath])
            [[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:YES attributes:nil error:nil];
        
        retFileName = [dataPath stringByAppendingPathComponent:filename];
    }
    else {
        retFileName = [docDirectory stringByAppendingPathComponent:filename];
    }
    
    
    return retFileName;
}

CG_INLINE NSDictionary* getDictFromFile (NSString* targetFileName, NSString* dirPath) {
    NSArray* separateArray = [targetFileName componentsSeparatedByString:@"."];
    NSString* filename = [generateFilePath(targetFileName, dirPath) copy];
    NSString* preFileName = [separateArray objectAtIndex:0];
    NSString* nextFileName = [separateArray objectAtIndex:1];
    
    NSDictionary* dict = [NSDictionary dictionaryWithContentsOfFile:filename];
    filename = nil;
    
    if (dict == nil) {
        filename = [[[NSBundle mainBundle] pathForResource:preFileName ofType:nextFileName] copy];
        dict = [NSDictionary dictionaryWithContentsOfFile:filename];
        filename = nil;
    }
    
    return dict;
}

//删除指定路径的文件
CG_INLINE void deleteFileFromPath(NSString* filename, NSString* dirPath)
{
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* docDirectory = [paths objectAtIndex:0];
    
    NSString* fullPath = nil;
    if (dirPath) {
        NSString *dataPath = [docDirectory stringByAppendingPathComponent:dirPath];
        if ([[NSFileManager defaultManager] fileExistsAtPath:dataPath]) {
            fullPath = [dataPath stringByAppendingPathComponent:filename];
        }
    }
    else {
        fullPath = [docDirectory stringByAppendingPathComponent:filename];
    }

    if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath]) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager removeItemAtPath:fullPath error:NULL];
    }
    
}


@end
