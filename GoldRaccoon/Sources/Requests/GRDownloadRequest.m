//
//  GRDownloadRequest.m
//  GoldRaccoon
//  v1.0.1
//
//  Created by Valentin Radu on 8/23/11.
//  Copyright 2011 Valentin Radu. All rights reserved.
//
//  Modified and/or redesigned by Lloyd Sargent to be ARC compliant.
//  Copyright 2012 Lloyd Sargent. All rights reserved.
//
//  Modified and redesigned by Alberto De Bortoli.
//  Copyright 2013 Alberto De Bortoli. All rights reserved.
//

#import "GRDownloadRequest.h"

@interface GRDownloadRequest ()

@property NSData *receivedData;

@end

@implementation GRDownloadRequest
//生成setter  getter  和 _属性
@synthesize passiveMode;
@synthesize uuid;
@synthesize error;
@synthesize streamInfo;
@synthesize maximumSize;
@synthesize percentCompleted;
@synthesize delegate;
@synthesize didOpenStream;
@synthesize path;

@synthesize receivedData;
@synthesize localFilePath;
@synthesize fullRemotePath;

- (void)start
{
    if ([self.delegate respondsToSelector:@selector(dataAvailable:forRequest:)] == NO) {
        [self.streamInfo streamError:self errorCode:kGRFTPClientMissingRequestDataAvailable];
        NSLog(@"%@", self.error.message);
        return;
    }
    
    // open the read stream and check for errors calling delegate methods
    // if things fail. This encapsulates the streamInfo object and cleans up our code.
    [self.streamInfo openRead:self];
}

- (void)pause{
    // override in subclasses
    self.streamInfo.readStream.delegate = nil;
    [self.streamInfo pause:self];
}
- (void)resume{
    // override in subclasses
    self.streamInfo.readStream.delegate = self;
    [self.streamInfo resume:self];
}

- (NSString *)fullRemotePath
{
    return [[self fullURL] absoluteString];
}

#pragma mark - NSStreamDelegate

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent
{
    // see if we have cancelled the runloop
    if ([self.streamInfo checkCancelRequest:self]) {
        return;
    }
    
    switch (streamEvent) {
        //流已经打开
        case NSStreamEventOpenCompleted: {
            //获取下载流的大小
            self.maximumSize = [[theStream propertyForKey:(id)kCFStreamPropertyFTPResourceSize] integerValue];
            NSLog(@"self.maximumSize = %f",self.maximumSize);
            self.didOpenStream = YES;
            self.streamInfo.bytesTotal = [self.dataSource dateSizeHaveDownloadForRequest:self].longValue;
            self.receivedData = [NSMutableData data];
        
        } 
        break;
        //处理接受过来的数据包
        case NSStreamEventHasBytesAvailable: {
            self.receivedData = [self.streamInfo read:self];
            
            if (self.receivedData) {
                if ([self.delegate respondsToSelector:@selector(dataAvailable:forRequest:)]) {
                    //下载百分比回调self.delegate 是Manager
                    [self.delegate dataAvailable:self.receivedData forRequest:self];
                }
            }else {
                NSLog(@"Stream opened, but failed while trying to read from it.");
                [self.streamInfo streamError:self errorCode:kGRFTPClientCantReadStream];
            }
        } 
        break;
        //可以向发送缓存发送数据
        case NSStreamEventHasSpaceAvailable: {
            
        } 
        break;
        //无法连接或断开连接    
        case NSStreamEventErrorOccurred: {
            [self.streamInfo streamError:self errorCode:[GRError errorCodeWithError:[theStream streamError]]];
            NSLog(@"%@", self.error.message);
        }
        break;
        //连接断开或结束
        case NSStreamEventEndEncountered: {
            [self.streamInfo streamComplete:self];
        }
        break;

        default:
            break;
    }
}


@end
