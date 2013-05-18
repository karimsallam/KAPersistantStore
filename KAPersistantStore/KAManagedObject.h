//
//  KAManagedObject.h
//  KAPersistantStore
//
//  Created by Karim Mohamed Abdel Aziz Sallam on 18/05/13.
//  Copyright (c) 2013 K-Apps. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface KAManagedObject : NSManagedObject

+ (void)cacheWithIds:(NSArray *)ids
managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

+ (void)cacheWithIds:(NSArray *)ids
relationshipKeyPaths:(NSArray *)keyPaths
managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

+ (id)updateOrInsertWithDictionary:(NSDictionary *)dictionary
                         idKeyPath:(NSString *)idKeyPath
              managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

+ (void)flushCache;

#pragma mark - Overrides

+ (NSString *)idKeyName;

- (void)updateWithDictionary:(NSDictionary *)dictionary;

@end
