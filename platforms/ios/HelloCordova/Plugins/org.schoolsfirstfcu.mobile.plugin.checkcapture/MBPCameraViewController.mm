#import "MBPCameraViewController.h"

#import <Cordova/CDV.h>
#import "opencv2/highgui/highgui.hpp"



@implementation MBPCameraViewController {
    void(^_callback)(UIImage*);
    AVCaptureSession *_captureSession;
    AVCaptureDevice *_rearCamera;
    AVCaptureStillImageOutput *_stillImageOutput;
    UIView *_buttonPanel;
    UIView *_headerPanel;
    UIImageView *_logoPanel;
    UILabel *_titlePanel;
    UIView *_topFramePanel;
    UIView *_leftFramePanel;
    UIButton *_captureButton;
    NSString *_logoFilename;
    NSString *_title;
    UIButton *_backButton;
    UIColor *_headerPanelColor;
    UIColor *_framePanelColor;
    //UIImageView *_topLeftGuide;
    //UIImageView *_topRightGuide;
    //UIImageView *_bottomLeftGuide;
    //UIImageView *_bottomRightGuide;
    UIActivityIndicatorView *_activityIndicator;
    
    AVCaptureVideoDataOutput *captureOutput;
    
    
}

@synthesize delegate;

static const CGFloat kHeaderHeightPhone = 56;
static const CGFloat kFrameBorderSizePhone = 20;
static const CGFloat kTitleFontSize = 14;
static const CGFloat kCaptureButtonWidthPhone = 60;
static const CGFloat kCaptureButtonHeightPhone = 36;
static const CGFloat kCaptureButtonRadiusPhone = 12;

//static const CGFloat kBackButtonWidthPhone = 100;
//static const CGFloat kBackButtonHeightPhone = 40;
static const CGFloat kBorderImageWidthPhone = 50;
static const CGFloat kBorderImageHeightPhone = 50;
static const CGFloat kHorizontalInsetPhone = 15;
static const CGFloat kVerticalInsetPhone = 25;
static const CGFloat kCaptureButtonVerticalInsetPhone = 6;

static const CGFloat kCaptureButtonWidthTablet = 75;
static const CGFloat kCaptureButtonHeightTablet = 75;
//static const CGFloat kBackButtonWidthTablet = 150;
//static const CGFloat kBackButtonHeightTablet = 50;
static const CGFloat kBorderImageWidthTablet = 50;
static const CGFloat kBorderImageHeightTablet = 50;
static const CGFloat kHorizontalInsetTablet = 100;
static const CGFloat kVerticalInsetTablet = 50;
static const CGFloat kCaptureButtonVerticalInsetTablet = 20;

static const CGFloat kAspectRatio = 125.0f / 86;

- (id)initWithCallback:(void(^)(UIImage*))callback titleName:(NSString*)title_ logoFilename:(NSString*)logoFilename_ {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _callback = callback;
        _captureSession = [[AVCaptureSession alloc] init];
        _captureSession.sessionPreset = AVCaptureSessionPresetPhoto;
        
        _title = title_;
        _logoFilename = logoFilename_;
        _headerPanelColor = [UIColor colorWithRed: 45.0/255.0 green: 68.0/255.0 blue:82.0/255.0 alpha:1.0f];
        _framePanelColor = [UIColor colorWithRed: 185.0/255.0 green: 199.0/255.0 blue:212.0/255.0 alpha:150.0/255.0];
    }
    return self;
}

- (void)dealloc {
    [_captureSession stopRunning];
}

- (void)loadView {
    self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.view.backgroundColor = [UIColor blackColor];
    AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_captureSession];
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    previewLayer.frame = self.view.bounds;
    [[self.view layer] addSublayer:previewLayer];
    [self.view addSubview:[self createOverlay]];
    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _activityIndicator.center = self.view.center;
    [self.view addSubview:_activityIndicator];
    [_activityIndicator startAnimating];
}

- (UIView*)createOverlay {
    UIView *overlay = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    _headerPanel = [[UIImageView alloc] initWithFrame:CGRectZero];
    [_headerPanel setBackgroundColor: _headerPanelColor];
    
    UIImage *logoImage = [UIImage imageNamed: _logoFilename];
    UIImage *logoImageScaled = [UIImage imageWithCGImage:[logoImage CGImage] scale:(logoImage.scale * 1.5) orientation:(logoImage.imageOrientation)];
    _logoPanel = [[UIImageView alloc] initWithFrame:CGRectZero];
    [_logoPanel setImage: logoImageScaled];
    [_logoPanel setTransform:CGAffineTransformMakeRotation(90 * M_PI / 180)];
    [_headerPanel addSubview:_logoPanel];
    [overlay addSubview:_headerPanel];
    
    _topFramePanel = [[UIView alloc] initWithFrame:CGRectZero];
    [_topFramePanel setBackgroundColor: _framePanelColor];
    [overlay addSubview:_topFramePanel];
    
    _leftFramePanel = [[UIView alloc] initWithFrame:CGRectZero];
    [_leftFramePanel setBackgroundColor: _framePanelColor];
    [overlay addSubview:_leftFramePanel];
    
    _titlePanel = [[UILabel alloc] initWithFrame:CGRectZero];
    [_titlePanel setText:_title];
    [_titlePanel setFont:[UIFont boldSystemFontOfSize: kTitleFontSize]];
    [_titlePanel setTextColor: [UIColor colorWithWhite: 0.0f alpha: 1.0f ]];
    [_titlePanel setTransform: CGAffineTransformMakeRotation(90 * M_PI / 180)];
    [_titlePanel setBackgroundColor: _framePanelColor];
    [overlay addSubview:_titlePanel];
    
    _buttonPanel = [[UIView alloc] initWithFrame:CGRectZero];
    [_buttonPanel setBackgroundColor:_framePanelColor];
    [overlay addSubview:_buttonPanel];
    
    _captureButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_captureButton setBackgroundColor:[UIColor colorWithWhite:1.0f alpha:1.0f]];
    //[_captureButton setImage:[self imageWithColor:[UIColor colorWithWhite:0.2f alpha:1.0f] forState:UIControlStateNormal];
    //[_captureButton setImage:[self imageWithColor:[UIColor colorWithWhite:0.9f alpha:1.0f] forState:UIControlStateHighlighted];
    [_captureButton addTarget:self action:@selector(takePictureWaitingForCameraToFocus) forControlEvents:UIControlEventTouchUpInside];
    
    //[_captureButton setImage:[UIImage imageNamed:@"www/img/cameraoverlay/capture_button.png"] forState:UIControlStateNormal];
    //[_captureButton setImage:[UIImage imageNamed:@"www/img/cameraoverlay/capture_button_pressed.png"] forState:UIControlStateHighlighted];
    //[_captureButton addTarget:self action:@selector(takePictureWaitingForCameraToFocus) forControlEvents:UIControlEventTouchUpInside];
    [overlay addSubview:_captureButton];
    
    /*_backButton = [UIButton buttonWithType:UIButtonTypeCustom];
     [_backButton setBackgroundImage:[UIImage imageNamed:@"www/img/cameraoverlay/back_button.png"] forState:UIControlStateNormal];
     [_backButton setBackgroundImage:[UIImage imageNamed:@"www/img/cameraoverlay/back_button_pressed.png"] forState:UIControlStateHighlighted];
     [_backButton setTitle:@"Cancel" forState:UIControlStateNormal];
     [_backButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
     [[_backButton titleLabel] setFont:[UIFont systemFontOfSize:18]];
     [_backButton addTarget:self action:@selector(dismissCameraPreview) forControlEvents:UIControlEventTouchUpInside];
     [overlay addSubview:_backButton];
     
     
     _topLeftGuide = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"www/img/cameraoverlay/border_top_left.png"]];
     [overlay addSubview:_topLeftGuide];
     
     _topRightGuide = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"www/img/cameraoverlay/border_top_right.png"]];
     [overlay addSubview:_topRightGuide];
     
     _bottomLeftGuide = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"www/img/cameraoverlay/border_bottom_left.png"]];
     [overlay addSubview:_bottomLeftGuide];
     
     _bottomRightGuide = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"www/img/cameraoverlay/border_bottom_right.png"]];
     [overlay addSubview:_bottomRightGuide];
     */
    
    return overlay;
}

- (void)viewWillLayoutSubviews {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self layoutForTablet];
    } else {
        [self layoutForPhone];
    }
}

- (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)layoutForPhone {
    CGRect bounds = [[UIScreen mainScreen] bounds];
    
    NSInteger height = bounds.size.height;
    NSInteger width = bounds.size.width - kHeaderHeightPhone;
    NSInteger logoSizeW = _logoPanel.image.size.width;
    NSInteger logoSizeH =_logoPanel.image.size.height;
    
    
    _captureButton.frame = CGRectMake((((width) / 2) - (kCaptureButtonWidthPhone / 2)),
                                      bounds.size.height - kCaptureButtonHeightPhone - kCaptureButtonVerticalInsetPhone,
                                      kCaptureButtonWidthPhone,
                                      kCaptureButtonHeightPhone);
    _captureButton.layer.cornerRadius = kCaptureButtonRadiusPhone;
    
    _buttonPanel.frame = CGRectMake(0,
                                    CGRectGetMinY(_captureButton.frame) - kCaptureButtonVerticalInsetPhone,
                                    bounds.size.width - kHeaderHeightPhone,
                                    kCaptureButtonHeightPhone + (kCaptureButtonVerticalInsetPhone * 2));
    
    _headerPanel.frame = CGRectMake(width, 0, kHeaderHeightPhone, height);
    
    
    
    _logoPanel.frame = CGRectMake((kHeaderHeightPhone - logoSizeH)/ 2, (height - logoSizeW) / 2 , logoSizeH, logoSizeW);
    
    _topFramePanel.frame = CGRectMake(0, 0, width, kFrameBorderSizePhone);
    
    _leftFramePanel.frame =CGRectMake(0, kFrameBorderSizePhone, kFrameBorderSizePhone, height - kFrameBorderSizePhone  - _buttonPanel.frame.size.height);
    
    _titlePanel.frame = CGRectMake(width - kFrameBorderSizePhone, kFrameBorderSizePhone, kFrameBorderSizePhone, height -kFrameBorderSizePhone - _buttonPanel.frame.size.height);
    /*
     _backButton.frame = CGRectMake((CGRectGetMinX(_captureButton.frame) - kBackButtonWidthPhone) / 2,
     CGRectGetMinY(_captureButton.frame) + ((kCaptureButtonHeightPhone - kBackButtonHeightPhone) / 2),
     kBackButtonWidthPhone,
     kBackButtonHeightPhone);
     */
    
    CGFloat screenAspectRatio = bounds.size.height / bounds.size.width;
    if (screenAspectRatio <= 1.5f) {
        [self layoutForPhoneWithShortScreen];
    } else {
        [self layoutForPhoneWithTallScreen];
    }
}

- (void)layoutForPhoneWithShortScreen {
    /*
     CGRect bounds = [[UIScreen mainScreen] bounds];
     CGFloat verticalInset = 5;
     CGFloat height = CGRectGetMinY(_buttonPanel.frame) - (verticalInset * 2);
     CGFloat width = height / kAspectRatio;
     CGFloat horizontalInset = (bounds.size.width - width) / 2;
     
     
     _topLeftGuide.frame = CGRectMake(horizontalInset,
     verticalInset,
     kBorderImageWidthPhone,
     kBorderImageHeightPhone);
     
     _topRightGuide.frame = CGRectMake(bounds.size.width - kBorderImageWidthPhone - horizontalInset,
     verticalInset,
     kBorderImageWidthPhone,
     kBorderImageHeightPhone);
     
     _bottomLeftGuide.frame = CGRectMake(CGRectGetMinX(_topLeftGuide.frame),
     CGRectGetMinY(_topLeftGuide.frame) + height - kBorderImageHeightPhone,
     kBorderImageWidthPhone,
     kBorderImageHeightPhone);
     
     _bottomRightGuide.frame = CGRectMake(CGRectGetMinX(_topRightGuide.frame),
     CGRectGetMinY(_topRightGuide.frame) + height - kBorderImageHeightPhone,
     kBorderImageWidthPhone,
     kBorderImageHeightPhone);
     */
}

- (void)layoutForPhoneWithTallScreen {
    /*
     CGRect bounds = [[UIScreen mainScreen] bounds];
     
     _topLeftGuide.frame = CGRectMake(kHorizontalInsetPhone, kVerticalInsetPhone, kBorderImageWidthPhone, kBorderImageHeightPhone);
     
     _topRightGuide.frame = CGRectMake(bounds.size.width - kBorderImageWidthPhone - kHorizontalInsetPhone,
     kVerticalInsetPhone,
     kBorderImageWidthPhone,
     kBorderImageHeightPhone);
     
     CGFloat height = (CGRectGetMaxX(_topRightGuide.frame) - CGRectGetMinX(_topLeftGuide.frame)) * kAspectRatio;
     
     _bottomLeftGuide.frame = CGRectMake(CGRectGetMinX(_topLeftGuide.frame),
     CGRectGetMinY(_topLeftGuide.frame) + height - kBorderImageHeightPhone,
     kBorderImageWidthPhone,
     kBorderImageHeightPhone);
     
     _bottomRightGuide.frame = CGRectMake(CGRectGetMinX(_topRightGuide.frame),
     CGRectGetMinY(_topRightGuide.frame) + height - kBorderImageHeightPhone,
     kBorderImageWidthPhone,
     kBorderImageHeightPhone);
     */
}

- (void)layoutForTablet {
    CGRect bounds = [[UIScreen mainScreen] bounds];
    
    _captureButton.frame = CGRectMake((bounds.size.width / 2) - (kCaptureButtonWidthTablet / 2),
                                      bounds.size.height - kCaptureButtonHeightTablet - kCaptureButtonVerticalInsetTablet,
                                      kCaptureButtonWidthTablet,
                                      kCaptureButtonHeightTablet);
    /*
     _backButton.frame = CGRectMake((CGRectGetMinX(_captureButton.frame) - kBackButtonWidthTablet) / 2,
     CGRectGetMinY(_captureButton.frame) + ((kCaptureButtonHeightTablet - kBackButtonHeightTablet) / 2),
     kBackButtonWidthTablet,
     kBackButtonHeightTablet);
     
     */
    _buttonPanel.frame = CGRectMake(0,
                                    CGRectGetMinY(_captureButton.frame) - kCaptureButtonVerticalInsetTablet,
                                    bounds.size.width,
                                    kCaptureButtonHeightTablet + (kCaptureButtonVerticalInsetTablet * 2));
    
    /*
     _topLeftGuide.frame = CGRectMake(kHorizontalInsetTablet, kVerticalInsetTablet, kBorderImageWidthTablet, kBorderImageHeightTablet);
     
     _topRightGuide.frame = CGRectMake(bounds.size.width - kBorderImageWidthTablet - kHorizontalInsetTablet,
     kVerticalInsetTablet,
     kBorderImageWidthTablet,
     kBorderImageHeightTablet);
     
     CGFloat height = (CGRectGetMaxX(_topRightGuide.frame) - CGRectGetMinX(_topLeftGuide.frame)) * kAspectRatio;
     
     _bottomLeftGuide.frame = CGRectMake(CGRectGetMinX(_topLeftGuide.frame),
     CGRectGetMinY(_topLeftGuide.frame) + height - kBorderImageHeightTablet,
     kBorderImageWidthTablet,
     kBorderImageHeightTablet);
     
     _bottomRightGuide.frame = CGRectMake(CGRectGetMinX(_topRightGuide.frame),
     CGRectGetMinY(_topRightGuide.frame) + height - kBorderImageHeightTablet,
     kBorderImageWidthTablet,
     kBorderImageHeightTablet);
     */
}

- (void)viewDidLoad {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        for (AVCaptureDevice *device in [AVCaptureDevice devices]) {
            if ([device hasMediaType:AVMediaTypeVideo] && [device position] == AVCaptureDevicePositionBack) {
                _rearCamera = device;
            }
        }
        AVCaptureDeviceInput *cameraInput = [AVCaptureDeviceInput deviceInputWithDevice:_rearCamera error:nil];
        [_captureSession addInput:cameraInput];
        _stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
        [_captureSession addOutput:_stillImageOutput];
        [_captureSession startRunning];
        dispatch_async(dispatch_get_main_queue(), ^{
            [_activityIndicator stopAnimating];
        });
        
        captureOutput = [[AVCaptureVideoDataOutput alloc] init];
        captureOutput.alwaysDiscardsLateVideoFrames = YES;
        
        // Set the video output to store frame in BGRA (It is supposed to be faster)
        // NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
        //NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
        //NSDictionary* videoSettings = [NSDictionary dictionaryWithObject:value forKey:key];
        //[captureOutput setVideoSettings:videoSettings];
        
        /*We create a serial queue to handle the processing of our frames*/
        dispatch_queue_t queue;
        queue = dispatch_queue_create("com.computer-vision-talks.cameraQueue", NULL);
        [captureOutput setSampleBufferDelegate:self queue:queue];
        dispatch_release(queue);
        
        [_captureSession addOutput:captureOutput];
    });
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    return orientation == UIDeviceOrientationPortrait;
}

- (void)dismissCameraPreview {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)takePictureWaitingForCameraToFocus {
    if (_rearCamera.adjustingFocus) {
        [_rearCamera addObserver:self forKeyPath:@"adjustingFocus" options:NSKeyValueObservingOptionNew context:nil];
    } else {
        [self takePicture];
    }
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    if ([keyPath isEqualToString:@"adjustingFocus"] && !_rearCamera.adjustingFocus) {
        [_rearCamera removeObserver:self forKeyPath:@"adjustingFocus"];
        [self takePicture];
    }
}

- (void)takePicture {
    AVCaptureConnection *videoConnection = [self videoConnectionToOutput:_stillImageOutput];
    [_stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
        _callback([UIImage imageWithData:imageData]);
    }];
}

- (AVCaptureConnection*)videoConnectionToOutput:(AVCaptureOutput*)output {
    for (AVCaptureConnection *connection in output.connections) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
                return connection;
            }
        }
    }
    return nil;
}

#pragma mark -
#pragma mark AVCaptureSession delegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    /*Lock the image buffer*/
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    
    /*Get information about the image*/
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    size_t stride = CVPixelBufferGetBytesPerRow(imageBuffer);
    
    cv::Mat frame(height, width, CV_8UC4, (void*)baseAddress, stride);
    
    
    
    /*
     cv::Vec4b tlPixel = frame.at<cv::Vec4b>(0,0);
     cv::Vec4b trPixel = frame.at<cv::Vec4b>(0,width - 1);
     cv::Vec4b blPixel = frame.at<cv::Vec4b>(height-1, 0);
     cv::Vec4b brPixel = frame.at<cv::Vec4b>(height-1, width - 1);
     
     
     std::cout << "TL: " << (int)tlPixel[0] << " " << (int)tlPixel[1] << " " << (int)tlPixel[2] << std::endl
     << "TR: " << (int)trPixel[0] << " " << (int)trPixel[1] << " " << (int)trPixel[2] << std::endl
     << "BL: " << (int)blPixel[0] << " " << (int)blPixel[1] << " " << (int)blPixel[2] << std::endl
     << "BR: " << (int)brPixel[0] << " " << (int)brPixel[1] << " " << (int)brPixel[2] << std::endl;
     */
    //[delegate frameCaptured:frame];
    
    /*We unlock the  image buffer*/
	CVPixelBufferUnlockBaseAddress(imageBuffer,0);
}


// Create a UIImage from sample buffer data
- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // Create an image object from the Quartz image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    
    // Release the Quartz image
    CGImageRelease(quartzImage);
    
    return (image);
}
@end
