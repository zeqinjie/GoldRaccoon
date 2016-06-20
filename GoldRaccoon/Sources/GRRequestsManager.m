//
//  GRRequestsManager.m
//  GoldRaccoon
//  v1.0.1
//
//  Created by Alberto De Bortoli on 14/06/2013.
//  Copyright 2013 Alberto De Bortoli. All rights reserved.
//

#import "GRRequestsManager.h"

#import "GRListingRequest.h"
#import "GRCreateDirectoryRequest.h"
#import "GRUploadRequest.h"
#import "GRDownloadRequest.h"
#import "GRDeleteRequest.h"

#import "GRQueue.h"

@interface GRRequestsManager () <GRRequestDelegate, GRRequestDataSource>

@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, strong) GRQueue *requestQueue;
@property (nonatomic, strong) GRRequest *currentRequest;

- (id<GRRequestProtocol>)_addRequestOfType:(Class)clazz withPath:(NSString *)filePath;
- (id<GRDataExchangeRequestProtocol>)_addDataExchangeRequestOfType:(Class)clazz withLocalPath:(NSString *)localPath remotePath:(NSString *)remotePath;
- (void)_enqueueRequest:(id<GRRequestProtocol>)request;
- (void)_processNextRequest;

@end

@implementation GRRequestsManager
{
    //当前下载数据 服务器appendData
    NSMutableData *_currentDownloadData;
    //已经下载的数据
    NSData *_haveDownloadData;
    //当前上传数据 本地获取
    NSData *_currentUploadData;
    
    BOOL _isRunning;
    
@private
    BOOL _delegateRespondsToPercentProgress;
}

@synthesize hostname = _hostname;
@synthesize delegate = _delegate;

#pragma mark - Dealloc and Initialization

- (instancetype)init
{
    NSAssert(NO, @"Initializer not allowed. Use designated initializer initWithHostname:username:password:");
    return nil;
}

- (instancetype)initWithHostname:(NSString *)hostname user:(NSString *)username password:(NSString *)password
{
    NSAssert([hostname length], @"hostname must not be nil");
    self = [super init];
    if (self) {
        _hostname = hostname;
        _username = username;
        _password = password;
        _requestQueue = [[GRQueue alloc] init];
        _isRunning = NO;
        _delegateRespondsToPercentProgress = NO;
    }
    NSLog(@"manager address = %p",self);
    return self;
}

- (void)dealloc
{
    NSLog(@"dealloc manager address = %p",self);
    [self stopAndCancelAllRequests];
}

#pragma mark - Setters

- (void)setDelegate:(id<GRRequestsManagerDelegate>)delegate
{
    if (_delegate != delegate) {
        _delegate = delegate;
        _delegateRespondsToPercentProgress = [_delegate respondsToSelector:@selector(requestsManager:didCompletePercent:forRequest:)];
    }
}

- (void)setBlock:(FTPManCompStateBlock)block{
    _block = block;
    _delegateRespondsToPercentProgress = YES;
}
#pragma mark - Public Methods

- (void)startProcessingRequests
{
    if (_isRunning == NO) {
        _isRunning = YES;
        [self _processNextRequest];
    }
}

- (void)stopAndCancelAllRequests
{
    [self.requestQueue clear];
    self.currentRequest.cancelDoesNotCallDelegate = TRUE;
    [self.currentRequest cancelRequest];
    self.currentRequest = nil;
    _isRunning = NO;
}

- (BOOL)cancelRequest:(GRRequest *)request
{
    return [self.requestQueue removeObject:request];
}

//暂停
- (void)pause{
    [self.currentRequest pause];
}
//继续
- (void)resume{
    [self.currentRequest resume];
}

- (void)start{
    [self.currentRequest start];
}

#pragma mark - FTP Actions

- (id<GRRequestProtocol>)addRequestForListDirectoryAtPath:(NSString *)path
{
    NSLog(@" path = %@",path);
    return [self _addRequestOfType:[GRListingRequest class] withPath:path];
}

- (id<GRRequestProtocol>)addRequestForCreateDirectoryAtPath:(NSString *)path
{
    return [self _addRequestOfType:[GRCreateDirectoryRequest class] withPath:path];
}

- (id<GRRequestProtocol>)addRequestForDeleteFileAtPath:(NSString *)filePath
{
    return [self _addRequestOfType:[GRDeleteRequest class] withPath:filePath];
}

- (id<GRRequestProtocol>)addRequestForDeleteDirectoryAtPath:(NSString *)path
{
    return [self _addRequestOfType:[GRDeleteRequest class] withPath:path];
}

- (id<GRDataExchangeRequestProtocol>)addRequestForDownloadFileAtRemotePath:(NSString *)remotePath toLocalPath:(NSString *)localPath
{
    return [self _addDataExchangeRequestOfType:[GRDownloadRequest class] withLocalPath:localPath remotePath:remotePath];
}

- (id<GRDataExchangeRequestProtocol>)addRequestForUploadFileAtLocalPath:(NSString *)localPath toRemotePath:(NSString *)remotePath
{
    return [self _addDataExchangeRequestOfType:[GRUploadRequest class] withLocalPath:localPath remotePath:remotePath];
}

#pragma mark - GRRequestDelegate required
//请求完成
- (void)requestCompleted:(GRRequest *)request
{
    // listing request
    if ([request isKindOfClass:[GRListingRequest class]]) {
        NSMutableArray *listing = [NSMutableArray array];
        for (NSDictionary *file in ((GRListingRequest *)request).filesInfo) {
            [listing addObject:[file objectForKey:(id)kCFFTPResourceName]];
        }
        if ([self.delegate respondsToSelector:@selector(requestsManager:didCompleteListingRequest:listing:)]) {
            [self.delegate requestsManager:self
                 didCompleteListingRequest:((GRListingRequest *)request)
                                   listing:listing];
        }
        
        if (self.block) {
            self.block(self,((GRListingRequest *)request),0,nil,listing,nil,FTPManagerTypeDidCompleteListing);
        }
    }
    
    // create directory request
    if ([request isKindOfClass:[GRCreateDirectoryRequest class]]) {
        if ([self.delegate respondsToSelector:@selector(requestsManager:didCompleteCreateDirectoryRequest:)]) {
            [self.delegate requestsManager:self didCompleteCreateDirectoryRequest:(GRUploadRequest *)request];
        }
        
        if (self.block) {
            self.block(self,(GRUploadRequest *)request,0,nil,nil,nil,FTPManagerTypeDidCompleteCreateDirectory);
        }
    }
    
    // delete request
    if ([request isKindOfClass:[GRDeleteRequest class]]) {
        if ([self.delegate respondsToSelector:@selector(requestsManager:didCompleteDeleteRequest:)]) {
            [self.delegate requestsManager:self didCompleteDeleteRequest:(GRUploadRequest *)request];
        }
        
        if (self.block) {
            self.block(self,(GRUploadRequest *)request,0,nil,nil,nil,FTPManagerTypeDidCompleteDelete);
        }
    }
    
    // upload request
    if ([request isKindOfClass:[GRUploadRequest class]]) {
        if ([self.delegate respondsToSelector:@selector(requestsManager:didCompleteUploadRequest:)]) {
            [self.delegate requestsManager:self didCompleteUploadRequest:(GRUploadRequest *)request];
        }
        
        if (self.block) {
            self.block(self,(GRUploadRequest *)request,0,nil,nil,nil,FTPManagerTypeDidCompleteUpload);
        }
        
        _currentUploadData = nil;
    }
    
    // download request
    else if ([request isKindOfClass:[GRDownloadRequest class]]) {
        /*
         NSError *writeError = nil;
         BOOL writeToFileSucceeded = [_currentDownloadData writeToFile:((GRDownloadRequest *)request).localFilePath
         options:NSDataWritingAtomic
         error:&writeError];
         
         if (writeToFileSucceeded && !writeError) {
         if ([self.delegate respondsToSelector:@selector(requestsManager:didCompleteDownloadRequest:)]) {
         [self.delegate requestsManager:self didCompleteDownloadRequest:(GRDownloadRequest *)request];
         }
         }
         else {
         if ([self.delegate respondsToSelector:@selector(requestsManager:didFailWritingFileAtPath:forRequest:error:)]) {
         [self.delegate requestsManager:self
         didFailWritingFileAtPath:((GRDownloadRequest *)request).localFilePath
         forRequest:(GRDownloadRequest *)request
         error:writeError];
         }
         }
         */
        
        if ([self.delegate respondsToSelector:@selector(requestsManager:didCompleteDownloadRequest:)]) {
            [self.delegate requestsManager:self didCompleteDownloadRequest:(GRDownloadRequest *)request];
        }
        
        if (self.block) {
            GRDownloadRequest *downloadReq = (GRDownloadRequest *)request;
            self.block(self,downloadReq,0,downloadReq.localFilePath,nil,nil,FTPManagerTypeDidCompleteDownload);
        }
        
        _currentDownloadData = nil;
    }
    
    [self _processNextRequest];
    
    [[NSNotificationCenter defaultCenter]postNotificationName:FTPDidFishNotifacation object:@(1)];
}

- (void)requestFailed:(GRRequest *)request
{
    if ([self.delegate respondsToSelector:@selector(requestsManager:didFailRequest:withError:)]) {
        NSError *error = [NSError errorWithDomain:@"com.github.goldraccoon" code:-1000 userInfo:@{@"message": request.error.message}];
        [self.delegate requestsManager:self didFailRequest:request withError:error];
    }
    
    if (self.block) {
        NSError *error = [NSError errorWithDomain:@"com.github.goldraccoon" code:-1000 userInfo:@{@"message": request.error.message}];
        self.block(self,request,0,nil,nil,error,FTPManagerTypeDidFail);
    }
    
    [self _processNextRequest];
}

#pragma mark - GRRequestDelegate optional

- (void)percentCompleted:(float)percent forRequest:(id<GRRequestProtocol>)request
{
    //    下载，上传完成百分比
    if (_delegateRespondsToPercentProgress) {
        if ([self.delegate respondsToSelector:@selector(requestsManager:didCompletePercent:forRequest:)]) {
            [self.delegate requestsManager:self didCompletePercent:percent forRequest:request];
        }
        
        if (self.block) {
            self.block(self,request,percent,nil,nil,nil,FTPManagerTypeDidCompletePercent);
        }
    }
}

- (void)dataAvailable:(NSData *)data forRequest:(id<GRDataExchangeRequestProtocol>)request
{
    //追加数据
    [_currentDownloadData appendData:data];
    
    if ([request isKindOfClass:[GRDownloadRequest class]]) {
        GRDownloadRequest *downReq = (GRDownloadRequest *)request;
        if (_haveDownloadData.length >= downReq.maximumSize) {
            //已下载完毕
            [downReq.delegate requestCompleted:downReq];
            [downReq.streamInfo close: request];
            NSLog(@"注意 该文件已下载过，如需重新下载 请删除本地缓存文件名！");
            
        }else{
            //不断写入文件
            NSString *localFilepath = downReq.localFilePath;
            NSFileHandle *outFile = [NSFileHandle fileHandleForWritingAtPath:localFilepath];
            if(outFile == nil)
            {
                
                NSError *writeError = nil;
                BOOL writeToFileSucceeded = [data writeToFile:localFilepath
                                                      options:NSDataWritingAtomic
                                                        error:&writeError];
                if (!writeToFileSucceeded) {
                    NSLog(@"Open of file for writing failed = %@",writeError.description);
                    if ([self.delegate respondsToSelector:@selector(requestsManager:didFailWritingFileAtPath:forRequest:error:)]) {
                        [self.delegate requestsManager:self
                              didFailWritingFileAtPath:downReq.localFilePath
                                            forRequest:downReq
                                                 error:writeError];
                    }
                    
                    if (self.block) {
                        self.block(self,downReq,0,downReq.localFilePath,nil,writeError,FTPManagerTypeDidFailWritingFileAtPath);
                    }
                }
                return;
            }else{
                [outFile seekToEndOfFile];
                [outFile writeData:data];
            }
            [outFile closeFile];
        }
        
    }
}

- (BOOL)shouldOverwriteFile:(NSString *)filePath forRequest:(id<GRDataExchangeRequestProtocol>)request
{
    // called only with GRUploadRequest requests
    return YES;
}

#pragma mark - GRRequestDataSource

- (NSString *)hostnameForRequest:(id<GRRequestProtocol>)request
{
    return self.hostname;
}

- (NSString *)usernameForRequest:(id<GRRequestProtocol>)request
{
    return self.username;
}

- (NSString *)passwordForRequest:(id<GRRequestProtocol>)request
{
    return self.password;
}

- (long)dataSizeForUploadRequest:(id<GRDataExchangeRequestProtocol>)request
{
    return [_currentUploadData length];
}

- (NSData *)dataForUploadRequest:(id<GRDataExchangeRequestProtocol>)request
{
    NSData *temp = _currentUploadData;
    _currentUploadData = nil; // next time will return nil;
    return temp;
}

//继续下载 (已经下载了的大小)
- (NSNumber *)dateSizeHaveDownloadForRequest:(id<GRDataExchangeRequestProtocol>)request{
    return [NSNumber numberWithUnsignedLongLong:_haveDownloadData.length];
}
//继续下载 (已经下载了的数据)
- (NSData *)dateHaveDownloadForRequest:(id<GRDataExchangeRequestProtocol>)request{
    return _haveDownloadData;
}

#pragma mark - Private Methods
//创建request对象
- (id<GRRequestProtocol>)_addRequestOfType:(Class)clazz withPath:(NSString *)filePath
{
    id<GRRequestProtocol> request = [[clazz alloc] initWithDelegate:self datasource:self];
    request.path = filePath;
    
    [self _enqueueRequest:request];
    return request;
}
//创建request对象
- (id<GRDataExchangeRequestProtocol>)_addDataExchangeRequestOfType:(Class)clazz withLocalPath:(NSString *)localPath remotePath:(NSString *)remotePath
{
    id<GRDataExchangeRequestProtocol> request = [[clazz alloc] initWithDelegate:self datasource:self];
    request.path = remotePath;
    request.localFilePath = localPath;
    
    [self _enqueueRequest:request];
    return request;
}
//添加请求到队列中
- (void)_enqueueRequest:(id<GRRequestProtocol>)request
{
    [self.requestQueue enqueue:request];
}

//取出当前进行
- (void)_processNextRequest
{
    self.currentRequest = [self.requestQueue dequeue];
    
    if (self.currentRequest == nil) {
        [self stopAndCancelAllRequests];
        return;
    }
    
    if ([self.currentRequest isKindOfClass:[GRDownloadRequest class]]) {
        _currentDownloadData = [NSMutableData dataWithCapacity:4096];
        NSString *localFilepath = ((GRDownloadRequest *)self.currentRequest).localFilePath;
        _haveDownloadData = [NSData dataWithContentsOfFile:localFilepath];
    }
    if ([self.currentRequest isKindOfClass:[GRUploadRequest class]]) {
        NSString *localFilepath = ((GRUploadRequest *)self.currentRequest).localFilePath;
        _currentUploadData = [NSData dataWithContentsOfFile:localFilepath];
        NSLog(@"downloadfield size = %ld",_currentDownloadData.length);
    }
    
    //
    dispatch_async(dispatch_get_main_queue(), ^{
        //发起请求
        [self.currentRequest start];
    });
    
    if ([self.delegate respondsToSelector:@selector(requestsManager:didStartRequest:)]) {
        //设置开启回调
        [self.delegate requestsManager:self didStartRequest:self.currentRequest];
    }
    
    if (self.block) {
        self.block(self,self.currentRequest,0,nil,nil,nil,FTPManagerTypeDidStart);
    }
}

@end
