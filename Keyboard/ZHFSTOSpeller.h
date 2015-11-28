//
//  ZHFSTOSpeller.h
//  TastyImitationKeyboard
//
//  Created by Brendan Molloy on 22/11/2015.
//  Copyright © 2015 Apple. All rights reserved.
//

#ifndef ZHFSTOSpeller_h
#define ZHFSTOSpeller_h

#import "ZHFSTOSpeller-binding.h"

@interface ZHFSTPair<T, U> : NSObject
@property T first;
@property U second;

-(id)initWithFirst:(T)first second:(U)second;

@end

@interface ZHFSTOSpeller : NSObject

@property zhfst_ospeller_t* handle;

- (id)init;
- (void)readZhfst:(NSString*)filename tempDir:(NSString*)tmpdir;
- (void)setQueueLimit:(unsigned long)limit;
- (void)setWeightLimit:(float)weight;
- (void)setBeam:(float)beam;
//- (void)clearSuggestionCache;
- (BOOL)spell:(NSString*)word;
- (NSArray<ZHFSTPair<NSString*, NSNumber*>*>*)suggest:(NSString*)word;

@end


#endif /* ZHFSTOSpeller_h */
