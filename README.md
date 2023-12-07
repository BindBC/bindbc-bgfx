<div align="center" width="100%">
	<img alt="BindBC-bgfx logo" width="50%" src="https://raw.githubusercontent.com/BindBC/bindbc-branding/master/logo_wide_bgfx.png"/>
</div>

# BindBC-bgfx
This project provides a set of both static and dynamic D bindings to [bgfx](https://github.com/bkaradzic/bgfx). They are compatible with `@nogc` and `nothrow`, and can be compiled with BetterC compatibility. This package is based on and supersedes the old [bgfx C99 API bindings by @GoaLitiuM](https://github.com/GoaLitiuM/bindbc-bgfx).

| Table of Contents |
|-------------------|
|[License](#license)|
|[bgfx documentation](#bgfx-documentation)|
|[Quickstart guide](#quickstart-guide)|
|[Binding-specific changes](#binding-specific-changes)|
|[Configurations](#configurations)|
|[Generating bindings](#generating-bindings)|

## License

BindBC-bgfx&mdash;as well as every other binding in the [BindBC project](https://github.com/BindBC)&mdash;is licensed under the [Boost Software License](https://www.boost.org/LICENSE_1_0.txt).

Bear in mind that you still need to abide by [bgfx's license](https://github.com/bkaradzic/bgfx/blob/master/LICENSE) if you use it through these bindings.

## bgfx documentation
This readme describes how to use BindBC-bgfx, *not* bgfx itself. BindBC-bgfx does have some minor API changes from bgfx, which are listed in [Binding-specific changes](#binding-specific-changes). Otherwise BindBC-bgfx is a direct D binding to the bgfx C++ API, so any existing bgfx documentation and tutorials can be adapted with only minor modifications.
* bgfx's official [build instructions](https://bkaradzic.github.io/bgfx/build.html).
* bgfx's official [API Reference](https://bkaradzic.github.io/bgfx/bgfx.html).
* A [short guide](https://dev.to/pperon/hello-bgfx-4dka) to help new users get started using bgfx.

Additionally, because these bindings are auto-generated, bgfx's documentation is also embedded within this library's [source code](https://github.com/BindBC/bindbc-bgfx/blob/master/source/bgfx/package.d).

## Quickstart guide
To use BindBC-bgfx in your dub project, add it to the list of `dependencies` in your dub configuration file. The easiest way is by running `dub add bindbc-bgfx` in your project folder. The result should look like this:

Example __dub.json__
```json
"dependencies": {
	"bindbc-bgfx": "~>1.0.0",
},
```
Example __dub.sdl__
```sdl
dependency "bindbc-bgfx" version="~>1.0.0"
```

By default, BindBC-bgfx is configured to compile as a dynamic binding that is not BetterC-compatible. If you prefer static bindings or need BetterC compatibility, they can be enabled via `subConfigurations` in your dub configuration file. For configuration naming & more details, see [Configurations](#configurations).

Example __dub.json__
```json
"subConfigurations": {
	"bindbc-bgfx": "staticBC",
},
```
Example __dub.sdl__
```sdl
subConfiguration "bindbc-bgfx" "staticBC"
```

If using static bindings, then you will need to add the filename your bgfx library to `libs`.

Example __dub.json__
```json
"libs": [
	"bgfx-shared-libDebug",
],
```
Example __dub.sdl__
```sdl
libs "bgfx-shared-libDebug"
```

**If you're using static bindings**: `import bindbc.bgfx` in your code, and then you can use all of bgfx. That's it!
```d
import bindbc.bgfx;

void main(){
	auto init = bgfx.Init(0);
	
	init.resolution.width = 800;
	init.resolution.height = 600;
	
	bgfx.init(init);
	
	//etc.
	
	bgfx.shutdown();
}
```

**If you're using dynamic bindings**: you need to load bgfx with `loadBgfx()`. 

For most use cases, it's best to use BindBC-Loader's [error handling API](https://github.com/BindBC/bindbc-loader#error-handling) to see if there were any errors while loading the libraries. This information can be written to a log file before aborting the program.

The load function will also return a member of the `LoadMsg` enum, which can be used for debugging:

* `noLibrary` means the library couldn't be found.
* `badLibrary` means there was an error while loading the library.
* `success` means that bgfx was loaded without any errors.

Here's a simple example using only the load function's return value:

```d
import bindbc.bgfx;
import bindbc.loader;

/*
This code attempts to load the bgfx shared library using
well-known variations of the library name for the host system.
*/
LoadMsg ret = loadBgfx();
if(ret != LoadMsg.success){
	/*
	Error handling. For most use cases, it's best to use the error handling API in
	BindBC-Loader to retrieve error messages for logging and then abort.
	If necessary, it's possible to determine the root cause via the return value:
	*/
	if(ret == LoadMsg.noLibrary){
		//The bgfx shared library failed to load
	}else if(ret == LoadMsg.badLibrary){
		/*
		One or more symbols failed to load. The likely cause is
		that the shared library is for a lower API version than
		`bgfx.apiVersion` in bindbc-bgfx.
		*/
	}
}

/*
This code attempts to load the bgfx library using a user-supplied file name.
Usually, the name and/or path used will be platform specific, as in this
example which attempts to load `bgfx.dll` from the `libs` subdirectory,
relative to the executable, only on Windows.
*/
version(Windows) loadBgfx("libs/bgfx.dll");
```

[The error handling API](https://github.com/BindBC/bindbc-loader#error-handling) in BindBC-Loader can be used to log error messages:
```d
import bindbc.bgfx;

/*
Import the sharedlib module for error handling. Assigning an alias ensures that the
function names do not conflict with other public APIs. This isn't strictly necessary,
but the API names are common enough that they could appear in other packages.
*/
import loader = bindbc.loader.sharedlib;

bool loadLib(){
	LoadMsg ret = loadBgfx();
	if(ret != LoadMsg.success){
		//Log the error info
		foreach(info; loader.errors){
			/*
			A hypothetical logging function. Note that `info.error` and
			`info.message` are `const(char)*`, not `string`.
			*/
			logError(info.error, info.message);
		}
		
		//Optionally construct a user-friendly error message for the user
		string msg;
		if(ret == LoadMsg.noLibrary){
			msg = "This application requires the bgfx library.";
		}
		//A hypothetical message box function
		showMessageBox(msg);
		return false;
	}
	return true;
}
```

## Binding-specific changes

### Default constructors

D completely disallows default constructors. Because of this, any default constructors from bgfx take a single `int` as their first parameter. This `int` parameter is always discarded, so you may supply any number, but a `0` is recommended for consistency:
```d
auto init = Init(0);
```
Failing to call the default constructor of a bgfx struct that has one may lead to unintended consequences, and is therefore not recommended:
```d
//The constructor will not be called in either of these cases:
Init init1;
auto init2 = Init(); //no `int` parameter!
```

### Enums
bgfx enums in these bindings are reformatted like so:
```d
void bgfxFn(bgfx_renderer_type_t type); //bgfx_some_type_name_t
//becomes:
void bgfxFn(RendererType type); //SomeTypeName

bgfxFn(BGFX_RENDERER_TYPE_OPENGLES); //BGFX_SOME_TYPE_NAME_SOME_MEMBER
//becomes:
bgfxFn(RendererType.openGLES); //SomeTypeName.someMember
```
This reformatting follows [the D Style](https://dlang.org/dstyle.html#naming_enum_members).

## Configurations
BindBC-bgfx has the following configurations:

|     ┌      |  DRuntime  |   BetterC   |
|-------------|------------|-------------|
| **Dynamic** | `dynamic`  | `dynamicBC` |
| **Static**  | `static`   | `staticBC`  |

For projects that don't use dub, if BindBC-bgfx is compiled for static bindings then the version identifier `BindBgfx_Static` must be passed to your compiler/linker when building your project.

> [!NOTE]\
> The version identifier `BindBC_Static` can be used to configure all of the _official_ BindBC packages used in your program. (i.e. those maintained in [the BindBC GitHub organisation](https://github.com/BindBC)) Some third-party BindBC packages may support it as well.

### Dynamic bindings
The dynamic bindings have no link-time dependency on the bgfx libraries, so the bgfx shared libraries must be manually loaded at runtime from the shared library search path of the user's system.
For bgfx, this is typically handled by distributing the bgfx shared library with your program.

The function `isBgfxLoaded` returns `true` if any version of the shared library has been loaded and `false` if not. `unloadBgfx` can be used to unload a successfully loaded shared library.

### Static bindings
Static _bindings_ do not require static _linking_. The static bindings have a link-time dependency on either the shared _or_ static bgfx libraries. On Windows, you can link with the static libraries or, to use the DLLs, the import libraries. On other systems, you can link with either the static libraries or directly with the shared libraries.

When linking with the shared (or import) libraries, there is a runtime dependency on the shared library just as there is when using the dynamic bindings. The difference is that the shared libraries are no longer loaded manually&mdash;loading is handled automatically by the system when the program is launched. Attempting to call `loadBgfx` with the static bindings enabled will result in a compilation error.

When linking with the static libraries, there is no runtime dependency on bgfx. If you decide to use the static bgfx libraries you will also need to ensure that you link with all of bgfx's link-time dependencies (such as bx, bimg, stdc++, and system API libraries).

## Generating bindings

The main bgfx repository already contains the latest generated binding definitions for D, so these files can be copied from `bgfx/bindings/d/` over the files in `bindbc-bgfx/source/bgfx/` when pairing these bindings with custom versions of bgfx. If you need to regenerate the bindings, you can run `genie idl` in the bgfx project folder, and copy the regenerated files to `bindbc-bgfx/source/bgfx/`.
