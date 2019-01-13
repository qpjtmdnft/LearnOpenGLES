//
//  GLImageLoader.h
//  LearnOpenGLES
//
//  Created by mac on 2019/1/12.
//  Copyright © 2019 loyinglin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface GLImageLoader : NSObject

@property (nonatomic, weak) GLKView *target;

- (void)loadWithFilePath:(NSString *)filePath;

@end

NS_ASSUME_NONNULL_END
