//
//  TransformAssistant.h
//  TouchRoad
//
//  Created by t t on 11-4-6.
//  Copyright 2011 沈阳天择智能交通工程有限公司. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

#define DEGREE_OF_ORTHOGONAL_CORRECTION 0.1


typedef enum {
	TransformFlagNone		= 0, // 默认
	TransformFlagTranslate	= 1, // 平移
	TransformFlagZoom		= 2, // 缩放
	TransformFlagStick		= 4, // 旋转
	TransformFlagExclusive	= 8	 // 独占
}TransformFlag;

#pragma mark -
@interface TransformAssistant : NSObject{
#pragma mark -
}

+ (BOOL)isExlusiveTransformFlag:(TransformFlag)flag forTouches:(NSSet*)touches; // 在给定touches集合的情况下, 判断flag是否为独占的
+ (BOOL)isTranslateTransformFlag:(TransformFlag)flag forTouches:(NSSet*)touches; // 在给定touches集合的情况下, 判断flag是否为平移的
+ (BOOL)isZoomTransformFlag:(TransformFlag)flag forTouches:(NSSet*)touches; // 在给定touches集合的情况下, 判断flag是否为缩放的
+ (BOOL)isStickTransformFlag:(TransformFlag)flag forTouches:(NSSet*)touches; // 在给定touches集合的情况下, 判断flag是否为旋转的

+ (CGPoint)transformPoint:(CGPoint)p withTransform:(CATransform3D)t; // 给定点坐标和变换矩阵, 返回相乘后的点坐标


// 给定图符原有的transform、当前的touches集合、变换标志位和所在的视图，返回一个合适的增量transform, 
// 使得图符乘上返回的transform后，完成相应的图符变换操作
+ (CATransform3D)transformIncrementFrom:(CATransform3D)from touches:(NSSet*)touches flag:(TransformFlag)flag inView:(UIView*)view;


+ (CATransform3D)oneTouchTranslateIncrementForm:(CATransform3D)from touch:(UITouch*)touch inView:(UIView*)view; // 计算单指平移增量transform
+ (CATransform3D)twoTouchesTranslateIncrementForm:(CATransform3D)from touches:(NSSet*)touches inView:(UIView*)view; // 计算双指平移增量transform
+ (CATransform3D)twoTouchesZoomIncrementForm:(CATransform3D)from touches:(NSSet*)touches inView:(UIView*)view; // 计算双指缩放增量transform
+ (CATransform3D)twoTouchesStickIncrementForm:(CATransform3D)from touches:(NSSet*)touches inView:(UIView*)view; // 计算双指旋转增量transform
+ (CATransform3D)threeTouchesTranslateIncrementForm:(CATransform3D)from touches:(NSSet*)touches inView:(UIView*)view; // 计算三指平移增量transform
+ (CATransform3D)threeTouchesZoomIncrementForm:(CATransform3D)from touches:(NSSet*)touches inView:(UIView*)view; // 计算三指缩放增量transform
+ (CATransform3D)threeTouchesStickIncrementForm:(CATransform3D)from touches:(NSSet*)touches inView:(UIView*)view; // 计算三指旋转增量transform
+ (CATransform3D)transpose:(CATransform3D)t; // 转置矩阵
+ (CGRect)rectangleFromRectangle:(CGRect)oriRect transformedBy:(CATransform3D)t; // 计算一个矩形变换后的矩形
+ (CATransform3D)zoomTransforFromP0:(CGPoint)p0 p1:(CGPoint)p1 toP2:(CGPoint)p2 p3:(CGPoint)p3; // 给定原始两个点的位置(p0, p1)和现在两个点的位置(p2, p3), 计算相应的缩放变换矩阵
+ (CATransform3D)orthogonalCorrectionForTransform3D:(CATransform3D)from; // 为避免变换矩阵的误差累积, 进行矩阵的正交矫正
+ (CATransform3D)translationWithTransform3D:(CATransform3D)from; // 获取一个变换矩阵的平移部分
+ (CATransform3D)rotatelationWithTransform3D:(CATransform3D)from; // 获取一个变换矩阵的旋转部分
	
@end
