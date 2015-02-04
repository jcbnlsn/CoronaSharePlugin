//
//  ShareLibrary.h
//
//  Created by Jacob Nielsen 2015
//

#ifndef _PluginShare_H__
#define _PluginShare_H__

#include "CoronaLua.h"
#include "CoronaMacros.h"

// This corresponds to the name of the library, e.g. [Lua] require "plugin.library"
// where the '.' is replaced with '_'
CORONA_EXPORT int luaopen_plugin_share( lua_State *L );

#endif // _PluginShare_H__
