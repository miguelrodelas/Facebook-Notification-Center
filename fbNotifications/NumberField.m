//  NumberField.m
//  Created by Michael Robinson (Code of Interest) on 28/11/10.
#import "NumberField.h"

@implementation NumberField

-(void) textDidEndEditing:(NSNotification *)aNotification {
	// replace content with its intValue ( or process the input's value differently )
	[self setIntValue:[self intValue]];
	// make sure the notification is sent back to any delegate
	[super textDidEndEditing:aNotification];
}
@end