//
//  LYRUIParticipantPresenting.h
//  LayerSample
//
//  Created by Kevin Coleman on 8/29/14.
//  Copyright (c) 2014 Layer, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LYRUIParticipant.h"

/**
 @abstract The `LYRUIParticipantPickerSortType` allows for configuration of the sorting order of participants.
 */
typedef NS_ENUM(NSUInteger, LYRUIParticipantPickerSortType) {
    LYRUIParticipantPickerSortTypeFirstName,
    LYRUIParticipantPickerSortTypeLastName,
};

/**
 @abstract The `LYRUIParticipantPresenting` protocol must be adopted by objects that wish to present Layer
 participants in the user interface.
 */
@protocol LYRUIParticipantPresenting <NSObject>

/**
 @abstract Tells the receiver to present an interface for the given participant.
 @param participant The participant to present.
 @param sortType The type of sorting currently used.
 @param shouldShowAvatarImage Whether or not the receiver should display the participant's avatar.
 */
- (void)presentParticipant:(id<LYRUIParticipant>)participant
              withSortType:(LYRUIParticipantPickerSortType)sortType
     shouldShowAvatarImage:(BOOL)shouldShowAvatarImage;

@end