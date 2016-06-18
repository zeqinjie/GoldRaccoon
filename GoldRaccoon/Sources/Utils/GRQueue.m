//
//  GRQueue.m
//  GoldRaccoon
//
//  Created by Alberto De Bortoli on 14/06/2013.
//  Copyright 2013 Alberto De Bortoli. All rights reserved.
//

#import "GRQueue.h"

@implementation GRQueue
{
	NSMutableArray *_items;
}

- (instancetype)init
{
    self = [super init];
	if (self) {
		_items = [[NSMutableArray alloc] init];
		_count = 0;
	}
	return self;
}
//添加对象到队列中
- (void)enqueue:(id)object
{
	[_items addObject:object];
	_count = [_items count];
}

//取出对象
- (id)dequeue
{
	id obj = nil;
	if ([_items count]) {
		obj = _items[0];
		[_items removeObjectAtIndex:0];
	}
    _count = [_items count];
    
	return obj;
}

//移除对象
- (BOOL)removeObject:(id)object
{
    if ([_items containsObject:object]) {
        [_items removeObject:object];
        return YES;
    }
    
    return NO;
}

- (NSArray *)allItems
{
    return _items;
}

- (void)clear
{
	[_items removeAllObjects];
	_count = 0;
}

@end
