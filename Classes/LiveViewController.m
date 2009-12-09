//
//  LiveViewController.m
//  gnarus
//
//  Created by Ben Cochran on 11/2/09.
//  Copyright 2009 Ben Cochran. All rights reserved.
//

#import "LiveViewController.h"
#import <ARKit/ARKit.h>
#import "InfoBubbleController.h"

@implementation LiveViewController

@synthesize arViewController=_arViewController, locationManager=_locationManager,
			glassController=_glassController;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

- (id)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		self.wantsFullScreenLayout = NO;
	}
	return self;
}

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
	self.view = [[[UIView alloc] init] autorelease];
	//self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	self.locationManager = [[[CLLocationManager alloc] init] autorelease];
    self.locationManager.delegate = self;
	// Set our desired accuracy to 
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
	//self.locationManager.headingFilter = kCLHeadingFilterNone;
    // When "tracking" the user, the distance filter can be used to control the frequency with which location measurements
    // are delivered by the manager. If the change in distance is less than the filter, a location will not be delivered.
    //locationManager.distanceFilter = [[setupInfo objectForKey:kSetupInfoKeyDistanceFilter] doubleValue];
	
#if !TARGET_IPHONE_SIMULATOR

	NSLog(@"location manager: %@", self.locationManager);
	self.arViewController = [[ARGeoViewController alloc] initWithLocationManager:self.locationManager];	
	self.arViewController.delegate = self;
	//self.arViewController.wantsFullScreenLayout = NO;
	
	NSMutableArray *tempLocationArray = [[NSMutableArray alloc] initWithCapacity:10];
	CLLocationCoordinate2D tempCoord2D;
	CLLocation *tempLocation;
	ARGeoCoordinate *tempCoordinate;
	
	NSString *errorDesc = nil;
	NSPropertyListFormat format;
	NSString *plistPath;
	NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	plistPath = [rootPath stringByAppendingFormat:@"Locations.plist"];
	if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
		plistPath = [[NSBundle mainBundle] pathForResource:@"Locations" ofType:@"plist"];
	}
	NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
	NSArray *temp = (NSArray *)[NSPropertyListSerialization propertyListFromData:plistXML mutabilityOption:NSPropertyListMutableContainersAndLeaves format:&format errorDescription:&errorDesc];
	if (!temp) {
		NSLog(@"Error reading plist: %@, format: %d", errorDesc, format);
	}
	
	NSNumber *lat;
	NSNumber *lon;
	NSNumber *altitude;
	
	NSDictionary *locationDict;
	for (locationDict in temp) {
		NSLog(@"Lat: %@, Lon %@, Altitude %@, %@", [locationDict objectForKey:@"latitude"], [locationDict objectForKey:@"longitude"], [locationDict objectForKey:@"altitude"], [locationDict objectForKey:@"name"]);
		
		lat = [locationDict objectForKey:@"latitude"];
		lon = [locationDict objectForKey:@"longitude"];
		altitude = [locationDict objectForKey:@"altitude"];
		
		tempCoord2D.latitude = [lat doubleValue];
		tempCoord2D.longitude = [lon doubleValue];
		
		tempLocation = [[CLLocation alloc] initWithCoordinate:tempCoord2D altitude:[altitude doubleValue] horizontalAccuracy:0.0 verticalAccuracy:0.0 timestamp:[NSDate date]];
		
//		tempLocation = [[CLLocation alloc] initWithLatitude:[lat doubleValue] longitude:[lon doubleValue]];		
//		
//		tempLocation = [[CLLocation alloc] initWithCoordinate:(CLLocationCoordinate2D)coordinate altitude:(CLLocationDistance)altitude horizontalAccuracy:(CLLocationAccuracy)hAccuracy verticalAccuracy:(CLLocationAccuracy)vAccuracy timestamp:(NSDate *)timestamp]
		
		tempCoordinate = [ARGeoCoordinate coordinateWithLocation:tempLocation];
		tempCoordinate.title = [locationDict objectForKey:@"name"];
		
		[tempLocationArray addObject:tempCoordinate];
		[tempLocation release];
	}	
	
	[self.arViewController addCoordinates:tempLocationArray];
	[tempLocationArray release];
	
	
//	CLLocation *newCenter = [[CLLocation alloc] initWithLatitude:44.455464206683956 longitude:-93.15729260444641];
//	self.arViewController.centerLocation = newCenter;
//	[newCenter release];
	
	[self.view addSubview:self.arViewController.view];
	//self.view = self.arViewController.view;
	//[arViewController release];
	
	NSLog(@"Running on device");

#else
	self.arViewController = nil;
	
	// Add image
	UIImageView *imageView = [[[UIImageView alloc] initWithFrame:self.view.frame] autorelease];
	imageView.contentMode = UIViewContentModeScaleAspectFill;
	imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	imageView.image = [UIImage imageNamed:@"bg.jpg"];
	[self.view addSubview:imageView];
	
	// Add an info bubble
	InfoBubbleController *infoBubbleController = [[[InfoBubbleController alloc] init] autorelease];
	infoBubbleController.title = @"Memorial Hall";
	infoBubbleController.view.center = self.view.center;
	[self.view addSubview:infoBubbleController.view];	
	
	NSLog(@"Running in simulator");
#endif
	
	self.glassController = [[[LiveViewGlassController alloc] init] autorelease];
	[self.view addSubview:self.glassController.view];
	
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
	[self.arViewController viewWillAppear:NO];
	[self.navigationController setNavigationBarHidden:YES animated:animated];
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:animated];
	
    // Once configured, the location manager must be "started".
    [self.locationManager startUpdatingLocation];
	[self.arViewController startListening];
}

- (void)viewDidAppear:(BOOL)animated {
	[self.arViewController viewDidAppear:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
	// Stop locationManager from listening
	[self.arViewController viewWillDisappear:NO];
	[self.navigationController setNavigationBarHidden:NO animated:animated];
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:animated];
}

- (void)buttonClick:(id)sender {

	UIViewController *viewController = [[UIViewController alloc] init];
	viewController.title = @"Hello";

	UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 95, 21)] autorelease];
	label.text = @"Hello, world";
	label.center = viewController.view.center;
	label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
	[viewController.view addSubview:label];

	[self.navigationController pushViewController:viewController animated:YES];
}

- (BOOL)shouldAutorotateViewsToInterfaceOrientation:(UIInterfaceOrientation)possibleOrientation {
    return (possibleOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	[self.arViewController viewDidUnload];
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (void)dealloc {
	[_locationManager release];
	[_arViewController release];
	
    [super dealloc];
}

#pragma mark Location Manager

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
	NSLog(@"location: %@", newLocation);
	NSLog(@"altitude: %f", newLocation.altitude);
	NSLog(@"verticalAccuracy: %f", newLocation.verticalAccuracy);

    // Test that the horizontal accuracy does not indicate an invalid measurement
    if (newLocation.horizontalAccuracy < 0) return;
	
    // Test the age of the location measurement to determine if the measurement is cached
    NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
    if (locationAge > 5.0) return;

	
	NSLog(@"using");
	// Update the ARViewController's center
	self.arViewController.centerLocation = newLocation;
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	NSLog(@"error: %@", error);

    // The location "unknown" error simply means the manager is currently unable to get the location.
    if ([error code] != kCLErrorLocationUnknown) {
		/// Give an alert about this.
        //[self stopUpdatingLocation:NSLocalizedString(@"Error", @"Error")];
    }
}

#pragma mark ARKit Delegate

- (UIView *)viewForCoordinate:(ARCoordinate *)coordinate {
	InfoBubbleController *infoBubbleController = [[[InfoBubbleController alloc] init] autorelease];
	infoBubbleController.title = coordinate.title;
	//infoBubbleController.view.center = self.view.center;
	return infoBubbleController.view;	
}

@end

////////////////////////////////////////////////////////////

@implementation LiveViewGlassController

@synthesize toggleBarController=_toggleBarController, itemsToLayers=_itemsToLayers;

- (void)loadView {
	self.view = [[[UIView alloc] init] autorelease];
	self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	NSLog(@"glass view did load");
	self.itemsToLayers = [NSMutableDictionary dictionary];
	
	// Add toggle bar
	self.toggleBarController = [[[GNToggleBarController alloc] init] autorelease];
	self.toggleBarController.delegate = self;
	
	[self.view addSubview:self.toggleBarController.view];
	CGRect barFrame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y + self.view.frame.size.height - 58, self.view.frame.size.width, 58);
	self.toggleBarController.view.frame = barFrame;
	
//	GNToggleItem *item = [[[GNToggleItem alloc] initWithTitle:@"Sports" image:[UIImage imageNamed:@"sports.png"]] autorelease];
//	GNLayer *layer = [[[CarletonBuildings alloc] init] autorelease];
//	[self.toggleBarController addQuickToggleItem:item];
//	[self.itemsToLayers setObject:layer forKey:item];
//	
//	item = [[[GNToggleItem alloc] initWithTitle:@"Trees" image:[UIImage imageNamed:@"trees.png"]] autorelease];
//	[self.toggleBarController addQuickToggleItem:item];
//	[self.itemsToLayers setObject:layer forKey:item];
//	
//	item = [[[GNToggleItem alloc] initWithTitle:@"Food" image:[UIImage imageNamed:@"food.png"]] autorelease];
//	[self.toggleBarController addQuickToggleItem:item];
//	[self.itemsToLayers setObject:layer forKey:item];
//
//	item = [[[GNToggleItem alloc] initWithTitle:@"Gas" image:[UIImage imageNamed:@"gas.png"]] autorelease];
//	[self.toggleBarController addQuickToggleItem:item];
//	[self.itemsToLayers setObject:layer forKey:item];
	
	GNToggleItem *item = [[[GNToggleItem alloc] initWithTitle:@"Academic" image:[UIImage imageNamed:@"academic.png"]] autorelease];
	GNLayer *layer = [[[CarletonBuildings alloc] init] autorelease];
	[self.toggleBarController addQuickToggleItem:item];
	[self.itemsToLayers setObject:layer forKey:item];
	[[GNLayerManager sharedManager] addLayer:layer active:NO];
	
	item = [[[GNToggleItem alloc] initWithTitle:@"Tweets" image:[UIImage imageNamed:@"bird.png"]] autorelease];
	layer = [[[TweetLayer alloc] init] autorelease];
	[self.toggleBarController addQuickToggleItem:item];
	[self.itemsToLayers setObject:layer forKey:item];
	[[GNLayerManager sharedManager] addLayer:layer active:NO];

    [super viewDidLoad];
}

- (GNLayer *)layerForToggleItem:(GNToggleItem*)item {
	return [self.itemsToLayers objectForKey:item];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}


- (NSArray *) sortedLayersForLandmark:(GNLandmark *)landmark {
	// Copy the main (ordered) array of layers from the toggle bar then
	// filter it based on whether or not each ayer is in the landmark's
	// active layer list
	NSMutableArray* returnArray = [NSMutableArray array];
	
	NSArray* activeLayers = landmark.activeLayers;
	
	GNLayer* layer;
	
	for (GNToggleItem* item in [self.toggleBarController activeToggleItems]) {
		layer = [self layerForToggleItem:item];
		if ([activeLayers containsObject:layer]) {
			[returnArray addObject:item];
		}
	}
	
	return returnArray;
}

#pragma mark Toggle Bar Delegate

- (void)toggleBarController:(GNToggleBarController *)toggleBarController toggleItem:(GNToggleItem *)toggleItem changedToState:(BOOL)active {
	GNLayer *layer = [self layerForToggleItem:toggleItem];
	[[GNLayerManager sharedManager] setLayer:layer active:active];
	
	
	NSLog(@"toggleItem %@ became %@", toggleItem, active ? @"active" : @"inactive");
	NSLog(@"GNLayerManager %@", [GNLayerManager sharedManager]);
}

@end
