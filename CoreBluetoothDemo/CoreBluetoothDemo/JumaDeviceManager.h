//
//  JumaDeviceManager.h
//  JumaDeviceManager
//  CoreBluetoothDemo
//
//  Created by xianzhiliao on 15/5/11.
//  Copyright (c) 2015年 xianzhiliao. All rights reserved.
//

#import <Foundation/Foundation.h> 


typedef NS_ENUM(NSInteger, JumaDeviceManagerState) {
    
    JumaDeviceManagerStateUnknown = 0, // 当前设备中蓝牙的状态未知
    JumaDeviceManagerStateResetting, // 当前设备中的蓝牙正在重置
    JumaDeviceManagerStateUnsupported, // 当前设备中蓝牙无法支持的状态
    JumaDeviceManagerStateUnauthorized, // 对蓝牙的使用没有获得用户授权
    JumaDeviceManagerStatePoweredOff, // 蓝牙已经关闭
    JumaDeviceManagerStatePoweredOn, // 蓝牙已经打开
};

@protocol JumaDeviceManagerDelegate;


@interface JumaDeviceManager : NSObject

@property (nonatomic, weak) id<JumaDeviceManagerDelegate> delegate; 

/** step 02, 扫描当前设备周围的其他设备 */
- (void)scanDeviceWithName:(NSString *)deviceName;
- (void)stopScan;

/** step 04, 连接到目标设备 */
- (void)connectDevice:(NSString *)deviceUUID;
/** 主动断开连接 */
- (void)disconnectDevice;

/** step 06 向目标设备写入数据 */
- (void)sendData:(NSData *)data;

@end

@protocol JumaDeviceManagerDelegate <NSObject>

@optional

/** step 01, 当前设备上的蓝牙的状态已经改变, 每改变一次, 这个方法就会被 SDK 调用一次 */
- (void)deviceManager:(JumaDeviceManager *)deviceManager didUpdateState:(JumaDeviceManagerState)state;

/** step 03, 已经发现目标设备 */
- (void)deviceManager:(JumaDeviceManager *)deviceManager didDiscoverDevice:(NSString *)deviceUUID name:(NSString *)deviceName RSSI:(NSNumber *)RSSI;
- (void)deviceManagerDidStopScan:(JumaDeviceManager *)deviceManager;

/** step 05, 连接到设备 */
- (void)deviceManager:(JumaDeviceManager *)deviceManager didConnectDevice:(NSString *)deviceUUID;
- (void)deviceManager:(JumaDeviceManager *)deviceManager didFailToConnectDevice:(NSString *)deviceUUID error:(NSString *)error;
/** 如果连接出错断开, error != nil, 否则 error == nil. code 暂未实现. byRemote 暂未实现 */
- (void)deviceManager:(JumaDeviceManager *)deviceManager didDisconnectDevice:(NSString *)deviceUUID byRemote:(BOOL)byRemote code:(NSInteger)code error:(NSString *)error;

/** step 07, 接收目标设备返回的数据 */
- (void)deviceManager:(JumaDeviceManager *)deviceManager didReceiveData:(NSData *)data error:(NSString *)error;

@end

