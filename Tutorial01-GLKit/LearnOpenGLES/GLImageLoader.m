//
//  GLImageLoader.m
//  LearnOpenGLES
//
//  Created by mac on 2019/1/12.
//  Copyright © 2019 loyinglin. All rights reserved.
//

#import "GLImageLoader.h"

@interface GLImageLoader ()

@property (nonatomic, strong) EAGLContext *context;
@property (nonatomic, strong) GLKBaseEffect *effect;

@end

@implementation GLImageLoader

- (instancetype)init {
    if (self = [super init]) {
        [self setupContext];
        [self uploadVertexArray];
    }
    return self;
}

- (void)setupContext {
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:self.context];
}

- (void)uploadVertexArray {
    //顶点数据，前三个是顶点坐标（x、y、z轴），后面两个是纹理坐标（x，y）
    GLfloat vertexData[] = {
        0, -0.5, 0,     1.0, 0.0,   // 右下
        0.5, 0.5, -0.0f,    1.0, 1.0,   // 右上
        -0.5, 0.5, 0.0f,    0.0, 1.0,   // 右上
        
        0.5, -0.5, 0.0f,    1.0f, 0.0f, // 右下
        -0.5, 0.5, 0.0f,    0.0f, 1.0f, // 左上,
        -0.5, -0.5, 0.05,   0.0f, 0.0f, // 左下
    };
    
    GLuint buffer;
    
    // glGenBuffers()创建缓存对象并且返回缓存对象的标示符。它需要2个参数：第一个为需要创建的缓存数量，第二个为用于存储单一ID或多个ID的GLuint变量或数组的地址。
    glGenBuffers(1, &buffer);
    
    /*
     当缓存对象创建之后，在使用缓存对象之前，我们需要将缓存对象连接到相应的缓存上。glBindBuffer()有2个参数：target与buffer。
     void glBindBuffer(GLenum target, GLuint buffer)
     arget告诉VBO该缓存对象将保存顶点数组数据还是索引数组数据：GL_ARRAY_BUFFER或GL_ELEMENT_ARRAY。
     任何顶点属性，如顶点坐标、纹理坐标、法线与颜色分量数组都使用GL_ARRAY_BUFFER。
     用于glDraw[Range]Elements()的索引数据需要使用GL_ELEMENT_ARRAY绑定。注意，target标志帮助VBO确定缓存对象最有效的位置，如有些系统将索引保存AGP或系统内存中，将顶点保存在显卡内存中。
     */
    glBindBuffer(GL_ARRAY_BUFFER, buffer);
    
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertexData), vertexData, GL_STATIC_DRAW);
}

#pragma mark - setter

- (void)setTarget:(GLKView *)target {
    _target = target;
    target.context = self.context;
    target.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
}

@end
