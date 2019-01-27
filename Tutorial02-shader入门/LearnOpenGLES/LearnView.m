//
//  LearnView.m
//  LearnOpenGLES
//
//  Created by loyinglin on 16/3/11.
//  Copyright © 2016年 loyinglin. All rights reserved.
//

#import "LearnView.h"
#import <OpenGLES/ES2/gl.h>

@interface LearnView()
@property (nonatomic , strong) EAGLContext* myContext;
@property (nonatomic , strong) CAEAGLLayer* myEagLayer;
@property (nonatomic , assign) GLuint       myProgram;


@property (nonatomic , assign) GLuint myColorRenderBuffer;
@property (nonatomic , assign) GLuint myColorFrameBuffer;

- (void)setupLayer;

@end

@implementation LearnView

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (void)layoutSubviews {
    
    [self setupLayer];
    
    [self setupContext];
    
    [self destoryRenderAndFrameBuffer];
    
    [self setupRenderBuffer];
    
    [self setupFrameBuffer];
    
    [self render]; 
}

- (void)setupLayer
{
    self.myEagLayer = (CAEAGLLayer*) self.layer;
    //设置放大倍数
    [self setContentScaleFactor:[[UIScreen mainScreen] scale]];
    
    // CALayer 默认是透明的，必须将它设为不透明才能让其可见
    self.myEagLayer.opaque = YES;
    
    // 设置描绘属性，在这里设置不维持渲染内容以及颜色格式为 RGBA8
    self.myEagLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
}

- (void)setupContext {
    // 指定 OpenGL 渲染 API 的版本，在这里我们使用 OpenGL ES 2.0
    EAGLContext* context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!context) {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
        exit(1);
    }
    
    // 设置为当前上下文
    if (![EAGLContext setCurrentContext:context]) {
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
    self.myContext = context;
}

- (void)render {
    glClearColor(0, 1.0, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    
    CGFloat scale = [[UIScreen mainScreen] scale]; //获取视图放大倍数，可以把scale设置为1试试
    
    /**
     * 设置窗口大小
     * 注意，一般open gl的原点在左下角，但iOS中在左上角
     */
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale); //设置视口大小
    
    //读取文件路径
    /**
     .vsh 是 vertex shader，用与顶点计算，可以理解控制顶点的位置，在这个文件中我们通常会传入当前顶点的位置，和纹理的坐标。
     
     首先，每一个Shader程序都有一个main函数，这一点和c语言是一样的。
     这里面有两种类型的变量，一种是attribute，另一种是varying.
     attribute是从外部传进来的，每一个顶点都会有这两个属性，所以它也叫做vertex attribute（顶点属性）。
     而varying类型的变量是在vertex shader和fragment shader之间传递数据用的。
     uniform 外部传入vsh文件的变量 变化率较低 对于可能在整个渲染过程没有改变 只是个常量。
     
     ## vertex shader是作用于每一个顶点的，如果vertex有三个点，那么vertex shader会被执行三次。##
     
     vsh 负责搞定像素位置 ,填写  gl_Posizion 变量，偶尔搞定一下点大小的问题，填写 gl_PixelSize。
     */
    NSString* vertFile = [[NSBundle mainBundle] pathForResource:@"shaderv" ofType:@"vsh"];
    
    /**
     .fsh 是片段shader。在这里面我可以对于每一个像素点进行重新计算。
     
     gl_FragColor我是一个系统内置变量了，它的作用是定义最终画在屏幕上面的像素点的颜色。
     
     fsh 负责搞定像素外观，填写 gl_FragColor ，偶尔配套填写另外一组变量。
     */
    NSString* fragFile = [[NSBundle mainBundle] pathForResource:@"shaderf" ofType:@"fsh"];
    
    //加载shader
    self.myProgram = [self loadShaders:vertFile frag:fragFile];
    
    //链接
    
    /**
     glLinkProgram链接program指定的program对象。
     附加到program的类型为GL_VERTEX_SHADER的着色器对象用于创建将在可编程顶点处理器上运行的可执行文件。
     附加到program的类型为GL_FRAGMENT_SHADER的着色器对象用于创建将在可编程片段处理器上运行的可执行文件。
     
     链接操作的状态将存储为program对象状态的一部分。 如果程序对象链接没有错误并且可以使用，则此值将设置为GL_TRUE，否则将设置为GL_FALSE。 可以通过使用参数program和GL_LINK_STATUS调用glGetShaderiv来查询它。
     */
    
    glLinkProgram(self.myProgram);
    GLint linkSuccess;
    
    glGetProgramiv(self.myProgram, GL_LINK_STATUS, &linkSuccess);
    
    if (linkSuccess == GL_FALSE) { //连接错误
        GLchar messages[256];
        glGetProgramInfoLog(self.myProgram, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"error%@", messageString);
        return ;
    }
    else {
        NSLog(@"link ok");
        
        /**
         指定程序对象的句柄，该程序对象的可执行文件将用作当前渲染状态的一部分。
         
         
         */
        glUseProgram(self.myProgram); //成功便使用，避免由于未使用导致的的bug
    }
    
    // 顶点数据
    GLfloat attrArr[] =
    {
        0.5f, -0.5f, -1.0f,     1.0f, 0.0f,
        -0.5f, 0.5f, -1.0f,     0.0f, 1.0f,
        -0.5f, -0.5f, -1.0f,    0.0f, 0.0f,
        0.5f, 0.5f, -1.0f,      1.0f, 1.0f,
        -0.5f, 0.5f, -1.0f,     0.0f, 1.0f,
        0.5f, -0.5f, -1.0f,     1.0f, 0.0f,
    };
    
    GLuint attrBuffer;
    glGenBuffers(1, &attrBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, attrBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    
    /**
     GLint glGetAttribLocation（GLuint program,const GLchar *name）;
     @param program 指定要查询的程序对象。
     @param 要查询其位置的属性变量的名称。
     
     在调用glLinkProgram之前，属性绑定不会生效。 成功链接程序对象后，属性变量的索引值将保持固定，直到发生下一个链接命令。 如果链接成功，则只能在链接后查询属性值。 glGetAttribLocation返回上次为指定程序对象调用glLinkProgram时实际生效的绑定。 glGetAttribLocation不返回自上次链接操作以来指定的属性绑定。
     */
    
    GLuint position = glGetAttribLocation(self.myProgram, "position");  // 此处position定义于shader中
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, NULL);
    glEnableVertexAttribArray(position);
    
    GLuint textCoor = glGetAttribLocation(self.myProgram, "textCoordinate");
    glVertexAttribPointer(textCoor, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (float *)NULL + 3);
    glEnableVertexAttribArray(textCoor);
    
    //加载纹理
    [self setupTexture:@"for_test"];
    
    //获取shader里面的变量，这里记得要在glLinkProgram后面，后面，后面！
    GLuint rotate = glGetUniformLocation(self.myProgram, "rotateMatrix");
    
    float radians = 10 * 3.14159f / 180.0f;
    float s = sin(radians);
    float c = cos(radians);
    
    //z轴旋转矩阵
    GLfloat zRotation[16] = { //
        c, -s, 0, 0.2, //
        s, c, 0, 0,//
        0, 0, 1.0, 0,//
        0.0, 0, 0, 1.0//
    };
    
    //设置旋转矩阵
    glUniformMatrix4fv(rotate, 1, GL_FALSE, (GLfloat *)&zRotation[0]);
    
    glDrawArrays(GL_TRIANGLES, 0, 6);
    
    [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
}

/**
 *  c语言编译流程：预编译、编译、汇编、链接
 *  glsl的编译过程主要有glCompileShader、glAttachShader、glLinkProgram三步；

 glCreateProgram创建一个空program并返回一个可以被引用的非零值（program ID）。
 program对象是可以附加着色器对象的对象。 这提供了一种机制来指定将链接以创建program的着色器对象。 它还提供了一种检查将用于创建program的着色器的兼容性的方法（例如，检查顶点着色器和片元着色器之间的兼容性）。 当不再需要作为program对象的一部分时，着色器对象就可以被分离了。
 
 通过调用glCompileShader成功编译着色器对象，并且通过调用glAttachShader成功地将着色器对象附加到program 对象，并且通过调用glLinkProgram成功的链接program 对象之后，可以在program 对象中创建一个或多个可执行文件。
 
 当调用glUseProgram时，这些可执行文件成为当前状态的一部分。 可以通过调用glDeleteProgram删除程序对象。 当program 对象不再是任何上下文的当前呈现状态的一部分时，将删除与program 对象关联的内存。
 */
- (GLuint)loadShaders:(NSString *)vert frag:(NSString *)frag {
    GLuint verShader, fragShader;
    
    // 创建空的program对象
    GLint program = glCreateProgram();
    
    //编译
    [self compileShader:&verShader type:GL_VERTEX_SHADER file:vert];
    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:frag];
    
    glAttachShader(program, verShader);
    glAttachShader(program, fragShader);
    
    
    //释放不需要的shader
    glDeleteShader(verShader);
    glDeleteShader(fragShader);
    
    return program;
}

- (void)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file {
    //读取字符串
    NSString* content = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    const GLchar* source = (GLchar *)[content UTF8String];
    
    /**
     指定要创建的着色器的类型。 只能是GL_VERTEX_SHADER或GL_FRAGMENT_SHADER。
     */
    *shader = glCreateShader(type);
    
    /**
     替换着色器对象中的源代码
     此时不扫描或解析源代码字符串; 它们只是复制到指定的着色器对象中。
     */
    glShaderSource(*shader, 1, &source, NULL);
    
    /**
     编译已存储在shader指定的着色器对象中的源代码字符串。
     */
    glCompileShader(*shader);
}

- (void)setupRenderBuffer {
    /**
     创建一个渲染缓冲对象
     
     */
    GLuint buffer;
    glGenRenderbuffers(1, &buffer);
    self.myColorRenderBuffer = buffer;
    
    /**
     相似地，我们打算把渲染缓冲对象绑定，这样所有后续渲染缓冲操作都会影响到当前的渲染缓冲对象：
     */
    glBindRenderbuffer(GL_RENDERBUFFER, buffer);
    
    // 为 颜色缓冲区 分配存储空间
    [self.myContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myEagLayer];
}


- (void)setupFrameBuffer {
    GLuint buffer;
    glGenFramebuffers(1, &buffer);
    self.myColorFrameBuffer = buffer;
    // 设置为当前 framebuffer
    glBindFramebuffer(GL_FRAMEBUFFER, self.myColorFrameBuffer);
    
    // 将 _colorRenderBuffer 装配到 GL_COLOR_ATTACHMENT0 这个装配点上
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER, self.myColorRenderBuffer);
}


- (void)destoryRenderAndFrameBuffer
{
    /**
     删除帧缓冲对象
     */
    glDeleteFramebuffers(1, &_myColorFrameBuffer);
    self.myColorFrameBuffer = 0;
    glDeleteRenderbuffers(1, &_myColorRenderBuffer);
    self.myColorRenderBuffer = 0;
}

- (GLuint)setupTexture:(NSString *)fileName {
    // 1获取图片的CGImageRef
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
    if (!spriteImage) {
        NSLog(@"Failed to load image %@", fileName);
        exit(1);
    }
    
    // 2 读取图片的大小
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    GLubyte * spriteData = (GLubyte *) calloc(width * height * 4, sizeof(GLubyte)); //rgba共4个byte
    
    /**
     CGContextRef CGBitmapContextCreate (
     
        void *data,
        size_t width,
        size_t height,
        size_t bitsPerComponent,
        size_t bytesPerRow,
        CGColorSpaceRef colorspace,
        CGBitmapInfo bitmapInfo
     );
     @param data 指向要渲染的绘制内存的地址。这个内存块的大小至少是（bytesPerRow*height）个字节
     @param width bitmap的宽度,单位为像素
     @param height 高度
     @param bitsPerComponent 内存中像素的每个组件的位数.例如，对于32位像素格式和RGB 颜色空间，你应该将这个值设为8.
     @param bytesPerRow bitmap的每一行在内存所占的比特数
     @param colorspace 颜色空间
     @param bitmapInfo 指定bitmap是否包含alpha通道，像素中alpha通道的相对位置，像素组件是整形还是浮点型等信息的字符串。
     */
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData,
                                                       width,
                                                       height,
                                                       8,
                                                       width*4,
                                                       CGImageGetColorSpace(spriteImage),
                                                       kCGImageAlphaPremultipliedLast);
    
    // 3在CGContextRef上绘图，图片存于spirteData中
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    
    CGContextRelease(spriteContext);
    
    // 4绑定纹理到默认的纹理ID（这里只有一张图片，故而相当于默认于片元着色器里面的colorMap，如果有多张图不可以这么做）
    glBindTexture(GL_TEXTURE_2D, 0);
    
    
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    float fw = width, fh = height;
    
    /**
     void glTexImage2D(GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, const GLvoid * pixels);
     @param target 指定目标纹理，这个值必须是GL_TEXTURE_2D
     @param level 执行细节级别。0是最基本的图像级别，你表示第N级贴图细化级别。
     @param internalformat 指定纹理中的颜色组件，这个取值和后面的format取值必须相同。GL_ALPHA,GL_RGB, GL_RGBA, GL_LUMINANCE, GL_LUMINANCE_ALPHA
     @param width 指定纹理图像的宽度，必须是2的n次方。纹理图片至少要支持64个材质元素的宽度
     @param height 指定纹理图像的高度，必须是2的m次方。纹理图片至少要支持64个材质元素的高度
     @param border 指定边框的宽度。必须为0。
     @param format 像素数据的颜色格式，必须和internalformatt取值必须相同
     @param type 可以使用的值有
                         GL_UNSIGNED_BYTE,
                         GL_UNSIGNED_SHORT_5_6_5,
                         GL_UNSIGNED_SHORT_4_4_4_4,
                         GL_UNSIGNED_SHORT_5_5_5_1
     @param pixels 指定内存中指向图像数据的指针
     */
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fw, fh, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    
    /**
     void glBindTexture(GLenum  target, GLuint  texture);
     将一个命名的纹理绑定到一个纹理目标上
     @param target 指明了纹理要绑定到的目标。必须是下面中的一个：GL_TEXTURE_1D, GL_TEXTURE_2D, GL_TEXTURE_3D, GL_TEXTURE_1D_ARRAY, GL_TEXTURE_2D_ARRAY, GL_TEXTURE_RECTANGLE, GL_TEXTURE_CUBE_MAP, GL_TEXTURE_CUBE_MAP_ARRAY, GL_TEXTURE_BUFFER, GL_TEXTURE_2D_MULTISAMPLE 或者 GL_TEXTURE_2D_MULTISAMPLE_ARRAY。
     @param texture 指明一张纹理的名字
     
     glBindTexture允许我们向GL_TEXTURE_1D, GL_TEXTURE_2D, GL_TEXTURE_3D, GL_TEXTURE_1D_ARRAY, GL_TEXTURE_2D_ARRAY, GL_TEXTURE_RECTANGLE, GL_TEXTURE_CUBE_MAP, GL_TEXTURE_CUBE_MAP_ARRAY, GL_TEXTURE_BUFFER, GL_TEXTURE_2D_MULTISAMPLE or GL_TEXTURE_2D_MULTISAMPLE_ARRAY 绑定一张纹理。当把一张纹理绑定到一个目标上时，之前对这个目标的绑定就会失效。
     
     纹理名字是一个无符号整数。值0是被保留的，它代表了每一个纹理目标的默认纹理。对于当前的GL渲染上下文中的共享对象空间，纹理名称以及它们对应的纹理内容是局部的；只有在显式开启上下文之间的共享，两个渲染上下文才可以共享纹理名称。
     
     当一张纹理被第一次绑定时，它假定成为指定的目标类型。例如，一张纹理若第一次被绑定到GL_TEXTURE_1D上，就变成了一张一维纹理；若第一次被绑定到GL_TEXTURE_2D上，就变成了一张二维纹理。
     
     当一张纹理被绑定后，GL对于这个目标的操作都会影响到这个被绑定的纹理。也就是说，这个纹理目标成为了被绑定到它上面的纹理的别名，而纹理名称为0则会引用到它的默认纹理。

     我们可以这样理解，GL_TEXTURE_1D, GL_TEXTURE_2D, GL_TEXTURE_3D等就是很多变量，当使用glBindTexture函数，我们就会使用一张纹理对这些变量进行赋值，
     */
    glBindTexture(GL_TEXTURE_2D, 0);
    
    free(spriteData);
    return 0;
}
@end
