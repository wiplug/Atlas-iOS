//
//  LYRUIMessagingUtilities.m
//  LayerUIKit
//
//  Created by Kevin Coleman on 10/27/14.
//
//

#import "LYRUIMessagingUtilities.h"
#import "LYRUIErrors.h"
#import <AssetsLibrary/AssetsLibrary.h>

NSString *const LYRUIMIMETypeTextPlain = @"text/plain";
NSString *const LYRUIMIMETypeTextHTML = @"text/HTML";
NSString *const LYRUIMIMETypeImagePNG = @"image/png";
NSString *const LYRUIMIMETypeImageJPEG = @"image/jpeg";
NSString *const LYRUIMIMETypeLocation = @"location/coordinate";
NSString *const LYRUIMIMETypeDate = @"text/date";

CGFloat LYRUIMaxCellWidth()
{
    return 220;
}

CGFloat LYRUIMaxCellHeight()
{
    return 300;
}

CGSize LYRUITextPlainSize(NSString *text, UIFont *font)
{
    CGRect rect = [text boundingRectWithSize:CGSizeMake(LYRUIMaxCellWidth(), CGFLOAT_MAX)
                                     options:NSStringDrawingUsesLineFragmentOrigin
                                  attributes:@{NSFontAttributeName: font}
                                     context:nil];
    return rect.size;
}

CGSize LYRUIImageSize(UIImage *image)
{
    CGSize maxSize = CGSizeMake(LYRUIMaxCellWidth(), LYRUIMaxCellHeight());
    CGSize itemSize = LYRUISizeProportionallyConstrainedToSize(image.size, maxSize);
    return itemSize;
}

CGSize LYRUISizeProportionallyConstrainedToSize(CGSize nativeSize, CGSize maxSize)
{
    CGSize itemSize;
    CGFloat widthScale = maxSize.width / nativeSize.width;
    CGFloat heightScale = maxSize.height / nativeSize.height;
    if (heightScale < widthScale) {
        itemSize = CGSizeMake(nativeSize.width * heightScale, maxSize.height);
    } else {
        itemSize = CGSizeMake(maxSize.width, nativeSize.height * widthScale);
    }
    return itemSize;
}

CGRect LYRUIImageRectConstrainedToSize(CGSize imageSize, CGSize maxSize)
{
    CGSize itemSize = LYRUISizeProportionallyConstrainedToSize(imageSize, maxSize);
    CGRect thumbRect = {0, 0, itemSize};
    return thumbRect;
}

UIImage *LYRUIAdjustOrientationForImage(UIImage *originalImage)
{
    UIGraphicsBeginImageContextWithOptions(originalImage.size, NO, originalImage.scale);
    [originalImage drawInRect:(CGRect){0, 0, originalImage.size}];
    UIImage *fixedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return fixedImage;
}

LYRMessagePart *LYRUIMessagePartWithText(NSString *text)
{
    return [LYRMessagePart messagePartWithMIMEType:@"text/plain" data:[text dataUsingEncoding:NSUTF8StringEncoding]];
}

LYRMessagePart *LYRUIMessagePartWithLocation(CLLocation *location)
{
    NSNumber *lat = @(location.coordinate.latitude);
    NSNumber *lon = @(location.coordinate.longitude);
    NSData *data = [NSJSONSerialization dataWithJSONObject:@{@"lat": lat, @"lon": lon} options:0 error:nil];
    return [LYRMessagePart messagePartWithMIMEType:LYRUIMIMETypeLocation data:data];
}

// Photo Resizing
CGSize  LYRUISizeFromOriginalSizeWithConstraint(CGSize originalSize, CGFloat constraint)
{
    if (originalSize.height > constraint && (originalSize.height > originalSize.width)) {
        CGFloat heightRatio = constraint / originalSize.height;
        return CGSizeMake(originalSize.width * heightRatio, constraint);
    } else if (originalSize.width > constraint) {
        CGFloat widthRatio = constraint / originalSize.width;
        return CGSizeMake(constraint, originalSize.height * widthRatio);
    }
    return originalSize;
}

NSData *LYRUIJPEGDataForImageWithConstraint(UIImage *image, CGFloat constraint)
{
    NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
    CGImageRef ref = [[UIImage imageWithData:imageData] CGImage];
    
    CGFloat width = 1.0f * CGImageGetWidth(ref);
    CGFloat height = 1.0f * CGImageGetHeight(ref);
    
    CGSize previousSize = CGSizeMake(width, height);
    CGSize newSize = LYRUISizeFromOriginalSizeWithConstraint(previousSize, constraint);
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    UIImage *assetImage = [UIImage imageWithCGImage:ref];
    [assetImage drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *imageToCompress = UIGraphicsGetImageFromCurrentImageContext();
    
    return UIImageJPEGRepresentation(imageToCompress, 0.25f);
}

LYRMessagePart *LYRUIMessagePartWithJPEGImage(UIImage *image)
{
    UIImage *adjustedImage = LYRUIAdjustOrientationForImage(image);
    NSData *imageData = LYRUIJPEGDataForImageWithConstraint(adjustedImage, 300);
    return [LYRMessagePart messagePartWithMIMEType:LYRUIMIMETypeImageJPEG
                                              data:imageData];
}

void LYRUILastPhotoTaken(void(^completionHandler)(UIImage *image, NSError *error))
{
    // Credit goes to @iBrad Apps on Stack Overflow
    // http://stackoverflow.com/questions/8867496/get-last-image-from-photos-app
    
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    // Enumerate just the photos and videos group by using ALAssetsGroupSavedPhotos.
    [library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        // When done, the group enumeration block is called another time with group set to nil.
        if (!group) return;

        // Within the group enumeration block, filter to enumerate just photos.
        [group setAssetsFilter:[ALAssetsFilter allPhotos]];

        if ([group numberOfAssets] == 0) {
            completionHandler(nil, [NSError errorWithDomain:LYRUIErrorDomain code:LYRUIErrorNoPhotos userInfo:@{NSLocalizedDescriptionKey: @"There are no photos."}]);
            return;
        }
        
        [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *result, NSUInteger index, BOOL *innerStop) {
            // When done, the asset enumeration block is called another time with result set to nil.
            if (!result) return;

            ALAssetRepresentation *representation = [result defaultRepresentation];
            UIImage *latestPhoto = [UIImage imageWithCGImage:[representation fullScreenImage]];
            
            // Stop the enumerations
            *innerStop = YES;
            *stop = YES;
            completionHandler(latestPhoto, nil);
        }];
    } failureBlock:^(NSError *error) {
        completionHandler(nil, error);
    }];
}

NSArray *LYRUILinkResultsForText(NSString *text)
{
    NSError *error;
    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink
                                                               error:&error];
    if (error) return nil;
    return [detector matchesInString:text options:kNilOptions range:NSMakeRange(0, text.length)];
}

NSString *LYRUIPushTextWithPartAndSenderName(LYRMessagePart *messagePart, NSString *senderName)
{
    NSString *pushText;
    if ([messagePart.MIMEType isEqualToString:LYRUIMIMETypeTextPlain]) {
        pushText = [[NSString alloc] initWithData:messagePart.data encoding:NSUTF8StringEncoding];
    } else if ([messagePart.MIMEType isEqualToString:LYRUIMIMETypeImageJPEG] || [messagePart.MIMEType isEqualToString:LYRUIMIMETypeImagePNG]) {
        pushText = @"Has sent a new image";
    } else if ([messagePart.MIMEType isEqualToString:LYRUIMIMETypeLocation]) {
        pushText = @"Has sent a new location";
    }
    return [NSString stringWithFormat:@"%@: %@", senderName, pushText];
}
