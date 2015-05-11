//
//  DeviceViewController.h
//  CoreBluetoothDemo
//
//  Created by xianzhiliao on 15/5/11.
//  Copyright (c) 2015年 xianzhiliao. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface Device : NSObject

@property (nonatomic, copy) NSString *deviceUUID;
@property (nonatomic, copy) NSString *deviceName;
@property (nonatomic, strong) NSNumber *RSSI;

- (instancetype)initWithDeviceUUID:(NSString *)deviceUUID deviceName:(NSString *)deviceName RSSI:(NSNumber *)RSSI;
+ (instancetype)deviceWithDeviceUUID:(NSString *)deviceUUID deviceName:(NSString *)deviceName RSSI:(NSNumber *)RSSI;

@end



@protocol DeviceViewControllerDelegate;

@interface DeviceViewController : UIViewController

@property (nonatomic, weak) id<DeviceViewControllerDelegate> delegate;

- (void)appendDevice:(Device *)device;
- (void)clearDevices;

@end

@protocol DeviceViewControllerDelegate <NSObject>

- (void)deviceController:(DeviceViewController *)deviceController didScanDeviceWithName:(NSString *)deviceName;
- (void)deviceController:(DeviceViewController *)deviceController didSelectDevice:(Device *)device;

@end

