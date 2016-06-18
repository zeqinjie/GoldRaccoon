//
//  GRStreamInfo.m
//  GoldRaccoon
//
//  Created by Valentin Radu on 8/23/11.
//  Copyright 2011 Valentin Radu. All rights reserved.
//
//  Modified and/or redesigned by Lloyd Sargent to be ARC compliant.
//  Copyright 2012 Lloyd Sargent. All rights reserved.
//
//  Modified and redesigned by Alberto De Bortoli.
//  Copyright 2013 Alberto De Bortoli. All rights reserved.
//  request.delegate 是manager

#import "GRStreamInfo.h"
#import "GRRequest.h"
#import "GRDownloadRequest.h"
@interface GRStreamInfo()
//@property (strong, nonatomic) NSRunLoop *readRunLoop;
@end
@implementation GRStreamInfo

@synthesize writeStream;    
@synthesize readStream;
@synthesize bytesThisIteration;
@synthesize bytesTotal;
@synthesize timeout;
@synthesize cancelRequestFlag;
@synthesize cancelDoesNotCallDelegate;

/**
 @brief dispatch_get_local_queue() is designed to get our local queue, if it exists, or create one if it doesn't exist.
 @return queue of type dispatch_queue_t
 */
dispatch_queue_t dispatch_get_local_queue()
{
    static dispatch_queue_t _queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _queue = dispatch_queue_create("com.github.goldraccoon", 0);
        dispatch_queue_set_specific(_queue, "com.github.goldraccoon", (void *) "com.github.goldraccoon", NULL);
    });
    return _queue;
}

//开启读取流
- (void)openRead:(GRRequest *)request
{
    if ([request.dataSource hostnameForRequest:request] == nil) {
        NSLog(@"The host name is nil!");
        request.error = [[GRError alloc] init];
        request.error.errorCode = kGRFTPClientHostnameIsNil;
        [request.delegate requestFailed: request];
        [request.streamInfo close: request];
        return;
    }
    
    // a little bit of C because I was not able to make NSInputStream play nice ,dataSource is Manager
    //设置流属性
    CFReadStreamRef readStreamRef = CFReadStreamCreateWithFTPURL(NULL, ( __bridge CFURLRef) request.fullURL);
    CFReadStreamSetProperty(readStreamRef, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
	CFReadStreamSetProperty(readStreamRef, kCFStreamPropertyFTPUsePassiveMode, request.passiveMode ? kCFBooleanTrue :kCFBooleanFalse);
    CFReadStreamSetProperty(readStreamRef, kCFStreamPropertyFTPFetchResourceInfo, kCFBooleanTrue);
    if ([request.dataSource usernameForRequest:request].length) {
        CFReadStreamSetProperty(readStreamRef, kCFStreamPropertyFTPUserName, (__bridge CFStringRef) [request.dataSource usernameForRequest:request]);
    }
    if ([request.dataSource passwordForRequest:request].length) {
        CFReadStreamSetProperty(readStreamRef, kCFStreamPropertyFTPPassword, (__bridge CFStringRef) [request.dataSource passwordForRequest:request]);
    }
    
    if ([request isKindOfClass:[GRDownloadRequest class]]) {
        GRDownloadRequest *downRequest = (GRDownloadRequest *)request;
        CFReadStreamSetProperty(readStreamRef, kCFStreamPropertyFTPFileTransferOffset, (__bridge  CFNumberRef) [request.dataSource dateSizeHaveDownloadForRequest:downRequest]);
    }
    
    readStream = ( __bridge_transfer NSInputStream *) readStreamRef;
    
    if (readStream == nil) {
        NSLog(@"Can't open the read stream! Possibly wrong URL");
        request.error = [[GRError alloc] init];
        request.error.errorCode = kGRFTPClientCantOpenStream;
        [request.delegate requestFailed: request];
        [request.streamInfo close: request];
        return;
    }
    //设置流代理对象
    readStream.delegate = request;
//    self.readRunLoop = [NSRunLoop currentRunLoop];
	[readStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    //NSRunLoopCommonModes
//    [self.readRunLoop runUntilDate:[NSDate distantFuture]];
//    NSLog(@" self.readRunLoop = %p", self.readRunLoop);
	[readStream open];
    
    request.didOpenStream = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, timeout * NSEC_PER_SEC), dispatch_get_local_queue(), ^{
        if (!request.didOpenStream && request.error == nil)
        {
            NSLog(@"No response from the server. Timeout.");
            request.error = [[GRError alloc] init];
            request.error.errorCode = kGRFTPClientStreamTimedOut;
            [request.delegate requestFailed: request];
            [request.streamInfo close: request];
        }
    });
}

- (void)openWrite:(GRRequest *)request
{
    if ([request.dataSource hostnameForRequest:request] == nil) {
        NSLog(@"The host name is nil!");
        request.error = [[GRError alloc] init];
        request.error.errorCode = kGRFTPClientHostnameIsNil;
        [request.delegate requestFailed: request];
        [request.streamInfo close: request];
        return;
    }

    CFWriteStreamRef writeStreamRef = CFWriteStreamCreateWithFTPURL(NULL, ( __bridge CFURLRef) request.fullURL);
//    CFWriteStreamSetProperty(writeStreamRef, kCFStreamPropertyFTPAttemptPersistentConnection, kCFBooleanFalse);
    CFWriteStreamSetProperty(writeStreamRef, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
	CFWriteStreamSetProperty(writeStreamRef, kCFStreamPropertyFTPUsePassiveMode, request.passiveMode ? kCFBooleanTrue :kCFBooleanFalse);
    CFWriteStreamSetProperty(writeStreamRef, kCFStreamPropertyFTPFetchResourceInfo, kCFBooleanTrue);
    if ([request.dataSource usernameForRequest:request].length) {
        CFWriteStreamSetProperty(writeStreamRef, kCFStreamPropertyFTPUserName, (__bridge CFStringRef) [request.dataSource usernameForRequest:request]);
    }
    if([request.dataSource passwordForRequest:request].length){
        CFWriteStreamSetProperty(writeStreamRef, kCFStreamPropertyFTPPassword, (__bridge CFStringRef) [request.dataSource passwordForRequest:request]);
    }
    writeStream = ( __bridge_transfer NSOutputStream *) writeStreamRef;
    
    if (writeStream == nil) {
        NSLog(@"Can't open the write stream! Possibly wrong URL!");
        request.error = [[GRError alloc] init];
        request.error.errorCode = kGRFTPClientCantOpenStream;
        [request.delegate requestFailed: request];
        [request.streamInfo close: request];
        return;
    }
    
    writeStream.delegate = request;
    [writeStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [writeStream open];
    
    request.didOpenStream = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, timeout * NSEC_PER_SEC), dispatch_get_local_queue(), ^{
        if (!request.didOpenStream && (request.error == nil)) {
            NSLog(@"No response from the server. Timeout.");
            request.error = [[GRError alloc] init];
            request.error.errorCode = kGRFTPClientStreamTimedOut;
            [request.delegate requestFailed:request];
            [request.streamInfo close: request];
        }
    });
}

- (BOOL)checkCancelRequest:(GRRequest *)request
{
    if (!cancelRequestFlag) {
        return NO;
    }
    
    // see if we don't want to call the delegate (set and forget)
    if (cancelDoesNotCallDelegate == YES) {
        [request.streamInfo close: request];
    }
    
    // otherwise indicate that the request to cancel was completed
    else {
        [request.delegate requestCompleted: request];
        [request.streamInfo close: request];
    }
    
    return YES;
}

- (NSData *)read:(GRRequest *)request
{
    NSData *data;
    NSMutableData *bufferObject = [NSMutableData dataWithLength:kGRDefaultBufferSize];
    
    bytesThisIteration = [readStream read:(UInt8 *)[bufferObject bytes] maxLength:kGRDefaultBufferSize];
    bytesTotal += bytesThisIteration;
    
    // return the data
    if (bytesThisIteration > 0) {
        data = [NSData dataWithBytes:(UInt8 *)[bufferObject bytes] length:bytesThisIteration];
        request.percentCompleted = bytesTotal / request.maximumSize;
        
        if ([request.delegate respondsToSelector:@selector(percentCompleted:forRequest:)]) {
            //下载完成百分比  request.delegate 是manager
            [request.delegate percentCompleted:request.percentCompleted forRequest:request];
        }
        
        return data;
    }
    
    // return no data, but this isn't an error... just the end of the file
    else if (bytesThisIteration == 0) {
        return [NSData data]; // returns empty data object - means no error, but no data
    }
    // otherwise we had an error, return an error
    [self streamError: request errorCode:kGRFTPClientCantReadStream];
    NSLog(@"%@", request.error.message);
    
    return nil;
}

- (BOOL)write:(GRRequest *)request data:(NSData *)data
{
    bytesThisIteration = [writeStream write:[data bytes] maxLength:[data length]];
    bytesTotal += bytesThisIteration;
            
    if (bytesThisIteration > 0) {
        request.percentCompleted = bytesTotal / request.maximumSize;
        if ([request.delegate respondsToSelector:@selector(percentCompleted:forRequest:)]) {
            //写数据到服务器  是上传百分比  request.delegate是manager
            [request.delegate percentCompleted:request.percentCompleted forRequest:request];
        }
        
        return YES;
    }
    
    if (bytesThisIteration == 0) {
        return YES;
    }
    
    [self streamError: request errorCode:kGRFTPClientCantWriteStream]; // perform callbacks and close out streams
    NSLog(@"%@", request.error.message);

    return NO;
}

- (void)close:(GRRequest *)request
{
    if (readStream) {
        [readStream close];
        [readStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        readStream = nil;
    }
    
    if (writeStream) {
        [writeStream close];
        [writeStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        writeStream = nil;
    }
    
    request.streamInfo = nil;
}

//暂停
- (void)pause:(GRRequest *)request{
    [readStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

//继续
- (void)resume:(GRRequest *)request{
    [readStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

//代理回调
- (void)streamError:(GRRequest *)request errorCode:(enum GRErrorCodes)errorCode
{
    request.error = [[GRError alloc] init];
    request.error.errorCode = errorCode;
    [request.delegate requestFailed: request];
    [request.streamInfo close: request];
}

- (void)streamComplete:(GRRequest *)request
{
    [request.delegate requestCompleted: request];
    [request.streamInfo close: request];
}

@end
