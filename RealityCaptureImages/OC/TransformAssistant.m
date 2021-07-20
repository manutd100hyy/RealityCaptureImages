//
//  TransformAssistant.m
//  TouchRoad
//
//  Created by t t on 11-4-6.
//  Copyright 2011 沈阳天择智能交通工程有限公司. All rights reserved.
//

#import "TransformAssistant.h"

#pragma mark -
@implementation TransformAssistant
#pragma mark -


#pragma mark Class Methods

+ (BOOL)isExlusiveTransformFlag:(TransformFlag)flag forTouches:(NSSet*)touches{
	flag = flag >> (touches.count * 4);
	return flag & TransformFlagExclusive;
}
+ (BOOL)isTranslateTransformFlag:(TransformFlag)flag forTouches:(NSSet*)touches{
	flag = flag >> (touches.count * 4);
	
	return flag & TransformFlagTranslate;
}
+ (BOOL)isZoomTransformFlag:(TransformFlag)flag forTouches:(NSSet*)touches{
	flag = flag >> (touches.count * 4);
	
	return flag & TransformFlagZoom;
}
+ (BOOL)isStickTransformFlag:(TransformFlag)flag forTouches:(NSSet*)touches{
	flag = flag >> (touches.count * 4);
	
	return flag & TransformFlagStick;
}

+ (CGPoint)transformPoint:(CGPoint)p withTransform:(CATransform3D)t{
	return CGPointApplyAffineTransform(p, CATransform3DGetAffineTransform(t));
}
+ (CATransform3D)transformIncrementFrom:(CATransform3D)from touches:(NSSet*)touches flag:(TransformFlag)flag inView:(UIView*)view{
	
	CATransform3D inc = CATransform3DIdentity;
	
	switch (touches.count) {
		case 1:
			if ([TransformAssistant isTranslateTransformFlag:flag forTouches:touches]) {
				inc = [TransformAssistant oneTouchTranslateIncrementForm:from touch:[touches anyObject] inView:view];
			}
			break;
		case 2:
			if ([TransformAssistant isTranslateTransformFlag:flag forTouches:touches]) {
				inc = [TransformAssistant twoTouchesTranslateIncrementForm:from touches:touches inView:view];
			}
			else if ([TransformAssistant isZoomTransformFlag:flag forTouches:touches]) {
				inc = [TransformAssistant twoTouchesZoomIncrementForm:from touches:touches inView:view];
			}
			else if ([TransformAssistant isStickTransformFlag:flag forTouches:touches]) {
				inc = [TransformAssistant twoTouchesStickIncrementForm:from touches:touches inView:view];
			}
			break;
		case 3:
			if ([TransformAssistant isTranslateTransformFlag:flag forTouches:touches]) {
				inc = [TransformAssistant threeTouchesTranslateIncrementForm:from touches:touches inView:view];
			}
			else if ([TransformAssistant isZoomTransformFlag:flag forTouches:touches]) {
				inc = [TransformAssistant threeTouchesZoomIncrementForm:from touches:touches inView:view];
			}
			else if ([TransformAssistant isStickTransformFlag:flag forTouches:touches]) {
				inc = [TransformAssistant threeTouchesStickIncrementForm:from touches:touches inView:view];
			}
			
			break;
		default:
			break;
	}
	
	return inc;
	
}
+ (CATransform3D)oneTouchTranslateIncrementForm:(CATransform3D)from touch:(UITouch*)touch inView:(UIView*)view{
	CGPoint p0 = [TransformAssistant transformPoint:[touch previousLocationInView:view] withTransform:CATransform3DInvert(from)];
	CGPoint p1 = [TransformAssistant transformPoint:[touch locationInView:view] withTransform:CATransform3DInvert(from)];
	
	return CATransform3DMakeTranslation(p1.x - p0.x, p1.y - p0.y, 0);
}
+ (CATransform3D)twoTouchesTranslateIncrementForm:(CATransform3D)from touches:(NSSet*)touches inView:(UIView*)view{
	return CATransform3DIdentity; 
}

/*
 p0 * M' = p1;
 p2 * M' = p3;
 
 M' =	[s 0 0 0
		 0 s 0 0
		 0 0 1 0
		 a b 0 1];

 [p0x 1 0			[s			[p1x
  p0y 0 1			 a			 p1y
  p2x 1 0      *	 b]  =		 p3x
  p2y 0 1]						 p3y];
 
 Ax = b;
 x = A+ * b;
 x = [inv(A.' * A) * A.'] * b;
 */
+ (CATransform3D)twoTouchesZoomIncrementForm:(CATransform3D)from touches:(NSSet*)touches inView:(UIView*)view{
	CGPoint p[4];
	NSInteger i = 0;
	for (UITouch* touch in touches) {
		p[i++] = [TransformAssistant transformPoint:[touch previousLocationInView:view] withTransform:CATransform3DInvert(from)];
		p[i++] = [TransformAssistant transformPoint:[touch locationInView:view] withTransform:CATransform3DInvert(from)];
	}
	
	CATransform3D A;
	A.m11 = p[0].x; A.m12 = 1; A.m13 = 0; A.m14 = 0;
	A.m21 = p[0].y; A.m22 = 0; A.m23 = 1; A.m24 = 0;
	A.m31 = p[2].x; A.m32 = 1; A.m33 = 0; A.m34 = 0;
	A.m41 = p[2].y; A.m42 = 0; A.m43 = 1; A.m44 = 0;
	
	CATransform3D M = CATransform3DConcat([TransformAssistant transpose:A], A);
	M.m44 = 1;
	M = CATransform3DInvert(M);
	CATransform3D Aplus = CATransform3DConcat(M, [TransformAssistant transpose:A]);
	
	CATransform3D t = CATransform3DIdentity;	
	
	t.m11 = t.m22 = Aplus.m11 * p[1].x + Aplus.m12 * p[1].y + Aplus.m13 * p[3].x + Aplus.m14 * p[3].y;
	t.m41 = Aplus.m21 * p[1].x + Aplus.m22 * p[1].y + Aplus.m23 * p[3].x + Aplus.m24 * p[3].y;
	t.m42 = Aplus.m31 * p[1].x + Aplus.m32 * p[1].y + Aplus.m33 * p[3].x + Aplus.m34 * p[3].y;
	
	
	return t;
}

/*
 p0 * M' = p1;
 p2 * M' = p3;
 
 M' =	[ u v 0 0
		 -v u 0 0
		  0 0 1 0	
		  a b 0 1];
 
 [p0x -p0y 1 0			[u			[p1x
  p0y  p0x 0 1			 v			 p1y
  p2x -p2y 1 0      *	 a  =		 p3x
  p2y  p2x 0 1]			 b]			 p3y];
 
 Ax = b;
 x = inv(A) * b;
 
 len = sqrt(u * u + v * v);
 u /= len;
 v /= len;
 
 */

+ (CATransform3D)twoTouchesStickIncrementForm:(CATransform3D)from touches:(NSSet*)touches inView:(UIView*)view{
	CGPoint p[4];
	NSInteger i = 0;
	for (UITouch* touch in touches) {
		p[i++] = [TransformAssistant transformPoint:[touch previousLocationInView:view] withTransform:CATransform3DInvert(from)];
		p[i++] = [TransformAssistant transformPoint:[touch locationInView:view] withTransform:CATransform3DInvert(from)];
	}
	
	CATransform3D A;
	A.m11 = p[0].x; A.m12 = p[0].y; A.m13 = 1; A.m14 = 0;
	A.m21 = p[0].y; A.m22 = -p[0].x; A.m23 = 0; A.m24 = 1;
	A.m31 = p[2].x; A.m32 = p[2].y; A.m33 = 1; A.m34 = 0;
	A.m41 = p[2].y; A.m42 = -p[2].x; A.m43 = 0; A.m44 = 1;
	
	CATransform3D M = CATransform3DInvert(A);
	CGFloat u = M.m11 * p[1].x + M.m12 * p[1].y + M.m13 * p[3].x + M.m14 * p[3].y;
	CGFloat v = M.m21 * p[1].x + M.m22 * p[1].y + M.m23 * p[3].x + M.m24 * p[3].y;
	CGFloat a = M.m31 * p[1].x + M.m32 * p[1].y + M.m33 * p[3].x + M.m34 * p[3].y;
	CGFloat b = M.m41 * p[1].x + M.m42 * p[1].y + M.m43 * p[3].x + M.m44 * p[3].y;
	
	// for not scale
	CGFloat len = sqrtf(u * u + v * v);
	u /= len;
	v /= len;
	
	CATransform3D t = CATransform3DIdentity;
	t.m11 = u; t.m12 = -v;
	t.m21 = v; t.m22 = u;
	t.m41 = a; t.m42 = b;
	
	
	return t; 
}
+ (CATransform3D)threeTouchesTranslateIncrementForm:(CATransform3D)from touches:(NSSet*)touches inView:(UIView*)view{ return CATransform3DIdentity; }
+ (CATransform3D)threeTouchesZoomIncrementForm:(CATransform3D)from touches:(NSSet*)touches inView:(UIView*)view{ return CATransform3DIdentity; }
+ (CATransform3D)threeTouchesStickIncrementForm:(CATransform3D)from touches:(NSSet*)touches inView:(UIView*)view{ return CATransform3DIdentity; }
+ (CATransform3D)transpose:(CATransform3D)t{
	CATransform3D u = t;
	u.m12 = t.m21; u.m13 = t.m31; u.m14 = t.m41;
	u.m21 = t.m12; u.m23 = t.m32; u.m24 = t.m42;
	u.m31 = t.m13; u.m32 = t.m23; u.m34 = t.m43;
	u.m41 = t.m14; u.m42 = t.m24; u.m43 = t.m34;
	
	return u;
}


+ (CGRect)rectangleFromRectangle:(CGRect)oriRect transformedBy:(CATransform3D)t{
	
	CGFloat minX = FLT_MAX;
	CGFloat minY = FLT_MAX;
	CGFloat maxX = -FLT_MAX;
	CGFloat maxY = -FLT_MAX;
	
	CGPoint p;
	
	p = CGPointMake(CGRectGetMinX(oriRect), CGRectGetMinY(oriRect));
	p = [TransformAssistant transformPoint:p withTransform:t];
	if (minX > p.x) { minX = p.x; }
	if (minY > p.y) { minY = p.y; }
	if (maxX < p.x) { maxX = p.x; }
	if (maxY < p.y) { maxY = p.y; }
	
	p = CGPointMake(CGRectGetMinX(oriRect), CGRectGetMaxY(oriRect));
	p = [TransformAssistant transformPoint:p withTransform:t];
	if (minX > p.x) { minX = p.x; }
	if (minY > p.y) { minY = p.y; }
	if (maxX < p.x) { maxX = p.x; }
	if (maxY < p.y) { maxY = p.y; }
	
	p = CGPointMake(CGRectGetMaxX(oriRect), CGRectGetMinY(oriRect));
	p = [TransformAssistant transformPoint:p withTransform:t];
	if (minX > p.x) { minX = p.x; }
	if (minY > p.y) { minY = p.y; }
	if (maxX < p.x) { maxX = p.x; }
	if (maxY < p.y) { maxY = p.y; }
	
	p = CGPointMake(CGRectGetMaxX(oriRect), CGRectGetMaxY(oriRect));
	p = [TransformAssistant transformPoint:p withTransform:t];
	if (minX > p.x) { minX = p.x; }
	if (minY > p.y) { minY = p.y; }
	if (maxX < p.x) { maxX = p.x; }
	if (maxY < p.y) { maxY = p.y; }
	
	
	return CGRectMake(minX, minY, maxX - minX, maxY - minY);
}
+ (CATransform3D)zoomTransforFromP0:(CGPoint)p0 p1:(CGPoint)p1 toP2:(CGPoint)p2 p3:(CGPoint)p3{
	CATransform3D A;
	A.m11 = p0.x; A.m12 = 1; A.m13 = 0; A.m14 = 0; A.m21 = p0.y; A.m22 = 0; A.m23 = 1; A.m24 = 0;
	A.m31 = p2.x; A.m32 = 1; A.m33 = 0; A.m34 = 0; A.m41 = p2.y; A.m42 = 0; A.m43 = 1; A.m44 = 0;
	
	CATransform3D M = CATransform3DConcat([TransformAssistant transpose:A], A);
	M.m44 = 1;
	M = CATransform3DInvert(M);
	A = CATransform3DConcat(M, [TransformAssistant transpose:A]);
	
	
	CATransform3D t = CATransform3DIdentity;
	
	t.m11 = t.m22 = A.m11 * p1.x + A.m12 * p1.y + A.m13 * p3.x + A.m14 * p3.y;
	t.m41 = A.m21 * p1.x + A.m22 * p1.y + A.m23 * p3.x + A.m24 * p3.y;
	t.m42 = A.m31 * p1.x + A.m32 * p1.y + A.m33 * p3.x + A.m34 * p3.y;
	
	return t;
	
	
}
+ (CATransform3D)orthogonalCorrectionForTransform3D:(CATransform3D)from{
	
	CATransform3D t = CATransform3DIdentity;
	
	CGFloat sb, cb;
	CGFloat b[4][2] = {{1, 0}, {0, 1}, {-1, 0}, {0, -1}};
		
	for (NSInteger i = 0; i < 4; i++) {
		
		cb = b[i][0] * from.m11 + b[i][1] * from.m12;
		sb = b[i][1] * from.m11 - b[i][0] * from.m12;
		
		if (fabsf(sb) < DEGREE_OF_ORTHOGONAL_CORRECTION && cb > 0) {
			t.m11 = cb;
			t.m12 = sb;
			t.m21 = -sb;
			t.m22 = cb;
			break;
		}
	}
	
	return t;
}
+ (CATransform3D)translationWithTransform3D:(CATransform3D)from{
	CATransform3D k = CATransform3DIdentity;
	
	k.m41 = from.m41;
	k.m42 = from.m42;
	
	return k;
	
}
+ (CATransform3D)rotatelationWithTransform3D:(CATransform3D)from{
	CATransform3D k = CATransform3DIdentity;
	
	k.m11 = from.m11;
	k.m12 = from.m12;
	k.m21 = from.m21;
	k.m22 = from.m22;
	
	return k;
	
}

	
@end
