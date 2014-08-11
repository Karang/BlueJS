//
//  BlueJS.m
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

#import "BlueJS.h"
#import <Cordova/CDV.h>

@implementation BlueJS

@synthesize manager;
@synthesize activePeripheral;
@synthesize connectingPeripheral;

CBUUID *service_uuid;
CBUUID *send_characteristic_uuid;
CBUUID *receive_characteristic_uuid;
CBUUID *disconnect_characteristic_uuid;
NSArray *characteristics;

CBCharacteristic *send_characteristic;
CBCharacteristic *disconnect_characteristic;

- (void) pluginInitialize {
    NSLog(@"BlueJS v0.0.1");
    NSLog(@"(c) 2014 Arthur Hennequin (Karang)");
    
    [super pluginInitialize];
    
    // RFduino services
    service_uuid = [CBUUID UUIDWithString:@"2220"];
    
    receive_characteristic_uuid = [CBUUID UUIDWithString:@"2221"];
    send_characteristic_uuid = [CBUUID UUIDWithString:@"2222"];
    disconnect_characteristic_uuid = [CBUUID UUIDWithString:@"2223"];
    
    characteristics = [NSArray arrayWithObjects:send_characteristic_uuid, receive_characteristic_uuid, disconnect_characteristic_uuid, nil];
    
    manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

#pragma mark - Plugin methods

- (void) startScan:(CDVInvokedUrlCommand *)command {
    NSLog(@"Scan");
    
    onDiscoverCallbackId = [command.callbackId copy];
    
    NSDictionary *opt = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
    [manager scanForPeripheralsWithServices:[NSArray arrayWithObject:service_uuid] options:opt];
    
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
    [pluginResult setKeepCallbackAsBool:TRUE];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) stopScan:(CDVInvokedUrlCommand *)command {
    NSLog(@"Stop scan");
    
    [manager stopScan];
    
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
    [pluginResult setKeepCallbackAsBool:TRUE];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) connect:(CDVInvokedUrlCommand *)command {
    NSString* uuid_string = [command.arguments objectAtIndex:0];
    CBUUID *device_uuid = [CBUUID UUIDWithString:uuid_string];
    CBPeripheral *device = [[manager retrievePeripheralsWithIdentifiers:[NSArray arrayWithObject:device_uuid]] objectAtIndex:0];
    
    if (device) {
        NSLog(@"Connecting to peripheral with UUID : %@", uuid_string);

        [manager stopScan];
        
        onConnectCallbackId = [command.callbackId copy];
        
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
        [pluginResult setKeepCallbackAsBool:TRUE];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        
        [manager connectPeripheral:device options:nil];
        self.connectingPeripheral = device;
    } else {
        NSLog(@"Peripheral not found");
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"DEVICE NOT FOUND"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void) disconnect:(CDVInvokedUrlCommand *)command {
    NSLog(@"Disconnect");
    
    if (activePeripheral) {
        [activePeripheral writeValue:[NSData data] forCharacteristic:disconnect_characteristic type:CBCharacteristicWriteWithoutResponse];
        
        if (activePeripheral.isConnected) {
            [manager cancelPeripheralConnection:activePeripheral];
        }
    }
    
    onConnectCallbackId = nil;
    
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) listenToData:(CDVInvokedUrlCommand *)command {
    NSLog(@"Listen to data");
    
    onDataCallbackId = [command.callbackId copy];
    
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
    [pluginResult setKeepCallbackAsBool:TRUE];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) readRSSI:(CDVInvokedUrlCommand *)command {
    if (activePeripheral && activePeripheral.isConnected) {
        onRSSICallbackId = [command.callbackId copy];
        
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
        [pluginResult setKeepCallbackAsBool:TRUE];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        
        [activePeripheral readRSSI];
    } else {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"NOT CONNECTED"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        
        onRSSICallbackId = nil;
    }
}

- (void) write:(CDVInvokedUrlCommand *)command {
    NSData * data = [command.arguments objectAtIndex:0];
    
    if (data != nil) {
        [activePeripheral writeValue:data forCharacteristic:send_characteristic type:CBCharacteristicWriteWithoutResponse];
    }
    
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
    [pluginResult setKeepCallbackAsBool:TRUE];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    NSString *uuidString = ([peripheral identifier])?[[peripheral identifier] UUIDString]:@"";
    NSString *advertisementString = @"";
    if (advertisementData) {
        id manufacturerData = [advertisementData objectForKey:CBAdvertisementDataManufacturerDataKey];
        if (manufacturerData) {
            const uint8_t *bytes = [manufacturerData bytes];
            unsigned long len = [manufacturerData length];
            NSData *data = [NSData dataWithBytes:bytes+2 length:len-2];
            advertisementString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
    }
    NSMutableDictionary *res = [NSMutableDictionary dictionary];
    [res setObject: uuidString forKey: @"uuid"];
    [res setObject: [peripheral name] forKey: @"name"];
    [res setObject: RSSI forKey: @"rssi"];
    [res setObject: advertisementString forKey: @"advertisement"];
    
    if (onDiscoverCallbackId) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:res];
        [pluginResult setKeepCallbackAsBool:TRUE];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:onDiscoverCallbackId];
    }
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    NSLog(@"CoreBluetooth Central Manager changed state: %d (%@)", (int)[central state], [self centralManagerStateToString:[central state]]);
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"Connected to peripheral");
    
    peripheral.delegate = self;
    self.activePeripheral = peripheral;
    
    [peripheral discoverServices:[NSArray arrayWithObject:service_uuid]];
    
    if (onConnectCallbackId) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [pluginResult setKeepCallbackAsBool:TRUE];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:onConnectCallbackId];
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Disconnected from peripheral");
    
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"DISCONNECTED"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:onConnectCallbackId];
    
    onConnectCallbackId = nil;
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Unable to connect to peripheral");
    
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"FAILED TO CONNECT"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:onConnectCallbackId];
    
    onConnectCallbackId = nil;
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    for (CBService *service in [peripheral services]) {
        if ([service.UUID isEqual:service_uuid]) {
            [peripheral discoverCharacteristics:characteristics forService:service];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if  ([service.UUID isEqual:service_uuid]) {
        for (CBCharacteristic *characteristic in [service characteristics]) {
            if ([characteristic.UUID isEqual:send_characteristic_uuid]) {
                send_characteristic = characteristic;
            } else if ([characteristic.UUID isEqual:receive_characteristic_uuid]) {
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            } else if ([characteristic.UUID isEqual:disconnect_characteristic_uuid]) {
                disconnect_characteristic = characteristic;
            }
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if ([characteristic.UUID isEqual:receive_characteristic_uuid]) {
        if (onDataCallbackId) {
            NSData*data = [characteristic value];
            
            CDVPluginResult*pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArrayBuffer:data];
            [pluginResult setKeepCallbackAsBool:TRUE];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:onDataCallbackId];
        }
    }
}

- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error {
    if (onRSSICallbackId) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:[peripheral.RSSI intValue]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:onRSSICallbackId];
        onRSSICallbackId = nil;
    }
}

#pragma mark - Utils

- (NSString *) centralManagerStateToString:(CBCentralManagerState)state {
    switch (state) {
        case CBCentralManagerStateUnknown:
            return @"State unknown (CBCentralManagerStateUnknown)";
        case CBCentralManagerStateResetting:
            return @"State resetting (CBCentralManagerStateUnknown)";
        case CBCentralManagerStateUnsupported:
            return @"State BLE unsupported (CBCentralManagerStateResetting)";
        case CBCentralManagerStateUnauthorized:
            return @"State unauthorized (CBCentralManagerStateUnauthorized)";
        case CBCentralManagerStatePoweredOff:
            return @"State BLE powered off (CBCentralManagerStatePoweredOff)";
        case CBCentralManagerStatePoweredOn:
            return @"State powered up and ready (CBCentralManagerStatePoweredOn)";
        default:
            return @"State unknown";
    }
    
    return @"Unknown state";
}

@end