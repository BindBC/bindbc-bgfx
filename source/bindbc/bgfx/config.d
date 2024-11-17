/+
+            Copyright 2023 – 2024 Aya Partridge
+ Distributed under the Boost Software License, Version 1.0.
+     (See accompanying file LICENSE_1_0.txt or copy at
+           http://www.boost.org/LICENSE_1_0.txt)
+/
module bindbc.bgfx.config;

enum staticBinding = (){
	version(BindBC_Static)        return true;
	else version(BindBgfx_Static) return true;
	else return false;
}();

public import bindbc.common.versions: Version;
import bindbc.common.codegen;

mixin(makeFnBindFns(staticBinding, Version(1,0,0)));
