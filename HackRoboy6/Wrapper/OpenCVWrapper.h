//
//  OpenCVWrapper.h
//  HackRoboy6
//
//  Created by Leenert Specht on 04.05.19.
//  Copyright © 2019 Leenert Specht. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OpenCVWrapper : NSObject
-(NSString *) openCVVersionString;
-(NSString *) displayPositionOfMarker: (UIImage*) image;

@end

NS_ASSUME_NONNULL_END
