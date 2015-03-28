//
//  dbHelper.m
//  CBParking
//
//  Created by Michael Scofield on 2014-12-23.
//  Copyright (c) 2014 Michael. All rights reserved.
//

#import "DBHelper.h"
#import <leveldb/db.h>
#import <leveldb/options.h>
#import <leveldb/write_batch.h>
@interface DBHelper()
{
    leveldb::DB *_db;
    leveldb::ReadOptions _readOptions;
    leveldb::WriteOptions _writeOptions;

    NSString *_path;
}
@end
@implementation DBHelper
NS_INLINE leveldb::Slice SliceByString(NSString *string)
{
    if (!string) return NULL;
    const char *cStr = [string UTF8String];
    size_t len = strlen(cStr);
    if (len == 0) return NULL;
    return leveldb::Slice(cStr,strlen(cStr));
}

NS_INLINE NSString *StringBySlice(const leveldb::Slice &slice)
{
    if (slice.empty()) return nil;
    const char *bytes = slice.data();
    const size_t len = slice.size();
    if (len == 0) return nil;
    return [[NSString alloc] initWithBytes:bytes length:len encoding:NSUTF8StringEncoding];
}

+ (DBHelper *)levelDBWithPath:(NSString *)path
{
    return [[self alloc] initWithPath:path];
}

- (id)initWithPath:(NSString *)path
{
    self = [super init];
    if (self)
    {
        _path = path;
        leveldb::Options options;
        options.create_if_missing = true;
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:_path])
        {
            BOOL sucess = [[NSFileManager defaultManager] createDirectoryAtPath:_path
                                                    withIntermediateDirectories:YES
                                                                     attributes:NULL
                                                                          error:NULL];
            if (!sucess)
            {
                return nil;
            }
        }
        
        leveldb::Status status = leveldb::DB::Open(options, [_path fileSystemRepresentation], &_db);
        if (!status.ok())
        {
            return nil;
        }
        
        //_readOptions.fill_cache = false;
        _writeOptions.sync = false;
    }
    return self;
}

- (void)dealloc
{
    delete _db;
    _db = NULL;
}

#pragma mark -
#pragma mark Getting Default Values

- (BOOL)boolForKey:(NSString *)aKey
{
    return [[self stringForKey:aKey] boolValue];
}

- (double)floatForKey:(NSString *)aKey
{
    return [[self stringForKey:aKey] doubleValue];
}

- (NSInteger)intForKey:(NSString *)aKey
{
    return [[self stringForKey:aKey] integerValue];
}

- (NSString *)stringForKey:(NSString *)aKey
{
    if (!_db || !aKey) return nil;
    leveldb::Slice sliceKey = SliceByString(aKey);
    std::string v_string;
    leveldb::Status status = _db->Get(_readOptions, sliceKey, &v_string);
    if (!status.ok()) return nil;
    return [[NSString alloc] initWithBytes:v_string.data() length:v_string.length() encoding:NSUTF8StringEncoding];
}

- (NSData *)dataForKey:(NSString *)aKey
{
    if (!_db || !aKey) return nil;
    leveldb::Slice sliceKey = SliceByString(aKey);
    std::string v_string;
    leveldb::Status status = _db->Get(_readOptions, sliceKey, &v_string);
    if (!status.ok()) return nil;
    return [[NSData alloc] initWithBytes:v_string.data() length:v_string.length()];
}

- (id)objectForKey:(NSString *)aKey
{
    id value = nil;
    if (!_db || !aKey) return value;
    leveldb::Slice sliceKey = SliceByString(aKey);
    std::string v_string;
    leveldb::Status status = _db->Get(_readOptions, sliceKey, &v_string);
    if (!status.ok()) return value;
    NSData *data = [[NSData alloc] initWithBytes:v_string.data() length:v_string.length()];
    if (!data) return value;
    @try {
        value = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    @catch (NSException *exception) {
        value = nil;
    }
    return value;
}

#pragma mark -
#pragma mark Setting Default Values

- (BOOL)setBool:(BOOL)value forKey:(NSString *)aKey
{
    return [self setString:[NSString stringWithFormat:@"%d",value] forKey:aKey];
}

- (BOOL)setInt:(NSInteger)value forKey:(NSString *)aKey
{
    return [self setString:[NSString stringWithFormat:@"%ld",value] forKey:aKey];
}

- (BOOL)setFloat:(double)value forKey:(NSString *)aKey
{
    return [self setString:[NSString stringWithFormat:@"%f",value] forKey:aKey];
}

- (BOOL)setString:(NSString *)value forKey:(NSString *)aKey
{
    if (!_db || !value || !aKey) return NO;
    leveldb::Slice sliceKey = SliceByString(aKey);
    leveldb::Slice sliceValue = SliceByString(value);
    leveldb::Status status = _db->Put(_writeOptions, sliceKey, sliceValue);
    return status.ok();
}

- (BOOL)setData:(NSData *)value forKey:(NSString *)aKey
{
    if (!_db || !value || !aKey) return NO;
    leveldb::Slice sliceKey = SliceByString(aKey);
    leveldb::Slice sliceValue = leveldb::Slice((char *)[value bytes],[value length]);
    leveldb::Status status = _db->Put(_writeOptions, sliceKey, sliceValue);
    return status.ok();
}

- (BOOL)setObject:(id)value forKey:(NSString *)aKey
{
    if (!_db || !value || !aKey) return NO;
    NSData *data = nil;
    @try {
        data = [NSKeyedArchiver archivedDataWithRootObject:value];
    }
    @catch (NSException *exception) {
        return NO;
    }
    if (!data) return NO;
    leveldb::Slice sliceKey = SliceByString(aKey);
    leveldb::Slice sliceValue = leveldb::Slice((char *)[data bytes],[data length]);
    leveldb::Status status = _db->Put(_writeOptions, sliceKey, sliceValue);
    return status.ok();
}

- (BOOL)removeValueForKey:(NSString *)aKey
{
    if (!_db || !aKey) return NO;
    leveldb::Slice sliceKey = SliceByString(aKey);
    leveldb::Status status = _db->Delete(_writeOptions, sliceKey);
    return status.ok();
}

- (NSArray *)allKeys
{
    if (_db == NULL) return nil;
    NSMutableArray *keys = [NSMutableArray array];
    [self enumerateKeys:^(NSString *key, BOOL *stop) {
        [keys addObject:key];
    }];
    return keys;
}

- (void)enumerateKeys:(void (^)(NSString *key, BOOL *stop))block
{
    if (_db == NULL) return;
    BOOL stop = NO;
    leveldb::Iterator* iter = _db->NewIterator(leveldb::ReadOptions());
    for (iter->SeekToFirst(); iter->Valid(); iter->Next()) {
        leveldb::Slice key = iter->key();
        NSString *k = StringBySlice(key);
        block(k, &stop);
        if (stop)
            break;
    }
    delete iter;
}

- (BOOL)clear
{
    NSArray *keys = [self allKeys];
    BOOL result = YES;
    for (NSString *k in keys) {
        result = result && [self removeValueForKey:k];
    }
    return result;
}

- (BOOL)deleteDB
{
    delete _db;
    _db = NULL;
    return [[NSFileManager defaultManager] removeItemAtPath:_path error:NULL];
}

@end
