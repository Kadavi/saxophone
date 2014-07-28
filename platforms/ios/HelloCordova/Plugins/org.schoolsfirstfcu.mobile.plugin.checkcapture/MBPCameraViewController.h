#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

@protocol VideoSourceDelegate <NSObject>

- (void) frameCaptured:(cv::Mat) frame;

@end

@interface MBPCameraViewController : UIViewController<AVCaptureVideoDataOutputSampleBufferDelegate>
@property id<VideoSourceDelegate> delegate;
- (id)initWithCallback:(void(^)(UIImage*))callback titleName:(NSString*)title_ logoFilename:(NSString*)logoFilename_;
@end
