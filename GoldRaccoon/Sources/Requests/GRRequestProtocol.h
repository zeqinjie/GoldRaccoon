//
//  GRRequestDelegate.h
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

#import <Foundation/Foundation.h>

@class GRRequest;
@class GRError;
@class GRStreamInfo;

@protocol GRRequestProtocol <NSObject>

@property BOOL passiveMode;
@property NSString *uuid;

@property (nonatomic) NSString *path;
@property (nonatomic, strong) GRError *error;
@property (nonatomic, strong) GRStreamInfo *streamInfo;

@property (nonatomic, assign) float maximumSize;
@property (nonatomic, assign) float percentCompleted;

- (NSURL *)fullURL;
- (NSURL *)fullURLWithEscape;
- (void)start;
- (void)cancelRequest;
//子类重写
- (void)pause;//暂停
- (void)resume;//继续
@end

@protocol GRDataExchangeRequestProtocol <GRRequestProtocol>
//下载的本地地址
@property (nonatomic, copy) NSString *localFilePath;
//下载的远程地址
@property (nonatomic, readonly) NSString *fullRemotePath;

@end

@protocol GRRequestDelegate <NSObject>

@required
- (void)requestCompleted:(id<GRRequestProtocol>)request;
- (void)requestFailed:(id<GRRequestProtocol>)request;

@optional
- (void)percentCompleted:(float)percent forRequest:(id<GRRequestProtocol>)request;
- (void)dataAvailable:(NSData *)data forRequest:(id<GRDataExchangeRequestProtocol>)request;
- (BOOL)shouldOverwriteFile:(NSString *)filePath forRequest:(id<GRDataExchangeRequestProtocol>)request;

@end

@protocol GRRequestDataSource <NSObject>

@required
//获取服务器地址
- (NSString *)hostnameForRequest:(id<GRRequestProtocol>)request;
//获取服务器用户名
- (NSString *)usernameForRequest:(id<GRRequestProtocol>)request;
//获取服务器密码
- (NSString *)passwordForRequest:(id<GRRequestProtocol>)request;

@optional
//上载大小
- (long)dataSizeForUploadRequest:(id<GRDataExchangeRequestProtocol>)request;
//上载数据
- (NSData *)dataForUploadRequest:(id<GRDataExchangeRequestProtocol>)request;
/**
 *  下载相关
 */
//继续下载 (已经下载了的大小)
- (NSNumber *)dateSizeHaveDownloadForRequest:(id<GRDataExchangeRequestProtocol>)request;
//继续下载 (已经下载了的数据)
- (NSData *)dateHaveDownloadForRequest:(id<GRDataExchangeRequestProtocol>)request;

@end
