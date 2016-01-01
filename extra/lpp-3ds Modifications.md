This modification is based on [this commit](https://github.com/Rinnegatamante/lpp-3ds/tree/a34b5bfcdf8a119b1aff94dfb273f423f659e933).

* `lua_listCia` now returns `id` as `title_id` to the script. This returns a value such as 1125899907130624 (Cubic Ninja US).
* `lua_download` and `lua_downstring` will call `httpcCloseContext(&context);` before throwing an error if an error occurs.