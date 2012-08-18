Facebook-Notification-Center
============================

Facebook Notifications for the new Notification Center in Mountain Lion.

You need to add your own Facebook Application ID in the AppDelegate.m:
<code>self.fb = [[PhFacebook alloc] initWithApplicationID: @"YOUR APPLICATION ID HERE" delegate: self];</code>

This app uses the following framework:
- PHFacebook - MacOSX Interface to Facebook graph API
(https://github.com/philippec/PhFacebook)