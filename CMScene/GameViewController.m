//
//  GameViewController.m
//  CMScene
//
//  Created by JinJay on 15/7/15.
//  Copyright (c) 2015年 JinJay. All rights reserved.
//

#import "GameViewController.h"
#import "AppDelegate.h"
#import <AVFoundation/AVFoundation.h>

@import GLKit;

@interface GameViewController ()

@property (retain, nonatomic)AVCaptureSession *captureSession;
@property (retain, nonatomic)AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (retain, nonatomic)SCNNode *camera;
@property (retain, nonatomic)SCNView *scnView;
@end

@implementation GameViewController

- (void)initCameraPreviewLayer {
    // capture video as background
    _captureSession = [[AVCaptureSession alloc] init];
    AVCaptureVideoPreviewLayer *videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    AVCaptureDevice* videoDevice = nil;
    NSArray* devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice* device in devices) {
        if ([device position] == AVCaptureDevicePositionBack) {
            videoDevice = device;
        }
    }
    
    if(videoDevice == nil) {
        videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    
    NSError *error;
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    
    if (error) {
        NSLog(@">> ERROR: Couldnt create AVCaptureDeviceInput");
        assert(0);
    }
    [_captureSession addInput:deviceInput];
    [_captureSession startRunning];
    videoPreviewLayer.frame = self.view.bounds;
    [self.view.layer addSublayer:videoPreviewLayer];
}

- (void)initSceneView {
    // create a new scene
    SCNScene *scene = [SCNScene sceneNamed:@"art.scnassets/ship.dae"];
    // create and add a camera to the scene
    _camera = [SCNNode node];
    _camera.camera = [SCNCamera camera];
    [scene.rootNode addChildNode:_camera];
    // place the camera
    _camera.position = SCNVector3Make(0, 0, 0);
    // create and add a light to the scene
    SCNNode *lightNode = [SCNNode node];
    lightNode.light = [SCNLight light];
    lightNode.light.type = SCNLightTypeOmni;
    lightNode.position = SCNVector3Make(0, 10, 10);
    [scene.rootNode addChildNode:lightNode];
    // create and add an ambient light to the scene
    SCNNode *ambientLightNode = [SCNNode node];
    ambientLightNode.light = [SCNLight light];
    ambientLightNode.light.type = SCNLightTypeAmbient;
    ambientLightNode.light.color = [UIColor darkGrayColor];
    [scene.rootNode addChildNode:ambientLightNode];
    
    // retrieve the ship node
    SCNNode *ship = [scene.rootNode childNodeWithName:@"ship" recursively:YES];
    ship.position = SCNVector3Make(0, 0, -15);
    
    [self _addNode2Scene:scene at:SCNVector3Make(0, -5, 15) withAssets:@"SpongeBob.scnassets/SpongeBob.dae" andNode:@"root" andScale:10 andRotation:SCNMatrix4MakeRotation(M_PI, 0, 1, 0)];
    [self _addNode2Scene:scene at:SCNVector3Make(0, 15, 0) withAssets:@"Wally.scnassets/Wally.dae" andNode:@"total" andScale:0.1 andRotation:SCNMatrix4MakeRotation(M_PI_2, 0, 0, 0)];
    [self _addNode2Scene:scene at:SCNVector3Make(0, -15, 0) withAssets:@"Baymax.scnassets/Baymax.dae" andNode:@"root" andScale:8 andRotation:SCNMatrix4MakeRotation(M_PI_2, 0, 0, 0)];
    [self _addNode2Scene:scene at:SCNVector3Make(15, -5, 0) withAssets:@"Baymax2.scnassets/Baymax2.dae" andNode:@"root" andScale:10 andRotation:SCNMatrix4MakeRotation(M_PI_2, 0, -1, 0)];
    [self _addNode2Scene:scene at:SCNVector3Make(-15, -5, 0) withAssets:@"Lnuyasha.scnassets/Lnuyasha.dae" andNode:@"root" andScale:10 andRotation:SCNMatrix4MakeRotation(M_PI_2, 0, 1, 0)];
    
    // retrieve the SCNView
    _scnView = [[SCNView alloc] initWithFrame:self.view.bounds];
    // set the scene to the view
    _scnView.scene = scene;
    // show statistics such as fps and timing information
    _scnView.showsStatistics = YES;
    // configure the view
    _scnView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_scnView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initCameraPreviewLayer];
    [self initSceneView];
}

- (void)_addNode2Scene:(SCNScene *)scene at:(SCNVector3)pos withAssets:(NSString *)assets andNode:(NSString *)node andScale:(float) scale andRotation:(SCNMatrix4)rotation{
    SCNNode *t = [[[SCNScene sceneNamed:assets] rootNode] childNodeWithName:node recursively:YES];
    SCNMatrix4 scaleMatrix = SCNMatrix4MakeScale(scale, scale, scale);
    t.transform = SCNMatrix4Mult(SCNMatrix4Mult(rotation, scaleMatrix), SCNMatrix4MakeTranslation(pos.x, pos.y, pos.z));
    [scene.rootNode addChildNode:t];
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

// MARK: Appear
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self commonInit];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopUpdate];
}

// MARK: CoreMotion
- (void)commonInit{
    CMMotionManager *manager = [(AppDelegate *)[[UIApplication sharedApplication] delegate] sharedManager];
    if (manager.deviceMotionAvailable && ([CMMotionManager availableAttitudeReferenceFrames] & CMAttitudeReferenceFrameXTrueNorthZVertical)) {
        [manager setDeviceMotionUpdateInterval:0.01];
        [manager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXTrueNorthZVertical toQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion * __nullable motion, NSError * __nullable error) {
            if (error == nil) {
                CMRotationMatrix m3 = motion.attitude.rotationMatrix;
            
                GLKMatrix4 m4 = GLKMatrix4Make(m3.m11, m3.m12, m3.m13, 0.0,
                                               m3.m21, m3.m22, m3.m23, 0.0,
                                               m3.m31, m3.m32, m3.m33, 0.0,
                                                  0.0,    0.0,    0.0, 1.0);
                SCNMatrix4 s4 = SCNMatrix4FromGLKMatrix4(m4);
                _camera.transform = SCNMatrix4Mult(s4, SCNMatrix4MakeRotation(M_PI_2, -1, 0, 0));
            }
        }];
    }
}

- (void)stopUpdate{
    CMMotionManager *manager = [(AppDelegate *)[[UIApplication sharedApplication] delegate] sharedManager];
    if (manager.isDeviceMotionActive) {
        [manager stopDeviceMotionUpdates];
    }
}

- (void)refreshFrame:(id)sender {
    [self stopUpdate];
    [self commonInit];
}
@end
