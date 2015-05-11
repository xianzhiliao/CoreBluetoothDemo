//
//  config.h
//  CoreBluetoothDemo
//
//  Created by xianzhiliao on 15/5/11.
//  Copyright (c) 2015年 xianzhiliao. All rights reserved.
//

#ifndef ____config_h
#define ____config_h

#ifdef __OBJC__
    // 自定义的打印函数
    #if DEBUG
    #define JMLog(...) NSLog(__VA_ARGS__)
    #else
    #define JMLog(...)
    #endif
#endif

#endif
