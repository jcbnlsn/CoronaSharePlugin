//
//  PluginShare.mm
//
//  Created by Jacob Nielsen 2015
//

#import "ShareLibrary.h"
#include "CoronaRuntime.h"

#import <UIKit/UIKit.h>
#import "InstagramActivity.h"

// ----------------------------------------------------------------------------

class ShareLibrary
{
	public:
		typedef ShareLibrary Self;

	public:
		static const char kName[];
		static const char kEvent[];

	protected:
		ShareLibrary();

	public:
		bool Initialize( CoronaLuaRef listener );

	public:
		CoronaLuaRef GetListener() const { return fListener; }

	public:
		static int Open( lua_State *L );

	protected:
		static int Finalizer( lua_State *L );

	public:
		static Self *ToLibrary( lua_State *L );

	public:
		static int init( lua_State *L );
		static int popUp( lua_State *L );

	private:
		CoronaLuaRef fListener;
};

// ----------------------------------------------------------------------------

// This corresponds to the name of the library, e.g. [Lua] require "plugin.library"
const char ShareLibrary::kName[] = "plugin.share";

// This corresponds to the event name, e.g. [Lua] event.name
const char ShareLibrary::kEvent[] = "pluginshareevent";

ShareLibrary::ShareLibrary()
:	fListener( NULL )
{
}

bool
ShareLibrary::Initialize( CoronaLuaRef listener )
{
	// Can only initialize listener once
	bool result = ( NULL == fListener );

	if ( result )
	{
		fListener = listener;
	}

	return result;
}

int
ShareLibrary::Open( lua_State *L )
{
	// Register __gc callback
	const char kMetatableName[] = __FILE__; // Globally unique string to prevent collision
	CoronaLuaInitializeGCMetatable( L, kMetatableName, Finalizer );

	// Functions in library
	const luaL_Reg kVTable[] =
	{
		{ "init", init },
		{ "popUp", popUp },

		{ NULL, NULL }
	};

	// Set library as upvalue for each library function
	Self *library = new Self;
	CoronaLuaPushUserdata( L, library, kMetatableName );

	luaL_openlib( L, kName, kVTable, 1 ); // leave "library" on top of stack

	return 1;
}

int
ShareLibrary::Finalizer( lua_State *L )
{
	Self *library = (Self *)CoronaLuaToUserdata( L, 1 );

	CoronaLuaDeleteRef( L, library->GetListener() );

	delete library;

	return 0;
}

ShareLibrary *
ShareLibrary::ToLibrary( lua_State *L )
{
	// library is pushed as part of the closure
	Self *library = (Self *)CoronaLuaToUserdata( L, lua_upvalueindex( 1 ) );
	return library;
}

// [Lua] library.init( listener )
int
ShareLibrary::init( lua_State *L )
{
	int listenerIndex = 1;

	if ( CoronaLuaIsListener( L, listenerIndex, kEvent ) )
	{
		Self *library = ToLibrary( L );

		CoronaLuaRef listener = CoronaLuaNewRef( L, listenerIndex );
		library->Initialize( listener );
	}

	return 0;
}

// [Lua] library.popUp()
int
ShareLibrary::popUp( lua_State *L )
{
    // Sharing parameters
    const char *message = NULL;
    const char *imageName = NULL;
    const char *url = NULL;
    //const char *subject = NULL;
    double originX = 0.0;
    double originY = 0.0;
    
    // Parameter table passed to plugin
    if ( lua_type( L, -1 ) == LUA_TTABLE )
	{
		lua_getfield( L, -1, "imageName" );
        if ( lua_type( L, -1 ) == LUA_TSTRING )
        {
            imageName = lua_tostring( L, -1 );
        }
        lua_pop( L, 1 );
        
        lua_getfield( L, -1, "message" );
        if ( lua_type( L, -1 ) == LUA_TSTRING )
        {
            message = lua_tostring( L, -1 );
        }
        lua_pop( L, 1 );
        
        lua_getfield( L, -1, "url" );
        if ( lua_type( L, -1 ) == LUA_TSTRING )
        {
            url = lua_tostring( L, -1 );
        }
        lua_pop( L, 1 );
        
        lua_getfield( L, -1, "origin" );
        if ( lua_type( L, -1 ) == LUA_TTABLE )
        {
            lua_getfield( L, -1, "x" );
            if ( lua_type( L, -1 ) == LUA_TNUMBER  )
            {
                originX = lua_tonumber( L, -1 );
            }
            lua_pop( L, 1 );
            
            lua_getfield( L, -1, "y" );
            if ( lua_type( L, -1 ) == LUA_TNUMBER  )
            {
                originY = lua_tonumber( L, -1 );
            }
            lua_pop( L, 1 );
            
        }
        lua_pop( L, 1 );
    }
    lua_pop( L, 1 );
    
    // Share it
    id<CoronaRuntime> runtime = (id<CoronaRuntime>)CoronaLuaGetContext( L );
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *imagePath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithUTF8String:imageName]];
    
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    NSString *textToShare = [NSString stringWithUTF8String:message]; //@"";
    NSString *urlString = [NSString stringWithUTF8String:url];
    NSURL *urlToShare = [NSURL URLWithString:urlString];
    
    InstagramActivity *instagramActivity = [[InstagramActivity alloc] init];
    instagramActivity.imageToShare = image;
    instagramActivity.messageToShare = textToShare;
    instagramActivity.viewController = runtime.appViewController;
    instagramActivity.originX = originX;
    instagramActivity.originY = originY;
    
    NSArray *activityItems = @[image, textToShare, urlToShare];
    NSArray *applicationActivities = @[instagramActivity];
    NSArray *excludeActivities = @[
                                    UIActivityTypePostToWeibo,
                                    UIActivityTypePostToVimeo, UIActivityTypePostToTencentWeibo,
                                    UIActivityTypeAssignToContact, UIActivityTypeAddToReadingList,
                                    //UIActivityTypePrint, UIActivityTypeCopyToPasteboard,
                                    //UIActivityTypePostToTwitter, UIActivityTypePostToFacebook,
                                    //UIActivityTypeMessage, UIActivityTypeMail,
                                    //UIActivityTypeSaveToCameraRoll, UIActivityTypePostToFlickr
                                    ];
    
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:applicationActivities];
    //[activityController setValue:@"Some email subject" forKey:@"subject"];
    activityController.excludedActivityTypes = excludeActivities;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:activityController];
        CGRect rect = CGRectMake(originX, originY, 1, 1);
        [popover presentPopoverFromRect:rect inView:runtime.appViewController.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        [runtime.appViewController presentModalViewController:activityController animated:YES];
    }
   
	return 0;
}

// ----------------------------------------------------------------------------

CORONA_EXPORT int luaopen_plugin_share( lua_State *L )
{
	return ShareLibrary::Open( L );
}
