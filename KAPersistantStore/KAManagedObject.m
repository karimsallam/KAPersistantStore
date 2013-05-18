//
//  KAManagedObject.m
//  KAPersistantStore
//
//  Created by Karim Mohamed Abdel Aziz Sallam on 18/05/13.
//  Copyright (c) 2013 K-Apps. All rights reserved.
//

#import "KAManagedObject.h"

NSString * const KAManagedObjectCacheKey = @"KAManagedObjectCacheKey";

@implementation KAManagedObject

#pragma mark - Overrides

+ (NSEntityDescription *)entityInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
	[NSException raise:NSInternalInconsistencyException
                format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
	return nil;
}

+ (id)insertInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
	[NSException raise:NSInternalInconsistencyException
                format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
	return nil;
}

+ (NSString *)idKeyName {
    [NSException raise:NSInternalInconsistencyException
                format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
    return nil;
}

- (void)updateWithDictionary:(NSDictionary *)aDictionary {
	[NSException raise:NSInternalInconsistencyException
                format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
}

#pragma mark - Public methods

+ (void)cacheWithIds:(NSArray *)ids
managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
	[self cacheWithIds:ids relationshipKeyPaths:nil managedObjectContext:managedObjectContext];
}

+ (void)cacheWithIds:(NSArray *)ids
relationshipKeyPaths:(NSArray *)keyPaths
managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
	ids = [self flattenIds:ids];
	NSMutableArray *entities = [NSMutableArray arrayWithArray:[self fetchOrInsertWithIds:ids
                                                                    relationshipKeyPaths:keyPaths
                                                                    managedObjectContext:managedObjectContext]];
	NSArray *entityIds = [entities valueForKeyPath:[self idKeyName]];
	for (NSString *anId in ids) {
		if ([entityIds containsObject:anId] == NO) {
			KAManagedObject *entity = [self insertInManagedObjectContext:managedObjectContext];
			[entity setValue:anId forKey:[self idKeyName]];
			[entities addObject:entity];
		}
	}
	NSMutableDictionary *entityCache = [self entityCache];
	for (id entity in entities) {
		[entityCache setObject:entity forKey:[entity valueForKey:[self idKeyName]]];
    }
}

+ (id)updateOrInsertWithDictionary:(NSDictionary *)dictionary
                         idKeyPath:(NSString *)idKeyPath
              managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
	KAManagedObject *entity = [self fetchOrInsertWithId:[dictionary valueForKeyPath:idKeyPath]
                                   managedObjectContext:managedObjectContext];
	[entity updateWithDictionary:dictionary];
	return entity;
}

+ (void)flushCache {
	NSMutableDictionary *cacheDictionary = [[[NSThread currentThread] threadDictionary] objectForKey:KAManagedObjectCacheKey];
	if (cacheDictionary == nil) {
		cacheDictionary = [NSMutableDictionary dictionary];
		[[[NSThread currentThread] threadDictionary] setObject:cacheDictionary
                                                        forKey:KAManagedObjectCacheKey];
	}
	[cacheDictionary removeObjectForKey:NSStringFromClass(self)];
}

#pragma mark - Private

+ (NSMutableDictionary *)threadCache {
	// NSManagedObjectContext is not thread safe, so we store the cache in a threadDictionary.
	NSMutableDictionary *cacheDictionary = [[[NSThread currentThread] threadDictionary] objectForKey:KAManagedObjectCacheKey];
	if (cacheDictionary == nil) {
		cacheDictionary = [NSMutableDictionary dictionary];
		[[[NSThread currentThread] threadDictionary] setObject:cacheDictionary forKey:KAManagedObjectCacheKey];
	}
	return cacheDictionary;
}

+ (NSMutableDictionary *)entityCache {
	NSMutableDictionary *entityDictionary = [[self threadCache] objectForKey:NSStringFromClass(self)];
	if (entityDictionary == nil) {
		entityDictionary = [NSMutableDictionary dictionary];
		[[self threadCache] setObject:entityDictionary forKey:NSStringFromClass(self)];
	}
	return entityDictionary;
}

+ (KAManagedObject *)fetchOrInsertWithId:(NSString *)anId
                    managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    if ([[self entityCache] objectForKey:anId] != nil) {
		return [[self entityCache] objectForKey:anId];
    }
    
	NSArray *entities = [self fetchOrInsertWithIds:[NSArray arrayWithObject:anId]
                              relationshipKeyPaths:nil
                              managedObjectContext:managedObjectContext];
	KAManagedObject *entity = nil;
	if ([entities count] == 0) {
		entity = [self insertInManagedObjectContext:managedObjectContext];
	}
    else if ([entities count] == 1) {
		entity = [entities objectAtIndex:0];
	}
    else {
		[NSException raise:NSInternalInconsistencyException
                    format:@"Found %d %@ with Id: %@", [entities count], NSStringFromClass(self), anId];
	}
	return entity;
}

+ (NSArray *)fetchOrInsertWithIds:(NSArray *)ids
             relationshipKeyPaths:(NSArray *)keyPaths
             managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[self entityInManagedObjectContext:managedObjectContext]];
	[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"%K IN %@", [self idKeyName], ids]];
	if (keyPaths != nil) {
		[fetchRequest setRelationshipKeyPathsForPrefetching:keyPaths];
    }
    
	NSArray *entities = [managedObjectContext executeFetchRequest:fetchRequest error:nil];
	return entities;
}

+ (NSArray *)flattenIds:(NSArray *)ids {
	NSMutableSet *idSet = [NSMutableSet set];
	for (id element in ids) {
		if ([element isKindOfClass:[NSArray class]] == YES) {
			[idSet addObjectsFromArray:[self flattenIds:element]];
		}
        else {
			[idSet addObject:element];
		}
	}
	return [idSet allObjects];
}

@end
