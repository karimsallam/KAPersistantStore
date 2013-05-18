//
//  KAPersistantStoreClient.h
//  KAPersistantStore
//
//  Created by Karim Mohamed Abdel Aziz Sallam on 18/05/13.
//  Copyright (c) 2013 K-Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface KAPersistantStoreClient : NSObject

- (id)initWithManagedObjectModelName:(NSString *)managedObjectModelName
                        databaseName:(NSString *)databaseName
                              bundle:(NSString *)bundleNameOrNil
                          folderName:(NSString *)folderNameOrNil;

- (id)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel
                    databaseName:(NSString *)databaseName
                      folderName:(NSString *)folderNameOrNil;

@property (readonly, copy, nonatomic) NSString *managedObjectModelName;
@property (readonly, copy, nonatomic) NSString *databaseName;
@property (readonly, copy, nonatomic) NSString *bundleName;
@property (readonly, copy, nonatomic) NSString *folderName;

- (NSManagedObjectModel *)managedObjectModel;
- (NSManagedObjectContext *)mainManagedObjectContext;
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;

- (NSManagedObjectContext *)managedObjectContext;

- (BOOL)saveContext;

- (BOOL)reset;

@end
