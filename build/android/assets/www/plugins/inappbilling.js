/*
 * Copyright (C) 2012 by Guillaume Charhon
 */

var inappbilling={init:function(success,fail){return cordova.exec(success,fail,"InAppBillingPlugin","init",["null"])},purchase:function(success,fail,productId){return cordova.exec(success,fail,"InAppBillingPlugin","purchase",[productId])},getOwnItems:function(success,fail){return cordova.exec(success,fail,"InAppBillingPlugin","ownItems",["null"])}}