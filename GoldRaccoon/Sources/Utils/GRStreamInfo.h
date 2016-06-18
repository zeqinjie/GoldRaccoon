//
//  GRStreamInfo.h
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
//

#import "GRError.h"

#define kGRDefaultBufferSize 32768

@protocol GRRequestProtocol;

@interface GRStreamInfo : NSObject
//输出流 上传
@property (nonatomic, strong) NSOutputStream *writeStream;
//输入流 下载
@property (nonatomic, strong) NSInputStream *readStream;

@property (nonatomic, assign) long bytesThisIteration;
//读取的字符长度
@property (nonatomic, assign) long bytesTotal;
//超时
@property (nonatomic, assign) long timeout;
//删除请求标志
@property (nonatomic, assign) BOOL cancelRequestFlag;
@property (nonatomic, assign) BOOL cancelDoesNotCallDelegate;
//打开 读取
- (void)openRead:(id<GRRequestProtocol>)request;
//打开 写   （上传 需先打开读取目录再去写文件）
- (void)openWrite:(id<GRRequestProtocol>)request;
- (BOOL)checkCancelRequest:(id<GRRequestProtocol>)request;
//下载数据
- (NSData *)read:(id<GRRequestProtocol>)request;
- (BOOL)write:(id<GRRequestProtocol>)request data:(NSData *)data;
- (void)streamError:(id<GRRequestProtocol>)request errorCode:(enum GRErrorCodes)errorCode;
- (void)streamComplete:(id<GRRequestProtocol>)request;
- (void)close:(id<GRRequestProtocol>)request;

//暂停
- (void)pause:(id<GRRequestProtocol>)request;
//继续
- (void)resume:(id<GRRequestProtocol>)request;
@end
