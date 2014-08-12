//
//  FwAppDelegate.m
//  fw_encoder
//
//  Created by Lee Denny on 7/12/14.
//  Copyright (c) 2014 fw-labs. All rights reserved.
//

#import "FwAppDelegate.h"

#import "FwViewController.h"
#import "HomeViewController.h"
#import "SettingViewController.h"
#import "HelpViewController.h"


@implementation FwAppDelegate

- (void)dealloc
{
    [_persistentStoreCoordinator release];
    [_managedObjectModel release];
    [_managedObjectContext release];
    [super dealloc];
}

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    [self createSettingFile];
   
    [self displayViewController:[viewContollers objectAtIndex:0]];

    
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag{
    
    if (flag) {
        return NO;
    }else{
        [myWindow makeKeyAndOrderFront:self];
        return YES;
    }
}


- (id)init{
    
    self = [super self];
    if (self) {
       
        viewContollers = [[NSMutableArray alloc] init];
        
        FwViewController  *vc;
        vc = [[HomeViewController alloc] init];
        [vc setManagedObjectContext:[self managedObjectContext]];
        [viewContollers addObject:vc];
        
        vc = [[SettingViewController alloc] init];
        [vc setManagedObjectContext:[self managedObjectContext]];
        [viewContollers addObject:vc];
        
        vc = [[HelpViewController alloc] init];
        [vc setManagedObjectContext:[self managedObjectContext]];
        [viewContollers addObject:vc];
    }
    return self;
}

- (void)displayViewController:(FwViewController *)vc{
    
    NSWindow *w = [box window];
    BOOL ended = [w makeFirstResponder:w];
    if (!ended) {
        NSBeep();
        return;
    }
    
    NSView *v = [vc view];
    [box setContentView:v];
}


- (IBAction)menuBtnClick:(id)sender{
    
    int i;
    if ([sender isEqual:btnHome]) {
        i = 0;
    }
    if ([sender isEqual:btnHelp]) {
        i = 2;
    }
    if ([sender isEqual:btnSetting]) {
        i = 1;
    }
    FwViewController *vc = [viewContollers objectAtIndex: i];
    [self displayViewController:vc];
    
    
}

- (void)createSettingFile{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL isDir;
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSArray *pathPublic = NSSearchPathForDirectoriesInDomains(NSSharedPublicDirectory, NSUserDomainMask, YES);
    
    NSString *userDefaultPath = [pathPublic objectAtIndex:0];
    NSString *userDefaultFTPUser = @"ftp_user";
    NSString *userDefaultFTPDomain = @"gloo.tv";
    
    NSArray *settings = [NSArray arrayWithObjects:userDefaultPath, userDefaultFTPUser, userDefaultFTPDomain, nil];

    
    if ([manager fileExistsAtPath:documentsDirectory isDirectory: &isDir]) {
        NSString *appSettingFile = [documentsDirectory stringByAppendingPathComponent:@"fw_encode.plist"];
        
        NSLog(@"App setting file = %@", appSettingFile);
        
        if (![manager fileExistsAtPath:appSettingFile]) {
            [[NSArray arrayWithObjects:settings, nil] writeToFile:appSettingFile atomically:NO];
        }       
        
        
    }else{
        NSLog(@"Documents directory not found!");
    }
}




// Returns the directory the application uses to store the Core Data store file. This code uses a directory named "com.fw-labs.fw_encoder" in the user's Application Support directory.
- (NSURL *)applicationFilesDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *appSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:@"com.fw-labs.fw_encoder"];
}

// Creates if necessary and returns the managed object model for the application.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
	
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"fw_encoder" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    
    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSError *error = nil;
    
    NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
    
    if (!properties) {
        BOOL ok = NO;
        if ([error code] == NSFileReadNoSuchFileError) {
            ok = [fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if (!ok) {
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    } else {
        if (![properties[NSURLIsDirectoryKey] boolValue]) {
            // Customize and localize this error.
            NSString *failureDescription = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationFilesDirectory path]];
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:101 userInfo:dict];
            
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    
    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"fw_encoder.storedata"];
    NSPersistentStoreCoordinator *coordinator = [[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom] autorelease];
    if (![coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]) {
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _persistentStoreCoordinator = [coordinator retain];
    
    return _persistentStoreCoordinator;
}

// Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) 
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];

    return _managedObjectContext;
}

// Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    return [[self managedObjectContext] undoManager];
}

// Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
- (IBAction)saveAction:(id)sender
{
    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    // Save changes in the application's managed object context before the application terminates.
    
    if (!_managedObjectContext) {
        return NSTerminateNow;
    }
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    
    if (![[self managedObjectContext] hasChanges]) {
        return NSTerminateNow;
    }
    
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {

        // Customize this code block to include application-specific recovery steps.              
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }

        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];

        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertAlternateReturn) {
            return NSTerminateCancel;
        }
    }

    return NSTerminateNow;
}

@end
