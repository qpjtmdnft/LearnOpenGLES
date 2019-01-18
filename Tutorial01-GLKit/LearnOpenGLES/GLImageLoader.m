//
//  GLImageLoader.m
//  LearnOpenGLES
//
//  Created by mac on 2019/1/12.
//  Copyright © 2019 loyinglin. All rights reserved.
//

#import "GLImageLoader.h"

@interface GLImageLoader ()<GLKViewDelegate>

@property (nonatomic, strong) EAGLContext *context;
@property (nonatomic, strong) GLKBaseEffect *effect;

@end

@implementation GLImageLoader

- (instancetype)init {
    if (self = [super init]) {
        [self setupContext];
    }
    return self;
}

- (void)setupContext {
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:self.context];
}

- (void)uploadVertexArray {
    //顶点数据，前三个是顶点坐标（x、y、z轴），后面两个是纹理坐标（x，y）
    // 顶点坐标，视图中间为零，范围为-1.0 到1.0
    // 纹理坐标，原点在左下，范围0 到 1
    GLfloat vertexData[] = {
        1, -1, 0,     1.0, 0.0,   // 右下
        1, 1, -0.0f,    1.0, 1.0,   // 右上
        -1, 1, 0.0f,    0.0, 1.0,   // 右上
        
        1, -1, 0.0f,    1.0f, 0.0f, // 右下
        -1, 1, 0.0f,    0.0f, 1.0f, // 左上,
        -1, -1, 0.0f,   0.0f, 0.0f, // 左下
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
    
    /*
     glBufferData()将数据拷贝到缓存对象。
     void glBufferData(GLenum target，GLsizeiptr size, const GLvoid*  data, GLenum usage);
     第一个参数target可以为GL_ARRAY_BUFFER或GL_ELEMENT_ARRAY。
     size为待传递数据字节数量。
     第三个参数为源数据数组指针，如data为NULL，则VBO仅仅预留给定数据大小的内存空间。
     最后一个参数usage标志位VBO的另一个性能提示，它提供缓存对象将如何使用：static、dynamic或stream、与read、copy或draw。
     ”static“表示VBO中的数据将不会被改动（一次指定多次使用），”dynamic“表示数据将会被频繁改动（反复指定与使用），”stream“表示每帧数据都要改变（一次指定一次使用）。”draw“表示数据将被发送到GPU以待绘制（应用程序到GL），”read“表示数据将被客户端程序读取（GL到应用程序），”copy“表示数据可用于绘制与读取（GL到GL）。
     注意，仅仅draw标志对VBO有用，copy与read标志对顶点/帧缓存对象（PBO或FBO）更有意义，如GL_STATIC_DRAW与GL_STREAM_DRAW使用显卡内存，GL_DYNAMIC使用AGP内存。_READ_相关缓存更适合在系统内存或AGP内存，因为这样数据更易访问。
     */
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertexData), vertexData, GL_STATIC_DRAW);
    
    /**
     * 默认情况下，出于性能考虑，所有顶点着色器的属性（Attribute）变量都是关闭的，意味着数据在着色器端是不可见的，哪怕数据已经上传到GPU，由glEnableVertexAttribArray启用指定属性，才可在顶点着色器中访问逐顶点的属性数据。
     */
    glEnableVertexAttribArray(GLKVertexAttribPosition); //顶点数据缓存
    
    /**
     * glVertexAttribPointer 指定了渲染时索引值为 index 的顶点属性数组的数据格式和位置。
     * void glVertexAttribPointer( GLuint index, GLint size, GLenum type, GLboolean normalized, GLsizei stride,const GLvoid * pointer);
     * index
     指定要修改的顶点属性的索引值
     * size
     指定每个顶点属性的组件数量。必须为1、2、3或者4。初始值为4。（如position是由3个（x,y,z）组成，而颜色是4个（r,g,b,a））
     * type
     指定数组中每个组件的数据类型。可用的符号常量有GL_BYTE, GL_UNSIGNED_BYTE, GL_SHORT,GL_UNSIGNED_SHORT, GL_FIXED, 和 GL_FLOAT，初始值为GL_FLOAT。
     *
     * normalized
     指定当被访问时，固定点数据值是否应该被归一化（GL_TRUE）或者直接转换为固定点值（GL_FALSE）。
     
     * stride
     指定连续顶点属性之间的偏移量。如果为0，那么顶点属性会被理解为：它们是紧密排列在一起的。初始值为0。
     
     * pointer
     指定第一个组件在数组的第一个顶点属性中的偏移量。该数组与GL_ARRAY_BUFFER绑定，储存于缓冲区中。初始值为0；
     */
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 0);
    
    // 纹理
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0); //纹理
    
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 3);
}

#pragma mark -

- (void)loadWithFilePath:(NSString *)filePath {
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return;
    }
    
    [EAGLContext setCurrentContext:self.context];
    [self uploadVertexArray];
    
    NSDictionary *options = @{GLKTextureLoaderOriginBottomLeft: @(1)};
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfFile:filePath options:options error:nil];
    
    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.texture2d0.enabled = GL_TRUE;
    self.effect.texture2d0.name = textureInfo.name;
    
    self.target.context = self.context;
    [self.target setNeedsDisplay];
}

#pragma mark -

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    // 设置底色 r, g, b, a
    glClearColor(0.3, 0.6, 1.0, 1);
    
    /**
     * 清除viewport的缓冲区
     * GL_COLOR_BUFFER_BIT: 当前可写的颜色缓冲
     GL_DEPTH_BUFFER_BIT: 深度缓冲
     GL_ACCUM_BUFFER_BIT: 累积缓冲
     GL_STENCIL_BUFFER_BIT: 模板缓冲
     */
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    [self.effect prepareToDraw];
    
    glDrawArrays(GL_TRIANGLES, 0, 6);
}

#pragma mark - setter

- (void)setTarget:(GLKView *)target {
    _target = target;
    target.context = self.context;
    target.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    target.delegate = self;
    
    NSLog(@"scale factor:%.2f", target.contentScaleFactor);
}

@end
