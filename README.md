# GoldRaccoon

## General Notes

[GoldRaccoon](http://albertodebortoli.github.io/GoldRaccoon/) is the iOS component to connect to a FTP service and do the following:

*	Download a file
*	Upload a file
*	Delete a file
*	Create a directory
*	Delete a directory
*	List a directory

## Why another Raccoon? 

First, because the humanity needs it.

This project started on 29/06/2013 for the Objective-C Hackathon (http://objectivechackathon.appspot.com/).

[GoldRaccoon](https://github.com/albertodebortoli/GoldRaccoon) aims to be an evolution of [BlackRaccoon](https://github.com/lloydsargent/BlackRaccoon) (which is an evolution of [WhiteRaccoon](https://github.com/valentinradu/WhiteRaccoon)), maybe the best (or at least one of the few) third-party component out there for handling FTP operations on iOS.

I forked the public repo of BlackRaccooon in May 2013 and added some improvements that have been merged into master to BlackRaccoon. Even though BlackRaccoon does what it says, I prefer to clean it a little and use a different and more extensible code structure.

Most of the code is therefore written by [Valentin Radu](https://github.com/valentinradu) and [Lloyd Sargent](https://github.com/lloydsargent), the main extensions I ([Alberto De Bortoli](https://github.com/albertodebortoli)) added are:

- Done some deep refactoring for the bloating of the previous code;
- Added missing (and reasonable) code conventions;
- Added GRRequestsManager to manage all the different kind of requests using a FIFO queue;
- Added a demo project.

## Usage

If you'd like to include this component as a pod using [CocoaPods](http://cocoapods.org/), just add the following line to your Podfile:

`pod "GoldRaccoon"`

otherwise

- copy Sources folder into your project
- add CFNetwork framework
- import `GRRequestsManager.h` in your class
- add a property for the manager

``` objective-c
@property (nonatomic, strong) GRRequestsManager *requestsManager;
```

- setup the manager somewhere (with hostname, username and password)

``` objective-c
self.requestsManager = [[GRRequestsManager alloc] initWithHostname:<hostname>
                                                              user:<username>
                                                          password:<password>];
```

- optionally make your class conform to `GRRequestsManagerDelegate`, implement the delegate methods (basically success, failure and progress callbacks) and set your instance of this class as delegate for the manager

``` objective-c
self.requestsManager.delegate = self;
```

- add the requests to the manager using the following methods:

``` objective-c
addRequestForListDirectoryAtPath:
addRequestForCreateDirectoryAtPath:
addRequestForDeleteFileAtPath:
addRequestForDeleteDirectoryAtPath:
addRequestForDownloadFileAtRemotePath:toLocalPath:
addRequestForUploadFileAtLocalPath:toRemotePath:
```

- start the manager

``` objective-c
[self.requestsManager startProcessingRequests];
```
##modify by zhengzeqin
修改成支持block方式，添加断点续传，删除任务，修改成支持无账户密码也支持链接方式
使用方式

```objective-c
    //1.创建对象
    FTPManagerTaskObj *obj = [FTPManagerTaskObj new];
    obj.hostUrl = @"";
    obj.userName = @"";
    obj.userPwd = @"";
    obj.taskName = obj.remotePath = @"down/null/1/1465011847256.txt";
    //2.使用下载工具  
    [[FTPManagerTool sharedInstance]downLoadTaskObj:obj block:^(GRRequestsManager *requestMan,GRRequest *request, CGFloat progress, NSString *pathStr, NSArray *listArr, NSError *error, FTPManagerType type) {
        if(type == FTPManagerTypeDidStart) {
            NSLog(@"开启请求:requestsManager:didStartRequest:");
        }else if (type == FTPManagerTypeDidCompletePercent){
            NSLog(@"完成百分比 = %f", progress);
        }else if (type == FTPManagerTypeDidCompleteDownload || type == FTPManagerTypeDidFail){
        //3.注意回收任务
        NSLog(@"下载完毕或者失败");
        }
    }isReDownLoad:YES];
    
   	 //支持断点续传，支持暂停 和  继续
    //1.从操作工具取出下载器
    GRRequestsManager *requestManager  = [[FTPManagerTool sharedInstance].taskDic objectForKey:obj.taskName];
    //2.暂停
    [requestManager pause];
    //3.继续
    [requestManager resume];
```