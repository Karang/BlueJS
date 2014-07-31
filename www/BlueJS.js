// (c) 2014 Arthur Hennequin (Karang)
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

'use strict';

module.exports = {
    startScan: function(onDiscover, onError) {
        cordova.exec(onDiscover, onError, "BlueJS", "startScan", []);
    },
    
    listenToDeviceUpdate: function(onDeviceUpdate, onError, period) {
        period = (period) ? period : 1;
        cordova.exec(onDeviceUpdate, onError, "BlueJS", "listenToDeviceUpdate", [period]); 
    },
    
    stopScan: function() {
        cordova.exec(function(){}, function(error){}, "BlueJS", "stopScan", []);
    },
    
    connect: function(uuid, onSuccess, onError) {
        cordova.exec(onSuccess, onError, "BlueJS", "connect", [uuid]);
    },
    
    disconnect: function(onSuccess, onError) {
        cordova.exec(onSuccess, onError, "BlueJS", "disconnect", []);
    },
    
    listenToData: function(onData, onError) {
        cordova.exec(onData, onError, "BlueJS", "listenToData", []);
    },
    
    write: function(data, onSuccess, onError) {
        cordova.exec(onSuccess, onError, "BlueJS", "write", []);
    }
};