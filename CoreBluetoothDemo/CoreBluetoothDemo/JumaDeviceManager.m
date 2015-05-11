//
//  JumaDeviceManager.m
//  JumaDeviceManager
//  CoreBluetoothDemo
//
//  Created by xianzhiliao on 15/5/11.
//  Copyright (c) 2015年 xianzhiliao. All rights reserved.
//

#import "JumaDeviceManager.h"
#import "config.h"

#import <CoreBluetooth/CoreBluetooth.h>

@interface JumaDeviceManager () <CBCentralManagerDelegate, CBPeripheralDelegate>


@property (nonatomic, strong) NSTimer *timer;


@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic) BOOL isScanning; // 标记 centralManager 是否正在扫描

/** 保存的符合过滤条件的 peripheral */
@property (nonatomic, strong) NSMutableArray *peripherals;
/** 当前需要连接的 peripheral */
@property (nonatomic, strong) CBPeripheral *peripheral;
/** 指定要扫描的设备名, 由 SDK 外界传入, 可以为空 */
@property (nonatomic, copy) NSString *peripheralName;
@property (nonatomic, strong) CBCharacteristic *characteristicForWriting;
//@property (nonatomic, copy) NSData *dataWritten;
@property (nonatomic, strong) CBCharacteristic *characteristicForNotifing;
//@property (nonatomic, copy) NSData *dataReceived;

@end

@implementation JumaDeviceManager

char       const PACKET_HEADER              = 0X02;
NSUInteger const PACKET_MAX_LENGTH          = 19;
NSString * const SERVICE_UUID               = @"00008000-60b2-21f8-bce3-94eea697f98c";
NSString * const WRITE_CHARACTERISTIC_UUID  = @"00008001-60b2-21f8-bce3-94eea697f98c";
NSString * const NOTIFY_CHARACTERISTIC_UUID = @"00008002-60b2-21f8-bce3-94eea697f98c";

#pragma mark - init and dealloc


- (instancetype)initWithDelegate:(id<JumaDeviceManagerDelegate>)delegate {
    
    if (self = [super init]) {
        self.delegate = delegate;
    }
    return self;
}

#pragma mark - setter and getter

- (void)setDelegate:(id<JumaDeviceManagerDelegate>)delegate {
    _delegate = delegate;
    
    if (self.peripherals    == nil) self.peripherals    =  [NSMutableArray array];
    if (self.centralManager == nil) self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}



#pragma mark - public method
- (void)scanDeviceWithName:(NSString *)deviceName {
    
    if (self.centralManager.state != CBCentralManagerStatePoweredOn) return;
    
    if (self.timer == nil) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                      target:self
                                                    selector:@selector(stopScan)
                                                    userInfo:nil
                                                     repeats:NO];
        
         self.peripheralName = deviceName;
        [self.centralManager scanForPeripheralsWithServices:nil options:nil];
        self.isScanning = YES;
        
        [self.peripherals removeAllObjects];
    }
}

- (void)stopScan {
    
    [self.timer invalidate];
     self.timer = nil;
    
    if (self.isScanning) {
        
        [self.centralManager stopScan];
        self.isScanning = NO;
        
        if ([self.delegate respondsToSelector:@selector(deviceManagerDidStopScan:)]) {
            [self.delegate deviceManagerDidStopScan:self];
        }
    }
}


- (void)connectDevice:(NSString *)deviceUUID {
    
    if (self.centralManager.state != CBCentralManagerStatePoweredOn) return;
    
    for (CBPeripheral *temp in self.peripherals) {
        if ([temp.identifier.UUIDString isEqualToString:deviceUUID.uppercaseString]) {
            
            self.peripheral = temp;
            [self.centralManager connectPeripheral:temp options:nil];
            break;
        }
    }
}

- (void)disconnectDevice {
    
    switch (self.peripheral.state) {
        case CBPeripheralStateDisconnected: return;
        case CBPeripheralStateConnecting:  [self.centralManager cancelPeripheralConnection:self.peripheral]; return;
        case CBPeripheralStateConnected:    break; // connected
    }
    
    // 停止接收特征通知
    for (CBService *service in self.peripheral.services) {
        for (CBCharacteristic *characteristic in service.characteristics) {
            
            if ([characteristic.UUID.UUIDString isEqualToString:NOTIFY_CHARACTERISTIC_UUID]) {
                [self.peripheral setNotifyValue:NO forCharacteristic:characteristic];
            }
        }
    }
    
    [self.centralManager cancelPeripheralConnection:self.peripheral];
    
    [self sendDelegateDisconnectError:nil code:0 byRemote:NO];
}

- (void)readRSSI {
    
    if ( self.peripheral) {
        [self.peripheral readRSSI];
    }
}

- (void)sendData:(NSData *)data {
    
    if (data.length == 0) return;
    
    if (data.length > PACKET_MAX_LENGTH) {
        data = [data subdataWithRange:NSMakeRange(0, PACKET_MAX_LENGTH)];
    }
    
    NSMutableData *packet = [NSMutableData dataWithBytes:&PACKET_HEADER
                                                  length:sizeof(PACKET_HEADER)];
    [packet appendData:data];
    
    [self.peripheral writeValue:[NSData dataWithData:packet]
              forCharacteristic:self.characteristicForWriting
                           type:CBCharacteristicWriteWithoutResponse];
}

#pragma mark - 向代理发送消息
- (void)sendDelegateFailToConnnectError:(NSString *)error {
    
    if ([self.delegate respondsToSelector:@selector(deviceManager:didFailToConnectDevice:error:)]) {
        [self.delegate deviceManager:self didFailToConnectDevice:self.peripheral.identifier.UUIDString error:error];
    }
}

- (void)sendDelegateDisconnectError:(NSString *)error code:(NSInteger)code byRemote:(BOOL)byRemote {
    
    if ([self.delegate respondsToSelector:@selector(deviceManager:didDisconnectDevice:byRemote:code:error:)]) {
        [self.delegate deviceManager:self didDisconnectDevice:self.peripheral.identifier.UUIDString byRemote:byRemote code:code error:error];
    }
}

- (void)sendDelegateConnectSuccess {
    
    if ([self.delegate respondsToSelector:@selector(deviceManager:didConnectDevice:)]) {
        [self.delegate deviceManager:self didConnectDevice:self.peripheral.identifier.UUIDString];
    }
    // 连接成功后关闭 scan
    [self stopScan];
}

- (void)sendDelegateReceivedData:(NSData *)data error:(NSString *)error {
    
    if ([self.delegate respondsToSelector:@selector(deviceManager:didReceiveData:error:)]) {
        [self.delegate deviceManager:self didReceiveData:data error:error];
    }
}

#pragma mark - CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    if ([self.delegate respondsToSelector:@selector(deviceManager:didUpdateState:)]) {
        [self.delegate deviceManager:self didUpdateState:(JumaDeviceManagerState)central.state];
    }
}

// discover peripheral
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
    JMLog(@"peripheral.name = %@", peripheral.name);
    
    if ([self.delegate respondsToSelector:@selector(deviceManager:didDiscoverDevice:name:RSSI:)]) {
        
        if ([self.peripherals containsObject:peripheral]) return;
        
        if ( self.peripheralName.length &&
            [self.peripheralName isEqualToString:peripheral.name] == NO) return; // 如果在扫描时指定了设备的名称, 就以名称过滤
        
        [self.peripherals addObject:peripheral]; // 保存所有符合条件的 peripheral
        [self.delegate deviceManager:self didDiscoverDevice:peripheral.identifier.UUIDString name:peripheral.name RSSI:RSSI];
    }
}

// connect peripheral
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
    if (peripheral != self.peripheral) return;
    
    [self sendDelegateFailToConnnectError:error.localizedDescription];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
    if (peripheral != self.peripheral) return;
    
    BOOL byRemote = NO;
    
    if (error) {
        byRemote = YES;
    }
    
    [self sendDelegateDisconnectError:error.localizedDescription code:0 byRemote:byRemote];
    
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    
    if (peripheral != self.peripheral) return;
    
    [peripheral setDelegate:self];
    [peripheral discoverServices:@[[CBUUID UUIDWithString:SERVICE_UUID.uppercaseString]]];
}

#pragma mark - CBPeripheralDelegate
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    
    if (peripheral != self.peripheral) return;
    
    if (error) {
        [self sendDelegateFailToConnnectError:error.localizedDescription];
        return;
    }
    
    for (CBService *service in peripheral.services) {
        if ([service.UUID.UUIDString isEqualToString:SERVICE_UUID.uppercaseString]) {
            
            NSArray *uuids = @[[CBUUID UUIDWithString:WRITE_CHARACTERISTIC_UUID], [CBUUID UUIDWithString:NOTIFY_CHARACTERISTIC_UUID]];
            [peripheral discoverCharacteristics:uuids forService:service];
            break;
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    
    if (error) {
        [self sendDelegateFailToConnnectError:error.localizedDescription];
        return;
    }
    
    for (CBCharacteristic *characteristic in service.characteristics) {
        
        if ([characteristic.UUID.UUIDString isEqualToString:NOTIFY_CHARACTERISTIC_UUID.uppercaseString]) { // 读取
            self.characteristicForNotifing = characteristic;
            JMLog(@"characteristic.isNotifying = %d", characteristic.isNotifying);
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            
        }
        else if ([characteristic.UUID.UUIDString isEqualToString:WRITE_CHARACTERISTIC_UUID.uppercaseString]) { // 写入
            self.characteristicForWriting = characteristic;
        }
    }
    
    if (self.characteristicForNotifing == nil || self.characteristicForWriting == nil) { // 没有找到用于写入的特征或者没有找到用于订阅的特征
        
        // 取消预订的特征
        if (self.characteristicForNotifing) {
            [peripheral setNotifyValue:NO forCharacteristic:self.characteristicForNotifing];
        }
        
        self.characteristicForNotifing = nil;
        self.characteristicForWriting  = nil;
        
        // 主动断开连接
        [self.centralManager cancelPeripheralConnection:peripheral];
        
        [self sendDelegateFailToConnnectError:@"找不到写入点或者找不到读取点, 也可能都找不到" /*@"Device manager can not either write some data to the device or get some data from the device"*/];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    if ([characteristic.UUID.UUIDString isEqualToString:NOTIFY_CHARACTERISTIC_UUID.uppercaseString] == NO) return;
    
    if (error) {
        [self sendDelegateFailToConnnectError:error.localizedDescription];
        return;
    }
    
    JMLog(@"characteristic.isNotifying = %d", characteristic.isNotifying);
    
    if (characteristic.isNotifying == YES) {
        [self sendDelegateConnectSuccess];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    if ([characteristic.UUID.UUIDString isEqualToString:NOTIFY_CHARACTERISTIC_UUID.uppercaseString] == NO) return;
    
    if (error) {
        [self sendDelegateReceivedData:nil error:error.localizedDescription];
    }
    else {
        NSData *data = characteristic.value;
        data = [data subdataWithRange:NSMakeRange(1, data.length - 1)];
        [self sendDelegateReceivedData:data error:nil];
    }
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error {
    
    if ([self.delegate respondsToSelector:@selector(deviceManager:didReadRSSI:error:)]) {
//        [self.delegate deviceManager:self didReadRSSI:RSSI error:error.localizedDescription];
    }
}
#else
- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error {
    
    if ([self.delegate respondsToSelector:@selector(deviceManager:didReadRSSI:error:)]) {
        [self.delegate deviceManager:self didReadRSSI:peripheral.RSSI error:error.localizedDescription];
    }
}
#endif

@end
