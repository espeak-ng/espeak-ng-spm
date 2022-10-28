//
//  Header.h
//  
//
//  Created by Yury Popov on 28.10.2022.
//

#pragma once

#import <Foundation/Foundation.h>

extern const NSErrorDomain _Nonnull EspeakErrorDomain;

@interface EspeakLib : NSObject
- (instancetype _Nonnull)init NS_UNAVAILABLE;
+ (BOOL)ensureBundleInstalledInRoot:(NSURL*_Nonnull)root error:(NSError*_Nullable*_Nonnull)error;
@end
