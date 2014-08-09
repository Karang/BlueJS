//
//  BlueJS.h
//  Cordova Plugin for nrf51822 modules
//
//  (c) 2014 Arthur Hennequin (Karang)
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#ifndef BLUEJS_H
#define BLUEJS_H

#import <Cordova/CDV.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface BlueJS : CDVPlugin <CBCentralManagerDelegate, CBPeripheralDelegate> {
    NSString* onConnectCallbackId;
    NSString* onDataCallbackId;
    NSString* onDiscoverCallbackId;
}

@property (strong, nonatomic) CBCentralManager *manager;
@property (strong, nonatomic) CBPeripheral *activePeripheral;
@property (strong, nonatomic) CBPeripheral *connectingPeripheral;

- (void) startScan:(CDVInvokedUrlCommand *)command;
- (void) stopScan:(CDVInvokedUrlCommand *)command;

- (void) connect:(CDVInvokedUrlCommand *)command;
- (void) disconnect:(CDVInvokedUrlCommand *)command;

- (void) listenToData:(CDVInvokedUrlCommand *)command;
- (void) write:(CDVInvokedUrlCommand *)command;

- (NSString *) centralManagerStateToString:(CBCentralManagerState)state;

@end

#endif