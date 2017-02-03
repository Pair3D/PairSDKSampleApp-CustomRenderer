//
//  ViewController.m
//  PairSampleApp
//
//  Created by Matt Loflin on 11/14/16.
//  Copyright © 2016 Pair, Inc. All rights reserved.
//

#import "PairAssetLoader.h"
#import "PairView.h"
#import "ViewController.h"
#import <OpenGLES/ES2/glext.h>

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

// Uniform index.
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_NORMAL_MATRIX,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum
{
    ATTRIB_VERTEX,
    ATTRIB_NORMAL,
    NUM_ATTRIBUTES
};

GLfloat gCubeVertexData[216] =
{
    // Data layout for each line below is:
    // positionX, positionY, positionZ,     normalX, normalY, normalZ,
    0.5f, -0.5f, -0.5f,        1.0f, 0.0f, 0.0f,
    0.5f, 0.5f, -0.5f,         1.0f, 0.0f, 0.0f,
    0.5f, -0.5f, 0.5f,         1.0f, 0.0f, 0.0f,
    0.5f, -0.5f, 0.5f,         1.0f, 0.0f, 0.0f,
    0.5f, 0.5f, -0.5f,          1.0f, 0.0f, 0.0f,
    0.5f, 0.5f, 0.5f,         1.0f, 0.0f, 0.0f,

    0.5f, 0.5f, -0.5f,         0.0f, 1.0f, 0.0f,
    -0.5f, 0.5f, -0.5f,        0.0f, 1.0f, 0.0f,
    0.5f, 0.5f, 0.5f,          0.0f, 1.0f, 0.0f,
    0.5f, 0.5f, 0.5f,          0.0f, 1.0f, 0.0f,
    -0.5f, 0.5f, -0.5f,        0.0f, 1.0f, 0.0f,
    -0.5f, 0.5f, 0.5f,         0.0f, 1.0f, 0.0f,

    -0.5f, 0.5f, -0.5f,        -1.0f, 0.0f, 0.0f,
    -0.5f, -0.5f, -0.5f,       -1.0f, 0.0f, 0.0f,
    -0.5f, 0.5f, 0.5f,         -1.0f, 0.0f, 0.0f,
    -0.5f, 0.5f, 0.5f,         -1.0f, 0.0f, 0.0f,
    -0.5f, -0.5f, -0.5f,       -1.0f, 0.0f, 0.0f,
    -0.5f, -0.5f, 0.5f,        -1.0f, 0.0f, 0.0f,

    -0.5f, -0.5f, -0.5f,       0.0f, -1.0f, 0.0f,
    0.5f, -0.5f, -0.5f,        0.0f, -1.0f, 0.0f,
    -0.5f, -0.5f, 0.5f,        0.0f, -1.0f, 0.0f,
    -0.5f, -0.5f, 0.5f,        0.0f, -1.0f, 0.0f,
    0.5f, -0.5f, -0.5f,        0.0f, -1.0f, 0.0f,
    0.5f, -0.5f, 0.5f,         0.0f, -1.0f, 0.0f,

    0.5f, 0.5f, 0.5f,          0.0f, 0.0f, 1.0f,
    -0.5f, 0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
    0.5f, -0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
    0.5f, -0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
    -0.5f, 0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
    -0.5f, -0.5f, 0.5f,        0.0f, 0.0f, 1.0f,

    0.5f, -0.5f, -0.5f,        0.0f, 0.0f, -1.0f,
    -0.5f, -0.5f, -0.5f,       0.0f, 0.0f, -1.0f,
    0.5f, 0.5f, -0.5f,         0.0f, 0.0f, -1.0f,
    0.5f, 0.5f, -0.5f,         0.0f, 0.0f, -1.0f,
    -0.5f, -0.5f, -0.5f,       0.0f, 0.0f, -1.0f,
    -0.5f, 0.5f, -0.5f,        0.0f, 0.0f, -1.0f
};

@interface ViewController () <PairViewModelDelegate, PairViewRecordingDelegate, PairViewSensorFusionDelegate, PairViewRenderDelegate>
{
    GLuint _program;

    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix3 _normalMatrix;
    float _rotation;

    GLuint _vertexArray;
    GLuint _vertexBuffer;
}
@property (assign, nonatomic) GLKMatrix4 baseModelViewMatrix;

@property (nonatomic, weak) IBOutlet UIButton *imageButton;
@property (nonatomic, weak) IBOutlet UIButton *addButton;
@property (nonatomic, weak) IBOutlet UIButton *videoButton;
@property (nonatomic, weak) IBOutlet UIButton *swatchButton;
@property (nonatomic, weak) IBOutlet PairView *pairView; // Used when loading from storyboard or xib.
//@property (nonatomic, strong) PairView *pairView; // Used when loading programmatically via one of he commented out options below.
@end

@implementation ViewController

- (void)dealloc
{
    [self tearDownGL];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Delete the downloaded models each time the app launches because this sample app stores models
    // in the same location and it's expected that during testing the model URL might be changed.
    [NSFileManager.defaultManager removeItemAtURL:ViewController.saveLocation error:nil];

    self.edgesForExtendedLayout = UIRectEdgeTop;

    self.imageButton.hidden = YES;
    self.addButton.hidden = YES;
    self.videoButton.hidden = YES;
    self.swatchButton.hidden = YES;

    // In this example the PairView is loaded via storyboard. Commented out below are some alternative
    // methods for creating and attaching the PairView to your view hierarchy.

    /*
     // Option: Create PairView programmatically using autolayout.
     self.pairView = [PairView new];
     self.pairView.translatesAutoresizingMaskIntoConstraints = NO;
     [self.view insertSubview:self.pairView atIndex:0];
     NSDictionary *views = NSDictionaryOfVariableBindings(_pairView);
     [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_pairView]|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
     [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_pairView]|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
     
     // Assign delegates.
     self.pairView.renderDelegate = self;
     self.pairView.modelDelegate = self;
     self.pairView.sensorFusionDelegate = self;
     self.pairView.recordingDelegate = self;
    */

    /*
     // Option: Create PairView programmatically using a CGRect frame.
     self.pairView = [[PairView alloc] initWithFrame:UIScreen.mainScreen.bounds];
     [self.pairView setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
     [self.view insertSubview:self.pairView atIndex:0];
     
     // Assign delegates.
     self.pairView.renderDelegate = self;
     self.pairView.modelDelegate = self;
     self.pairView.sensorFusionDelegate = self;
     self.pairView.recordingDelegate = self;
    */

    [self setupGL];
    
    // The PairView will not start until "resume" is called.
    [self.pairView resume];
}

- (void)setupGL
{
    //[EAGLContext setCurrentContext:self.context];

    [self loadShaders];

    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);

    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(gCubeVertexData), gCubeVertexData, GL_STATIC_DRAW);

    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(0));
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(12));

    glBindBuffer(GL_ARRAY_BUFFER, 0);

    glBindVertexArrayOES(0);
}

- (void)tearDownGL
{
//    [EAGLContext setCurrentContext:self.context];

    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);

    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
         [self.pairView viewWillTransitionToSize:size];
    } completion:nil];
}

- (IBAction)onImageButtonTouch:(id)sender
{
    UIImageWriteToSavedPhotosAlbum([self.pairView screenshot], self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    NSLog(@"Image saved");
}

+ (nonnull NSURL *)saveLocation
{
    NSURL *documentsDirectory = [NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].lastObject;
    return [documentsDirectory URLByAppendingPathComponent:@"PairTemp" isDirectory:YES];
}

- (IBAction)onAddButtonTouch:(id)sender
{
    // The path to which the asset's mesh and texture data can be saved.
    NSURL *saveLocation = ViewController.saveLocation;

    PairAsset *pairAsset;
    NSURL *modelURL = [PairAssetLoader findModelFileInDirectory:saveLocation];
    if (modelURL) {
        // The model data is on the device. Load directly from file.
        pairAsset = [[PairAsset alloc] initWithURL:modelURL];
    } else {
        // The model data is not on the device and so needs to be downloaded.

        //
        // Example model with swatches:
        //

        // Download loactaion of the mesh and texture files needed to render the asset.
        NSURL *downloadURL = [NSURL URLWithString:@"https://paircatalog.blob.core.windows.net/pair-public-catalog/catalog-models/a47b580c-d5ca-4b43-a559-d29f1e7f9798/model_v4.tar.gz"]; // example model with swatches

        // Create a bounding box that serves as a placeholder while the asset is loaded.
        // It's best to have the asset's bounding box prior to loading.
        MDLAxisAlignedBoundingBox boundingBox;
        boundingBox.minBounds = (vector_float3){-0.507238686, 0, -0.539075017};
        boundingBox.maxBounds = (vector_float3){0.507238686, 0.876996994, 0.539074898};

        /*
         //
         // Example model with no swatches:
         //

         // Download loactaion of the mesh and texture files needed to render the asset.
         NSURL *downloadURL = [NSURL URLWithString:@"https://paircatalog.blob.core.windows.net/pair-public-catalog/catalog-models/f1e62aa7-4b95-40db-a5c2-395b808acca6/model_v4.tar.gz"];

         // Create a bounding box that serves as a placeholder while the asset is loaded.
         // It's best to have the asset's bounding box prior to loading.
         MDLAxisAlignedBoundingBox boundingBox;
         boundingBox.minBounds = (vector_float3){-0.170000017, 0, -0.325071335};
         boundingBox.maxBounds = (vector_float3){0.170000017, 0.89465636, 0.325071335};
        */

        // PairAssetLoader is an example implementation of how to use the PairAssetLoaderProtocol
        // for downloading and loading of remote models
        PairAssetLoader *pairAssetLoader = [[PairAssetLoader alloc] initWithRemoteDownloadURL:downloadURL
                                                                                 saveLocation:saveLocation
                                                                    andPlaceholderBoundingBox:boundingBox];

        // Create a new PairAsset using a PairAssetLoader (an implementation of the PairAssetLoaderProtocol).
        pairAsset = [[PairAsset alloc] initWithPairAssetLoader:pairAssetLoader];
    }

    // Add PairAsset to the PairView.
    [self.pairView addPairAsset:pairAsset atPoint:self.view.center];

    // Select the newly added PairAsset.
    self.pairView.selectedPairAsset = pairAsset;

    self.baseModelViewMatrix = pairAsset.frame.matrix;
}

- (IBAction)onVideoButtonTouch:(id)sender
{
    if (self.pairView.isRecordingVideo) {
        [self.pairView stopVideoRecording];
        [self.videoButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        [self.videoButton setTitle:@"Record Video" forState:UIControlStateNormal];
    } else {
        [self.pairView startVideoRecording];
        [self.videoButton setTitleColor:UIColor.redColor forState:UIControlStateNormal];
        [self.videoButton setTitle:@"Stop Video" forState:UIControlStateNormal];
    }
}

- (IBAction)onSwapSwatchTouch:(id)sender
{
    for (PairAsset *pairAsset in self.pairView.pairAssets) {
        NSUInteger activeSwatchIndex = pairAsset.activeSwatchIndex + 1;
        if (activeSwatchIndex > pairAsset.numberOfSwatches - 1) {
            pairAsset.activeSwatchIndex = 0;
        } else {
            pairAsset.activeSwatchIndex = activeSwatchIndex;
        }
    }
}

#pragma mark - PairViewModelDelegate

- (void)onDidLoadPairAsset:(nonnull PairAsset *)pairAsset
{
    if (pairAsset.numberOfSwatches > 1) {
        self.swatchButton.hidden = NO;
    }

    self.imageButton.hidden = NO;
    self.videoButton.hidden = NO;
}

- (void)onDidUnloadPairAsset:(nonnull PairAsset *)pairAsset
{
    __block BOOL anAssetHasSwatches = NO;
    [self.pairView.pairAssets enumerateObjectsUsingBlock:^(PairAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.numberOfSwatches > 1) {
            anAssetHasSwatches = YES;
            *stop = YES;
        }
    }];
    self.swatchButton.hidden = !anAssetHasSwatches;

    if (self.pairView.pairAssets.count == 0) {
        self.imageButton.hidden = YES;
        self.videoButton.hidden = YES;
    }
}

- (void)onWillSelecteModel:(nonnull PairAsset *)pairAsset
{
    // Do something when asset is selected.
}

- (void)onWillDeselecteModel:(nonnull PairAsset *)pairAsset
{
    // Do something when asset is deselected.
}

#pragma mark - PairViewRecordingDelegate

- (void)onVideoRecordingSaved:(NSURL *)filePathURL
{
    if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum( filePathURL.path)) {
        UISaveVideoAtPathToSavedPhotosAlbum(filePathURL.path, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
    }
}

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    NSLog(@"Video saved");
}

#pragma mark - PairViewSensorFusionDelegate

- (void)onSensorFusionDidChangeStatus:(nonnull PairSensorFusionStatus *)status
{
    BOOL hideButtons = status.isInitializing;
    self.addButton.hidden = hideButtons;
}

#pragma mark - PairViewRenderDelegate

- (void)willRenderWithSensorFusionData:(nonnull PairSensorFusionData *)data withCameraToScreenMatrix:(GLKMatrix4)cameraToScreen
{
//    GLint fbo = 0;
//    glGetIntegerv(GL_FRAMEBUFFER_BINDING, &fbo);

    // Update
    self.baseModelViewMatrix =  GLKMatrix4MakeTranslation(0.0f, 0.0f, -4.0f);
    self.baseModelViewMatrix = GLKMatrix4Rotate(self.baseModelViewMatrix, _rotation, 0.0f, 1.0f, 0.0f);
    GLKMatrix4 modelViewMatrix = self.pairView.camera.viewMatrix;
    self.baseModelViewMatrix = GLKMatrix4Rotate(self.baseModelViewMatrix, _rotation, 1.0f, 1.0f, 1.0f);
    modelViewMatrix = GLKMatrix4Multiply(modelViewMatrix, self.baseModelViewMatrix);
    _normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix), NULL);
    _modelViewProjectionMatrix = GLKMatrix4Multiply(cameraToScreen, modelViewMatrix);

    // Render
    glBindVertexArrayOES(_vertexArray);
    glUseProgram(_program);
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
    glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, _normalMatrix.m);
    glDrawArrays(GL_TRIANGLES, 0, 36);
    glBindVertexArrayOES(0);
}

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;

    // Create shader program.
    _program = glCreateProgram();

    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }

    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }

    // Attach vertex shader to program.
    glAttachShader(_program, vertShader);

    // Attach fragment shader to program.
    glAttachShader(_program, fragShader);

    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(_program, GLKVertexAttribPosition, "position");
    glBindAttribLocation(_program, GLKVertexAttribNormal, "normal");

    // Link program.
    if (![self linkProgram:_program]) {
        NSLog(@"Failed to link program: %d", _program);

        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }

        return NO;
    }

    // Get uniform locations.
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(_program, "modelViewProjectionMatrix");
    uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(_program, "normalMatrix");

    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }

    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;

    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }

    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);

#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif

    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }

    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);

#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif

    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }

    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;

    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }

    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }

    return YES;
}

@end
