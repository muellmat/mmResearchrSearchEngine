/* mmResearchrSearchEngine */
//
//  Created by Matthias M�ller <muellmat@informatik.uni-tuebingen.de> 
//  on 17-10-2010. This source is based on the SDK created by Mekentosj on  
//  17-01-2007. Copyright (c) 2007 Mekentosj.com. All rights reserved.
// 
//  For use outside of the Papers application structure, please contact
//  Mekentosj at feedback@mekentosj.com
//  DO NOT REDISTRIBUTE WITHOUT ALL THE INCLUDED FILES

#import "mmResearchrSearchEngine.h"



@interface mmResearchrSearchEngine (private)
BOOL isSearching;
BOOL shouldContinueSearch;

// caches
NSDictionary *cachedPredefinedSearchTerms;
NSDictionary *cachedSearchFields;
NSArray *cachedStopwords;
@end

#pragma mark 



@interface mmResearchrSearchEngine (researchr_methods)

NSArray *searchtokens;

-(BOOL)verifyTokens;

@end

#pragma mark 



@implementation mmResearchrSearchEngine (researchr_methods)

// Verify the given tokens. Returns YES if everything is fine.
-(BOOL)verifyTokens {
	// ToDo
	return YES;
}

@end

#pragma mark 



// Here is where the implementation of the plugin starts and where the 
// different protocol methods are provided.
@implementation mmResearchrSearchEngine

#pragma mark 
#pragma mark Init

-(id)init {
    self = [super init];
	if (self != nil) {
		// space for early setup
		isSearching = NO;
		shouldContinueSearch = YES;
		
		// set the caches to nil
		cachedPredefinedSearchTerms = nil;
		cachedSearchFields = nil;
		cachedStopwords = nil;
	}
	return self;    
}

// Setup nib if necessary, here we initialize the preferences.
-(void)awakeFromNib {
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	
	if (![prefs objectForKey:@"mm_researchr_itemsPerPage"])
		[prefs setObject:[NSNumber numberWithInt:30] 
				  forKey:@"mm_researchr_itemsPerPage"];
	
	if (![prefs objectForKey:@"mm_researchr_shouldAutocomplete"])
		[prefs setObject:[NSNumber numberWithBool:NO] 
				  forKey:@"mm_researchr_shouldAutocomplete"];
}

// Cleanup last items here. NOTE: most items are cleaned in the 
// performCleanup:method, which is called after each run. The dealloc method 
// is only called when the plugin is unloaded, which is only when the app quits.
-(void)dealloc {
	// clear the caches
	[cachedPredefinedSearchTerms release];
	[cachedSearchFields release];
	[cachedStopwords release];
	
    [super dealloc];
}



#pragma mark -
#pragma mark Accessors

// Gives you a handle to the delegate object to which you deliver results and 
// notify progress - do not retain the delegate.
-(id)delegate {
	return delegate;
}

-(void)setDelegate:(id)newDelegate {
	delegate = newDelegate;
}



// Number of items that are fetched per batch, default is set by Papers but can 
// be overridden internally. NOTE: Only applies to the performSearchWithQuery:method
-(NSNumber*)itemsPerPage {
	return (itemsPerPage 
			? itemsPerPage
			: [[NSUserDefaults standardUserDefaults] objectForKey:@"mm_researchr_itemsPerPage"]);
}

-(void)setItemsPerPage:(NSNumber*)newItemsPerPage {
	[newItemsPerPage retain];
	[itemsPerPage release];
	itemsPerPage = newItemsPerPage;
}



// The offset we have to start fetching from. This is set by Papers before the 
// search is started and used when the user wishes to get the next page of 
// results. NOTE: Only applies to the performSearchWithQuery:method
-(NSNumber*)itemOffset {
	return itemOffset;
}

-(void)setItemOffset:(NSNumber*)newItemOffset {
	[newItemOffset retain];
	[itemOffset release];
	itemOffset = newItemOffset;
}



// Return the number of items found for this query, this is the total number 
// even if you fetch only one page.
-(NSNumber*)itemsFound {
	return itemsFound;
}

-(void)setItemsFound:(NSNumber*)newItemsFound {
	[newItemsFound retain];
	[itemsFound release];
	itemsFound = newItemsFound;
}



// Return the number of items you are about to retrieve (batch size). Return 
// the number of items you have retrieved. As long as this value is nil an 
// indeterminate progress bar is shown, the moment you return a non-nil value 
// for both the progress will be shown to the user. Use in combination with 
// the delegate method updateStatus:to push changes to the delegate and force 
// an update.
-(NSNumber*)itemsToRetrieve {
	return itemsToRetrieve;
}

-(void)setItemsToRetrieve:(NSNumber*)newItemsToRetrieve {
	[newItemsToRetrieve retain];
	[itemsToRetrieve release];
	itemsToRetrieve = newItemsToRetrieve;
	
	// inform our delegate to update the status
	id <PapersSearchPluginDelegate> del = [self delegate];
	[del updateStatus:self];
}



// Here we keep track of what we have retrieved thusfar since we work in batches.
-(NSNumber*)retrievedItems {
	return retrievedItems;
}

-(void)setRetrievedItems:(NSNumber*)newRetrievedItems {
	[newRetrievedItems retain];
	[retrievedItems release];
	retrievedItems = newRetrievedItems;
	
	// inform our delegate to update the status
	id <PapersSearchPluginDelegate> del = [self delegate];
	[del updateStatus:self];
}



-(void)incrementRetrievedItemsWith:(int)value {
	int old = [[self retrievedItems]intValue];
	[self setRetrievedItems:[NSNumber numberWithInt:old+value]];
}

// Return the current status of your plugin to inform the user. We use it in 
// combination with the delegate method updateStatus: to push changes to the 
// delegate and force an update.
// The statusstring is stored here such that the delegate can retrieve it
// when we call [delegate updateStatus]. note that we invoke this method
// automatically when we change the value in the setter.
-(NSString*)statusString {
	return statusString;
}

-(void)setStatusString:(NSString*)newStatusString {
	[newStatusString retain];
	[statusString release];
	statusString = newStatusString;
	
	// inform our delegate to update the status
	id <PapersSearchPluginDelegate> del = [self delegate];
	[del updateStatus:self];
}



// A method to check whether the search finished properly and one to get at any 
// errors that resulted. See above for usage of errorCodes.
-(NSError*)searchError {
	return searchError;
}

-(void)setSearchError:(NSError*)newSearchError {
	[newSearchError retain];
	[searchError release];
	searchError = newSearchError;
}



#pragma mark -
#pragma mark Interface interaction methods

// Name returns a string which is shown in the source list and used throughout 
// the UI. Make sure there are no naming collisions with existing plugins and 
// keep the name rather short.
-(NSString*)name {
	return NSLocalizedStringFromTableInBundle(
			  @"Researchr", 
			  nil, 
			  [NSBundle bundleForClass:[self class]], 
			  @"Localized name of the service");
}

// Allows to return a color for your plugin, here blue for Researchr. NOTE: In the 
// plugin test application you can click on the statusbar in the config panel 
// to get a color picker that helps you pick a color for the statusbar. The 
// color will be updated and logged into the console so that it can be entered here.
-(NSColor*)color {
	return [NSColor colorWithCalibratedRed:136.0/255.0
									 green:169.0/255.0
									  blue:249.0/255.0
									 alpha:1.0];	
}

// Return the logo as will be displayed in the search box. Take a look at the 
// sample plugins for examples. Suggested size 250w x 50h.
-(NSImage*)logo {
	return [[[NSImage alloc] initWithContentsOfFile:
			 [[NSBundle bundleForClass:[self class]] 
			  pathForResource:@"logo_researchr" ofType:@"tif"]] autorelease];
}

// Return an 37w x 31h icon for use in the statusbar (one with the magnifying class).
-(NSImage*)large_icon {
	return [[[NSImage alloc] initWithContentsOfFile:
			 [[NSBundle bundleForClass:[self class]] 
			  pathForResource:@"toolstrip_researchr" ofType:@"tif"]] autorelease];
}

// Return a 18w x 16 icon for use in the inspector bar (without a magnifying class).
-(NSImage*)small_icon {
	return [[[NSImage alloc] initWithContentsOfFile:
			 [[NSBundle bundleForClass:[self class]] 
			  pathForResource:@"statusbar_researchr" ofType:@"tif"]] autorelease];
}

// Return a 25w x23h icon for use in the source list (normal setting).
-(NSImage*)sourcelist_icon {
	return [[[NSImage alloc] initWithContentsOfFile:
			 [[NSBundle bundleForClass:[self class]] 
			  pathForResource:@"group_researchr" ofType:@"tif"]] autorelease];
}

// Return a 20w x 18h icon for use in the source list (small setting).
-(NSImage*)sourcelist_icon_small {
	return [[[NSImage alloc] initWithContentsOfFile:
			 [[NSBundle bundleForClass:[self class]] 
			  pathForResource:@"group_researchr_small" ofType:@"tif"]] autorelease];
}

// Return the weburl to the homepage of the searchengine/repository.
-(NSURL*)info_url {
	return [NSURL URLWithString:@"http://researchr.uni-trier.de/"];
}

// Return a unique identifier in the form of a reverse web address of the 
// search engine.
-(NSString*)identifier {
	return @"de.uni-trier.researchr";
}

// Return whether the search engine requires a subscription.
-(BOOL)requiresSubscription {
	return NO;
}

// Return NO if you only wish to use this plugin for matching or automatching.
// Note that you still need to fullfill the PapersSearchPluginProtocol protocol, 
// you can just leave most of its methods empty in that case.
-(BOOL)actsAsGeneralSearchEngine {
	return YES;
}



#pragma mark -
#pragma mark Preferences

// If your plugin needs to be configured you can return here a preference panel. 
// Take a look at the example plugin on how to use this. Otherwise return nil.
-(NSView*)preferenceView {
	return nil; //[preferenceWindow contentView];
}



#pragma mark -
#pragma mark Query Generation

// Return a dictionary of predefinedSearchTerms, can be a one or two levels deep.
// The key is the meny item name, if the value is a dictionary it will create a 
// submenu, if the value is a string it will be the searchterm that will be 
// filled in upon selection.
//
// Example:
//	<key>Availability</key>
//	<dict>
//		<key>Free Full Text</key>
//		<string>free full text[sb]</string>
//      ...
//	</dict>
//
// Return nil if not applicable      
-(NSDictionary*)predefinedSearchTerms {
	if (!cachedPredefinedSearchTerms) {
		NSString *dictpath = [[NSBundle bundleForClass:[self class]] 
							  pathForResource:@"ResearchrPredefinedTokens" ofType:@"plist"];
		cachedPredefinedSearchTerms = [[NSDictionary alloc]initWithContentsOfFile:dictpath];
	}
	return cachedPredefinedSearchTerms;
}

// Return a dictionary of search field codes that show up as choices in the 
// searchtokens the dictionary should contain an array under key "order" and a 
// dictionary under the key "fields" containing key-value pairs where the key 
// is the name of the field and the value a code that your plugin can translate 
// into the right parameters. We advise to adopt the PubMed model of field codes.
// 
// Example:
//	<key>order</key>
//	<array>
//		<string>First Author</string>
//		...
//  </array>
//	<key>fields</key>
//	<dict>
//		<key>First Author</key>
//		<string>[1AU]</string>
//      ...
//	</dict>
//
// Return nil if not applicable
-(NSDictionary*)searchFields {
	if (!cachedSearchFields) {
		NSString *dictpath = [[NSBundle bundleForClass:[self class]] 
							  pathForResource:@"ResearchrSearchFields" ofType:@"plist"];
		cachedSearchFields = [[NSDictionary alloc]initWithContentsOfFile:dictpath];
	}
	return cachedSearchFields;
}



#pragma mark Auto-completion

// Return yes if you wish to autocomplete searchterms if you do autocompletion 
// via the internet, be sure to check the server is up!
- (BOOL)autocompletesSearchTerms {
	return NO;
}

// Return an array of strings for the partial string, make sure this stuff works fast!
- (NSArray*)autocompletionsForPartialString:(NSString*)str {
	return [NSArray new];
}



#pragma mark -
#pragma mark Searching

// A method to make sure everything's set to go before starting, do some setup 
// or tests here if necessary. And a method to find out what the problems are 
// if things aren't set. See above for usage of errorCodes. For instance return 
// an error when the service is not up.
-(BOOL)readyToPerformSearch {
	// do some setup here if necessary
	shouldContinueSearch = YES;
	[self setSearchError:nil];
	[self setItemsFound:[NSNumber numberWithInt:0]];
	[self setRetrievedItems:[NSNumber numberWithInt:0]];
	return YES;	
}

// Here we simple return searchError, if something went wrong before we would 
// have set it to a non-nil value.
-(NSError*)searchPreparationError {
	
	return searchError;
}

// Used for the history items and saved folders in the descriptive string for the query.
-(NSString*)descriptiveStringForQuery:(NSArray*)tokens {
	if (tokens)
		return [[tokens valueForKey:@"displayString"]componentsJoinedByString:@"+"];
	else
		return @"";
}

// Return YES if you support cancelling the current search session (strongly advised).
-(BOOL)canCancelSearch {
	return YES; 
}

// This method is the main worker method and launches the search process, here 
// you are handed over the MTQueryTermTokens that were entered in the searchfield. 
// The tokens have the following key-value compliant fields:
// 
//   NSString *token;        - The searchterm like the user entered it
//   NSString *field;        - The field that was selected
//   NSString *code;         - The code that belongs to the selected field
//   NSString *operatorType; - The operator type (AND, NOT, OR)
//   NSNumber *predefined;   - A boolean NSNumber that indicates whether the 
//                             token was predefined.
// 
// Also you are handed the offset you have to start from, the first time for a 
// new query this will always be 0 subsequent pages are fetched by calling this 
// method with an offset which represents the last number of the last number of 
// items you returned. So if you fetched the first time 30 papers, the next 
// time the offset will be 30 for the next page of results. 
// 
// IMPORTANT: Try to always sort results on publication date!
// 
// NOTE: That this method runs in a separate thread. Signal your progress to 
//       the delegate.
-(void)performSearchWithQuery:(NSArray*)tokens {
	// Since we run threaded we need the autorelease pool!
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// Are we already searching?
	if (isSearching) {
		// Warning: CHECK WHAT HAPPENS IF CALLED AGAIN, AND CANCEL PREVIOUS ONE
		goto isAlreadySearching;
	}
	// Now we are
	isSearching = YES;
	
	// Inform delegate we're about to start
	id <PapersSearchPluginDelegate> del = [self delegate];
	[del didBeginSearch:self];
	
	// verify tokens
	if (![self verifyTokens]) {
		goto cleanup;
	}
	
	// test connection
	[self setStatusString:NSLocalizedStringFromTableInBundle(
		 @"Connecting with Researchr...", 
		 nil, 
		 [NSBundle bundleForClass:[self class]], 
		 @"Status message shown when plugin is connecting to the service")];
	
	// if there is no error, everything is fine
	[self setStatusString:NSLocalizedStringFromTableInBundle(
		 @"Connected to Researchr...", 
		 nil, 
		 [NSBundle bundleForClass:[self class]], 
		 @"Status message shown when the plugin has succesfully connected to the service")];
	
	// check whether we have been cancelled
	if (!shouldContinueSearch) {
		goto cleanup;
	}
	
	// ToDo
	
	
	
cleanup:
	
	[self setStatusString:NSLocalizedStringFromTableInBundle(
		 @"Done.", 
		 nil, 
		 [NSBundle bundleForClass:[self class]], 
		 @"Status message shown after all metadata has been retrieved")];
	
	// done, let the delegate know
	del = [self delegate];
	[del didEndSearch:self];
	
	isSearching = NO;
	
	
	
	// cleanup researchr stuff	
	
	
isAlreadySearching:	
	
	// cleanup nicely
	[pool release];
	
}

// Informs us that we should stop searching. Since we're running in a thread we 
// should check regularly if we have been cancelled.
-(void)cancelSearch {
	// we simply set the bool that is checked after each batch in the 
	// respective query methods
	shouldContinueSearch = NO;
	[self setStatusString:NSLocalizedStringFromTableInBundle(
		 @"Cancelling search...", 
		 nil, 
		 [NSBundle bundleForClass:[self class]], 
		 @"Status message shown while cancelling search.")];
}



#pragma mark -
#pragma mark Saved searches 

// NOT YET IMPLEMENTED IN PAPERS

// When a search is saved it will be regularly updated, only return those 
// results that are new since the given date. NOTE: This method runs in a 
// separate thread. Signal your progress to the delegate.
-(void)performSavedSearchWithQuery:(NSArray*)tokens afterDate:(NSDate*)date {
	// currently we simply invoke the whole thing:
	[self performSearchWithQuery:tokens];
	
	// Once we implement this in the future we will make use of Pubmed's 
	// reldate parameter we calculate the number of days we go back from the 
	// input date, we feed that as an additional parameter into fetchInfoForQuery.
}



#pragma mark -
#pragma mark Related articles 

// Return whether your plugin supports the retrieval of related articles or not.
-(BOOL)supportsRelatedArticles {
	return NO;
}

// Return related articles in the same way you return search results. You will 
// be passed the ID as you set it during the search. NOTE: This method runs in 
// a separate thread. Signal your progress to the delegate. IMPORTANT: You can 
// optionally add one extra parameter per paper which is a "score" 
// (NSNumber between 0.0 and 1.0).
-(void)getRelatedArticlesForID:(NSString*)identifier {
	
}



#pragma mark -
#pragma mark Cited by Articles

// Return whether your plugin supports the retrieval of articles that cite a 
// particular paper or not.
-(BOOL)supportsCitedByArticles {
	return NO;
}

// Return articles that cite a particular paper in the same way you return 
// search results. You will be passed the id as you set it during the search.
// NOTE: This method runs in a separate thread. Signal your progress to the delegate.
-(void)getCitedByArticlesForID:(NSString*)identifier {
	
}



#pragma mark -
#pragma mark Recent Articles

// These methods are used to find recently published articles for authors, 
// journals or keywords. Like with matching (see below) you can optimize for 
// speed by returning a limited set of fields:
// 
// - ID, Title, Name, Year, Volume, Issue, Pages, Authors, Journal, 
//   Publication Date (these are the minimum)
// 
// In addition you can also return two other variables that replace a number of 
// these fields which saves you from parsing complicated strings (this will be 
// done anyway once the match is selected by the user:
// 
// - tempAuthorString  -> return a string of authors (see PubMed example) as a 
//                        whole instead of all authors separately
// - tempJournalString -> return a single string representing the publication 
//                        (e.g. "Nature 2005, vol. 16(2) pp. 400-123")
// 
// If you return the latter you don't have to return the individual journal, 
// volume, year, issue, pages fields, those will be ignored.

// Return recent articles for the provided author. You will be passed a 
// dictionary representation of the author during the search. NOTE: This 
// method runs in a separate thread. Signal your progress to the delegate.
-(void)recentArticlesForAuthor:(NSDictionary*)author {
	
}

// Return recent articles for the provided journal. You will be passed a 
// dictionary representation of the journal during the search. NOTE: This 
// method runs in a separate thread. Signal your progress to the delegate.
-(void)recentArticlesForJournal:(NSDictionary*)journal {
	
}

// Return recent articles for the provided keyword. You will be passed a 
// dictionary representation of the keyword during the search. NOTE: This 
// method runs in a separate thread. Signal your progress to the delegate.
-(void)recentArticlesForKeyword:(NSDictionary*)keyword {
	
}



#pragma mark -
#pragma mark Cleanup methods

// A method to check whether the search finished properly and one to get at any 
// errors that resulted. See above for usage of errorCodes.
-(BOOL)successfulCompletion {
	// we simply check whether we caught an error
	return (searchError == nil);
}

-(NSError*)searchCompletionError {
	return searchError;
}

// Let the plugin get rid of any data that needs to be reset for a new search.
-(void)performCleanup {
	[itemsPerPage release], itemsPerPage = nil;
	[itemOffset release], itemOffset = nil;
	[itemsFound release], itemsFound = nil;
	[itemsToRetrieve release], itemsToRetrieve = nil;
	[retrievedItems release], retrievedItems = nil;
	[statusString release], statusString = nil;
	[searchError release], searchError = nil;
}



#pragma mark -
#pragma mark Metadata lookup methods

// Return the metadata for the paper with the given identifier. You will be 
// passed the ID as you set it during the search. Return a dictionary with the 
// standard format of a papers entry and the single paper entry or nil if 
// impossible to resolve. NOTE: This one is asynchronous and you do not signal 
// progress to the delegate. If you want to run asynchronous use the method 
// below with a single identifier in an array.
-(NSDictionary*)metadataForID:(NSString*)identifier {
	return [NSDictionary new];
}

// Return the metadata for the paper with the given identifier. You will be 
// passed the ID as you set it during the search. Return nil if impossible to 
// resolve. NOTE: This method runs in a separate thread. Signal your progress 
// to the delegate.
-(void)metadataForIDs:(NSArray*)identifiers {
	
}



#pragma mark Follow-up

// Return the URL to the paper within the repository. You will be passed the ID 
// as you set it during the search. Return nil if impossible to resolve.
-(NSURL*)repositoryURLForID:(NSString*)identifier {
	return [NSURL new];
}

// Return the URL to the paper at the publisher's website, preferably fulltext.
// You will be passed the ID as you set it during the search. Return nil if 
// impossible to resolve.
- (NSURL*)publisherURLForID:(NSString*)identifier {
	return [NSURL new];
}

// Return the URL to the PDF of the paper. You will be passed the ID as you set 
// it during the search. Return nil if impossible to resolve. IMPORTANT: If you 
// return nil Papers will do its best to automatically retrieve the PDF on the 
// basis of the publisherURLForID as returned above. ONLY return a link for a 
// PDF here if a) you are sure you know the location 
//          or b) you think you can do some fancy lookup 
//                that outperforms Papers build in attempts.
- (NSURL*)pdfURLForID:(NSString*)identifier {
	return [NSURL new];
}



#pragma mark -
#pragma mark Matching methods

// Return the logo as will be displayed in the search box (this one is smaller 
// than that for the search engine). Take a look at the sample plugins for 
// examples. Suggested size 115w x 40h.
-(NSImage*)small_logo {
	return [[[NSImage alloc] initWithContentsOfFile:
			 [[NSBundle bundleForClass:[self class]] 
			  pathForResource:@"logo_researchr_basic" ofType:@"tif"]] autorelease];
}

// This method is the main worker method and launches the search process for 
// matches. There's no difference with the performSearchWithQuery method above 
// (you could use the same one), except that you can optimize for speed by 
// returning a limited set of fields:
// 
// - ID, Title, Name, Year, Volume, Issue, Pages, Authors, Journal, 
//   Publication Date (these are the minimum)
//
// In addition there a unique situation here that you can also return two other 
// variable that replace a number of these fields which saves you from parsing 
// complicated strings (this will be done anyway once the match is selected by 
// the user:
// 
// - tempAuthorString  -> return a string of authors (see researchr example) as a 
//                        whole instead of all authors separately
// - tempJournalString -> return a single string representing the publication 
//                        (e.g. "Nature 2005, vol. 16(2) pp. 400-123")
// 
// If you return the latter you don't have to return the individual journal, 
// volume, year, issue, pages fields, those will be ignored.
//
// NOTE: This method runs in a separate thread. Signal your progress to the 
// delegate. Use the search protocols delegate methods.
-(void)performMatchWithQuery:(NSArray*)tokens {
	
}

// This method is called when the user has selected the right paper, you will 
// be passed the identifier (as you set it during the initial search, and you 
// have to return the full metadata for the paper (as rich as possible).
// Return the usual dictionary with a papers array containing a SINGLE entry 
// or nil if the identifier cannot be resolved. NOTE: This method runs in a 
// separate thread. Signal your progress to the delegate. Use the above 
// delegate methods.
-(void)performMatchForID:(NSString*)identifier {
	
}



#pragma mark -
#pragma mark Auto Matching methods

// This method is called when the user wishes to auto match a paper. You will 
// be handed all available metadata (including the link to the PDF file if 
// present) in the above described dictionary format. It's your task to return 
// one or more (preferably fewer than 5) possible hits. Return nothing if you
// can't find anything. NOTE: In the current implementation it's likely we 
// ignore the results if you return more than 1 hit. NOTE: This method runs in 
// a separate thread. Signal your progress to the delegate. Use the above 
// delegate methods.
-(void)performAutoMatchForPaper:(NSDictionary*)paper {
	
}

@end