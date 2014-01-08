//
//  ChildBrowserViewController.m
//
//  Created by Jesse MacFadyen on 21/07/09.
//  Copyright 2009 Nitobi. All rights reserved.
//  Copyright (c) 2011, IBM Corporation
//  Copyright 2011, Randy McMillan
//

#import "ChildBrowserViewController.h"

@interface ChildBrowserViewController()

//Gesture Recognizer
- (void)addGestureRecognizer;

@end

@implementation ChildBrowserViewController

@synthesize imageURL, isImage, scaleEnabled;
@synthesize delegate, orientationDelegate;
@synthesize spinner, webView, addressLabel, toolbar;
@synthesize closeBtn, refreshBtn, backBtn, fwdBtn, safariBtn;
@synthesize whiteListURLs, parentWebView;

//    Add *-72@2x.png images to ChildBrowser.bundle
//    Just duplicate and rename - @RandyMcMillan

+ (NSString*) resolveImageResource:(NSString*)resource
{
	NSString* systemVersion = [[UIDevice currentDevice] systemVersion];
	BOOL isLessThaniOS4 = ([systemVersion compare:@"4.0" options:NSNumericSearch] == NSOrderedAscending);
	
	// the iPad image (nor retina) differentiation code was not in 3.x, and we have to explicitly set the path
	if (isLessThaniOS4)
	{
        return [NSString stringWithFormat:@"%@.png", resource];
	} else if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] == YES && [[UIScreen mainScreen] scale] == 2.00)
    {
	    return [NSString stringWithFormat:@"%@@2x.png", resource];
    }

	
	return resource;
}



- (ChildBrowserViewController*)initWithScale:(BOOL)enabled parentWebView:(UIWebView *) parentWeb
{
    self = [super init];
	if(self!=nil)
    {
        [self addGestureRecognizer];
        NSString * useragent = [NSString stringWithString:@"Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_0 like Mac OS X; en-us) AppleWebKit/532.9 (KHTML, like Gecko) Version/4.0.5 Mobile/8A293 Safari/6531.22.7"];
    
        NSDictionary *dictionary = [[NSDictionary alloc] initWithObjectsAndKeys:useragent, @"UserAgent", nil];
        [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
    }
	
	self.scaleEnabled = enabled;
    self.parentWebView = parentWeb;
	
	return self;	
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
	self.refreshBtn.image = [UIImage imageNamed:[[self class]
                                                 resolveImageResource:@"ChildBrowser.bundle/but_refresh"]];
	self.backBtn.image = [UIImage imageNamed:[[self class]
                                              resolveImageResource:@"ChildBrowser.bundle/arrow_left"]];
	self.fwdBtn.image = [UIImage imageNamed:[[self class]
                                        resolveImageResource:@"ChildBrowser.bundle/arrow_right"]];
	self.safariBtn.image = [UIImage imageNamed:[[self class]
                                           resolveImageResource:@"ChildBrowser.bundle/compass"]];

	self.webView.delegate = self;
	self.webView.scalesPageToFit = TRUE;
	self.webView.backgroundColor = [UIColor whiteColor];
    
	NSLog(@"View did load");
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	NSLog(@"View did UN-load");
}


- (void)dealloc {
	self.webView.delegate = nil;
    self.delegate = nil;
    self.orientationDelegate = nil;
	
#if !__has_feature(objc_arc)
    [self.whiteListURLs release];
    [self.parentWebView release];
	[self.webView release];
	[self.closeBtn release];
	[self.refreshBtn release];
	[self.addressLabel release];
	[self.backBtn release];
	[self.fwdBtn release];
	[self.safariBtn release];
	[self.spinner release];
    [self.toolbar release];
d
	[super dealloc];
#endif
}

-(void)closeBrowser
{
	
	if (self.delegate != NULL)
	{
		[self.delegate onClose];
	}
    if ([self respondsToSelector:@selector(presentingViewController)]) { 
        //Reference UIViewController.h Line:179 for update to iOS 5 difference - @RandyMcMillan
        [[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
    } else {
        [[self parentViewController] dismissModalViewControllerAnimated:YES];
    }
}

-(IBAction) onDoneButtonPress:(id)sender
{
    [self.webView stopLoading];
	[self closeBrowser];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]];
    [self.webView loadRequest:request];
}


-(IBAction) onSafariButtonPress:(id)sender
{
	
	if (self.delegate != nil)
	{
		[self.delegate onOpenInSafari];
	}
	
	if(isImage)
	{
		NSURL* pURL = [[ [NSURL alloc] initWithString:imageURL ] autorelease];
		[ [ UIApplication sharedApplication ] openURL:pURL  ];
	}
	else
	{
		NSURLRequest *request = webView.request;
		[[UIApplication sharedApplication] openURL:request.URL];
	}

	 
}


- (void)loadURL:(NSString*)url
{
	NSLog(@"Opening Url : %@",url);
	 
	if( [url hasSuffix:@".png" ]  || 
	    [url hasSuffix:@".jpg" ]  || 
		[url hasSuffix:@".jpeg" ] || 
		[url hasSuffix:@".bmp" ]  || 
		[url hasSuffix:@".gif" ]  )
	{
		self.imageURL = nil;
		self.imageURL = url;
		self.isImage = YES;
		NSString* htmlText = @"<html><body style='background-color:#333;margin:0px;padding:0px;'><img style='min-height:200px;margin:0px;padding:0px;width:100%;height:auto;' alt='' src='IMGSRC'/></body></html>";
		htmlText = [ htmlText stringByReplacingOccurrencesOfString:@"IMGSRC" withString:url ];

		[webView loadHTMLString:htmlText baseURL:[NSURL URLWithString:@""]];
		
	}
	else
	{
		self.imageURL = @"";
		self.isImage = NO;
		NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
		[self.webView loadRequest:request];
	}
	self.webView.hidden = NO;
}

- (BOOL)webView:(UIWebView *)theWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString * url = [[request URL] absoluteString];
    NSURL * urlFromNSURL = [NSURL URLWithString: url];
    NSString * host = urlFromNSURL.host;
    NSLog(@"url: %@", url);
    
    BOOL isInternalURL = NO;
    
    //if its local or it's in the whitelist
    if ([urlFromNSURL isFileURL] )
    {
        isInternalURL = YES;
        
        //for testing...
        if ( [url rangeOfString:@"childBrowserTest.html"].location != NSNotFound)
        {
            isInternalURL = NO;
        }
        
    }
    else if (self.whiteListURLs)
    {
        NSEnumerator *enu = [self.whiteListURLs objectEnumerator];
        NSString * domain;
        while ((domain = [enu nextObject])) {
            if (host && [host rangeOfString:domain].location != NSNotFound)
            {
                isInternalURL = YES;
                break;
            } 
        }                
    }
    
    //open whitelist in parent browser...
    if (isInternalURL)
    {
        [self.parentWebView loadRequest:request];
        [self closeBrowser];        
        return NO;
    }
    
    
    return YES;
}



- (void)webViewDidStartLoad:(UIWebView *)sender {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

	self.addressLabel.text = @"Loading...";
	self.backBtn.enabled = webView.canGoBack;
	self.fwdBtn.enabled = webView.canGoForward;
	
	[self.spinner startAnimating];
	
}

- (void)webViewDidFinishLoad:(UIWebView *)sender 
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

	NSURLRequest *request = self.webView.request;
	NSLog(@"New Address is : %@",request.URL.absoluteString);

	self.addressLabel.text = request.URL.absoluteString;
	self.backBtn.enabled = webView.canGoBack;
	self.fwdBtn.enabled = webView.canGoForward;
	[self.spinner stopAnimating];
	
	if (self.delegate != NULL) {
		[self.delegate onChildLocationChange:request.URL.absoluteString];
	}
}

- (void)webView:(UIWebView *)wv didFailLoadWithError:(NSError *)error {
    NSLog (@"webView:didFailLoadWithError");
    NSLog (@"%@", [error localizedDescription]);
    NSLog (@"%@", [error localizedFailureReason]);
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

    [spinner stopAnimating];
    addressLabel.text = @"Failed";
}

#pragma mark - Disaplying Controls

- (void)resetControls
{
    
    CGRect rect = addressLabel.frame;
    rect.origin.y = self.view.frame.size.height-(44+26);
    [addressLabel setFrame:rect];
    rect=webView.frame;
    rect.size.height= self.view.frame.size.height-(44+26);
    [webView setFrame:rect];
    [addressLabel setHidden:NO];
    [toolbar setHidden:NO];
}

- (void)showLocationBar:(BOOL)isShow
{
    if(isShow)
        return;
    //the addreslabel heigth 21 toolbar 44
    CGRect rect = webView.frame;
    rect.size.height+=(26+44);
    [webView setFrame:rect];
    [addressLabel setHidden:YES];
    [toolbar setHidden:YES];
}

- (void)showAddress:(BOOL)isShow
{
    if(isShow)
        return;
    CGRect rect = webView.frame;
    rect.size.height+=(26);
    [webView setFrame:rect];
    [addressLabel setHidden:YES];
    
}

- (void)showNavigationBar:(BOOL)isShow
{
    if(isShow)
        return;
    CGRect rect = webView.frame;
    rect.size.height+=(44);
    [webView setFrame:rect];
    [toolbar setHidden:YES];
    rect = addressLabel.frame;
    rect.origin.y+=44;
    [addressLabel setFrame:rect];
}

#pragma mark - Gesture Recognizer

- (void)addGestureRecognizer
{
    UISwipeGestureRecognizer* closeRG = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(closeBrowser)];
    closeRG.direction = UISwipeGestureRecognizerDirectionLeft;
    closeRG.delegate=self;
    [self.view addGestureRecognizer:closeRG];
    [closeRG release];
}

//- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
//{
//    return YES;
//}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return YES;
}

#pragma mark CDVOrientationDelegate

- (BOOL)shouldAutorotate
{
    if ((self.orientationDelegate != nil) && [self.orientationDelegate respondsToSelector:@selector(shouldAutorotate)]) {
        return [self.orientationDelegate shouldAutorotate];
    }
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    if ((self.orientationDelegate != nil) && [self.orientationDelegate respondsToSelector:@selector(supportedInterfaceOrientations)]) {
        return [self.orientationDelegate supportedInterfaceOrientations];
    }

    // return UIInterfaceOrientationMaskPortrait; // NO - is IOS 6 only
    return (1 << UIInterfaceOrientationPortrait);
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ((self.orientationDelegate != nil) && [self.orientationDelegate respondsToSelector:@selector(shouldAutorotateToInterfaceOrientation:)]) {
        return [self.orientationDelegate shouldAutorotateToInterfaceOrientation:interfaceOrientation];
    }

    return YES;
}

@end
