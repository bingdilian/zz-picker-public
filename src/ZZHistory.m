#import "ZZPicker.h"

static const NSUInteger ZZHistoryTaskLimit = 10;

NSURL *ZZHitHistoryDirectory(void) {
    NSURL *support=[NSFileManager.defaultManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask].firstObject;
    return [support URLByAppendingPathComponent:@"ZZPicker-v1-hits" isDirectory:YES];
}

static NSArray<NSURL *> *ZZHistoryFiles(NSURL *directory) {
    NSArray<NSURL *> *files=[NSFileManager.defaultManager contentsOfDirectoryAtURL:directory includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:nil];
    NSPredicate *isTask=[NSPredicate predicateWithBlock:^BOOL(NSURL *file, NSDictionary *bindings) {
        (void)bindings;
        return [file.lastPathComponent hasPrefix:@"run-"]&&[file.pathExtension isEqual:@"json"];
    }];
    return [[files filteredArrayUsingPredicate:isTask]sortedArrayUsingComparator:^NSComparisonResult(NSURL *first, NSURL *second) {
        return [second.lastPathComponent compare:first.lastPathComponent options:NSNumericSearch];
    }];
}

BOOL ZZSaveHitTask(NSURL *directory, NSDictionary *task) {
    NSString *run=task[@"run"];
    if(![run hasPrefix:@"run-"]||[run rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"run-0123456789"].invertedSet].location!=NSNotFound)return NO;
    NSData *data=[NSJSONSerialization dataWithJSONObject:task options:0 error:nil];
    NSFileManager *files=NSFileManager.defaultManager;
    if(!data||![files createDirectoryAtURL:directory withIntermediateDirectories:YES attributes:nil error:nil])return NO;
    [directory setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];
    NSURL *file=[directory URLByAppendingPathComponent:[run stringByAppendingPathExtension:@"json"]];
    if(![data writeToURL:file options:NSDataWritingAtomic error:nil])return NO;
    NSArray<NSURL *> *tasks=ZZHistoryFiles(directory);
    for(NSUInteger i=ZZHistoryTaskLimit;i<tasks.count;i++)[files removeItemAtURL:tasks[i] error:nil];
    return YES;
}

NSArray<NSDictionary *> *ZZReadHitTasks(NSURL *directory) {
    NSMutableArray *tasks=[NSMutableArray new];
    for(NSURL *file in ZZHistoryFiles(directory)){
        NSData *data=[NSData dataWithContentsOfURL:file];
        if(!data)continue;
        id task=[NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if(![task isKindOfClass:NSDictionary.class]||![task[@"rows"]isKindOfClass:NSArray.class]||![task[@"run"]isKindOfClass:NSString.class]||![task[@"model"]isKindOfClass:NSString.class])continue;
        [tasks addObject:task];
        if(tasks.count==ZZHistoryTaskLimit)break;
    }
    return tasks;
}
