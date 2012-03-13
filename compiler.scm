(%include base: ffi)
(compile-file "src/sdl" cc-options: "-w -I/usr/include/SDL" ld-options: "-lSDL")
