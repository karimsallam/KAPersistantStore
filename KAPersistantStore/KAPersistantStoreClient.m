//
//  KAPersistantStoreClient.m
//  KAPersistantStore
//
//  Created by Karim Mohamed Abdel Aziz Sallam on 18/05/13.
//  Copyright (c) 2013 K-Apps. All rights reserved.
//

#import "KAPersistantStoreClient.h"

@interface KAPersistantStoreClient ()

@property (strong, nonatomic) NSManagedObjectModel          *managedObjectModel;
@property (strong, nonatomic) NSManagedObjectContext        *mainManagedObjectContext;
@property (strong, nonatomic) NSPersistentStoreCoordinator  *persistentStoreCoordinator;

@end

@implementation KAPersistantStoreClient

- (id)initWithManagedObjectModelName:(NSString *)managedObjectModelName
                        databaseName:(NSString *)databaseName
                              bundle:(NSString *)bundleNameOrNil
                          folderName:(NSString *)folderNameOrNil {
    NSAssert(managedObjectModelName != nil, @"You must provide a managedObjectModelName");
    NSAssert(databaseName != nil, @"You must provide a databaseName");
    self = [super init];
    if (self != nil) {
        _managedObjectModelName = [managedObjectModelName copy];
        _databaseName = [databaseName copy];
        _bundleName = [bundleNameOrNil copy];
        _folderName = [folderNameOrNil copy];
    }
    return self;
}

- (id)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel
                    databaseName:(NSString *)databaseName
                      folderName:(NSString *)folderNameOrNil {
    NSAssert(managedObjectModel != nil, @"You must provide a managedObjectModel");
    NSAssert(databaseName != nil, @"You must provide a databaseName");
    self = [super init];
    if (self != nil) {
        _managedObjectModel = [managedObjectModel copy];
        _databaseName = [databaseName copy];
        _folderName = [folderNameOrNil copy];
    }
    return self;
}

- (void)dealloc {
    [self saveContext];
}

#pragma mark - Core Data stack

- (NSManagedObjectModel *)managedObjectModel {
	if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    if (self.managedObjectModelName == nil) {
        return nil;
    }
    
    NSString *momPath = self.managedObjectModelName;
    if (self.bundleName != nil) {
        momPath = [NSString stringWithFormat:@"%@/%@", self.bundleName, self.managedObjectModelName];
    }
    
    NSURL *objectModelURL = [[NSBundle mainBundle] URLForResource:momPath withExtension:@"momd"];
    if (objectModelURL == nil) {
        objectModelURL = [[NSBundle mainBundle] URLForResource:momPath withExtension:@"mom"];
    }
    
    return _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:objectModelURL];
}

- (NSManagedObjectContext *)mainManagedObjectContext {
	if (_mainManagedObjectContext != nil) {
        return _mainManagedObjectContext;
    }
    
	// Create the main object context only on the main thread.
	if ([NSThread isMainThread] == NO) {
		[self performSelectorOnMainThread:@selector(mainManagedObjectContext) withObject:nil waitUntilDone:YES];
		return _mainManagedObjectContext;
	}
    
	_mainManagedObjectContext = [[NSManagedObjectContext alloc] init];
	[_mainManagedObjectContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
    [_mainManagedObjectContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mergeChangesFromContextDidSaveNotification:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:nil];
    
	return _mainManagedObjectContext;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    if (self.managedObjectModel == nil) {
        return nil;
    }
    if (self.databaseName == nil) {
        return nil;
    }
    
    NSURL *storeURL = [self storeURL];
    if (storeURL == nil) {
        return nil;
    }
    
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
                             nil];
    NSError *error = nil;
	_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
	if ([_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                  configuration:nil
                                                            URL:storeURL
                                                        options:options
                                                          error:&error] == nil) {
        NSLog(@"Can't add/merge persistent store: %@", error);
        if ([[NSFileManager defaultManager] removeItemAtURL:storeURL error:&error] == NO) {
            NSLog(@"Can't remove previous persistent store file: %@, %@", error, [error userInfo]);
        }
        if ([_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                      configuration:nil
                                                                URL:storeURL
                                                            options:nil
                                                              error:&error] == nil) {
            NSLog(@"Can't add new persistent store: %@, %@", error, [error userInfo]);
        }
	}
    
	return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *)managedObjectContext {
	NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] init];
	[managedObjectContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
	return managedObjectContext;
}

- (BOOL)saveContext {
	if ([self.mainManagedObjectContext hasChanges] == NO) {
        return YES;
    }
    
	NSError *error = nil;
	if ([self.mainManagedObjectContext save:&error] == NO) {
        NSLog(@"Error while saving: %@", [error localizedDescription]);
        NSArray *detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
        if (detailedErrors && [detailedErrors count]) {
            for (NSError *detailedError in detailedErrors) {
                NSLog(@"Detailed Error: %@", [detailedError userInfo]);
            }
        }
        else {
            NSLog(@"%@", [error userInfo]);
        }
        return NO;
	}
	return YES;
}

- (BOOL)reset {
    NSURL *storeURL = [self storeURL];
    NSPersistentStore *persistentStore = [self.persistentStoreCoordinator persistentStoreForURL:storeURL];
    NSError *error = nil;
    if ([self.persistentStoreCoordinator removePersistentStore:persistentStore error:&error] == NO) {
        NSLog(@"Can't remove persistent store: %@, %@", error, [error userInfo]);
        return NO;
    }
    else {
        if ([[NSFileManager defaultManager] removeItemAtURL:storeURL error:&error] == NO) {
            NSLog(@"Can't remove persistent store file: %@, %@", error, [error userInfo]);
            return NO;
        }
        else if ([_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                           configuration:nil
                                                                     URL:storeURL
                                                                 options:nil
                                                                   error:&error] == nil) {
            NSLog(@"Can't add persistent store: %@, %@", error, [error userInfo]);
            return NO;
        }
    }
    return YES;
}

#pragma mark - Private

/* The NSManagedObjectContext in the NSOperation is on a background thread.
 * We want merge notifications to happen on the main thread and there is no
 * need to act on the main thread's own merge notifications.
 */
- (void)mergeChangesFromContextDidSaveNotification:(NSNotification *)notification {
    if (self.mainManagedObjectContext != [notification object]) {
        [self.mainManagedObjectContext performSelectorOnMainThread:@selector(mergeChangesFromContextDidSaveNotification:)
                                                        withObject:notification
                                                     waitUntilDone:NO];
    }
}

- (NSURL *)storeURL {
    if (self.databaseName == nil) {
        return nil;
    }
    
    NSURL *storeURL = [self applicationSupportDirectory];
    if (self.folderName != nil) {
        storeURL = [storeURL URLByAppendingPathComponent:self.folderName isDirectory:YES];
        
        BOOL isDir = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:[storeURL path] isDirectory:&isDir] == NO) {
            NSError *error = nil;
            if ([[NSFileManager defaultManager] createDirectoryAtURL:storeURL
                                          withIntermediateDirectories:YES
                                                           attributes:@{ NSURLIsExcludedFromBackupKey : @(YES) }
                                                                error:&error] == NO) {
                NSLog(@"Can't create database directory: %@", error);
                return nil;
            }
        }
        else if (isDir == NO) {
            NSLog(@"Database directory name is already taken by a file");
            return nil;
        }
    }
    
    return [storeURL URLByAppendingPathComponent:self.databaseName];
}

- (NSURL *)applicationSupportDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
