;;;; FILE: 	"sdl-interface.scm"
;;;; IMPLEMENTS: Minimal SDL [Simple DirectMedia Layer] bindings for Gambit
;;;; AUTHOR: 	 Kenneth Dickey  --  Ken[dot]Dickey[at]whidbey[dot]com
;;;; DATE:	 28 December 2007

;; @@FIXME: Use namespace "sdl#"
;;  For now: User interface prefix "SDL::",
;;           Internal implementation prefix "SDL-imp::"
;; @@FIXME: Implement define-foreign-struct [automagic accessors]
;; @@FIXME: Throw Gambit errors

;(compile-options cc-options: "-w -I/usr/include/SDL" ld-options: "-lSDL" force-compile: #t)

;(import (base system-conditional))

;; TODO: pass target directory as argument
;;(%compile-cond
;; ("Linux"
;;  ("-w -I/usr/include/SDL"
;;   "-lSDL"))
;; ("Darwin"
;;  ("-w -I/opt/local/include/SDL"
;;   "osx/sdlosx.o -L/opt/local/lib -lGL -lGLU -lstdc++ -lobjc -ldl -framework GLUT -framework OpenGL -lSDL -framework Cocoa")))


(define pointer) ; FIXME: What? Why?
(define cast-pointer)

(c-declare #<<end-of-c-declare

#include <stdlib.h>
#include "SDL.h"
#include "SDL_keysym.h"
#include "SDL_events.h"

#ifdef __APPLE__
#include "osx-sdl.h"
#endif

int must_lock_surface_P(SDL_Surface *screen)
{
   return( SDL_MUSTLOCK(screen) ) ;
}

/* draw_rect: return 0 => success, -1 =>error */
void draw_rect(SDL_Surface *screen,
              int x,     int y,
              int width, int height,
              int rgb_color )
{
 SDL_Rect rect;

 rect.x = (Sint16)x;
 rect.y = (Sint16)y;
 rect.w = (Uint16)width;
 rect.h = (Uint16)height;

 SDL_FillRect( screen, &rect, rgb_color ) ;
}

/* set_clip_area */
void set_clip_area(SDL_Surface *screen,
                   int x,     int y,
                   int width, int height)
{
 SDL_Rect rect;

 rect.x = (Sint16)x;
 rect.y = (Sint16)y;
 rect.w = (Uint16)width;
 rect.h = (Uint16)height;
 
 SDL_SetClipRect( screen , &rect );
}


int SDL_blit_surface( SDL_Surface *src,
                      int src_x, int src_y, int src_width, int src_height,
                      SDL_Surface *dest,
                      int dest_x, int dest_y, int dest_width, int dest_height )
{
 SDL_Rect src_rect;
 SDL_Rect dest_rect;

 src_rect.x = (Sint16)src_x;
 src_rect.y = (Sint16)src_y;
 src_rect.w = (Uint16)src_width;
 src_rect.h = (Uint16)src_height;
 dest_rect.x = (Sint16)dest_x;
 dest_rect.y = (Sint16)dest_y;
 dest_rect.w = (Uint16)dest_width;
 dest_rect.h = (Uint16)dest_height;

 return( SDL_BlitSurface( src, &src_rect, dest, &dest_rect ) ) ;
}

/* @@@ TEST -- C cruft from here to "end of c declare"  @@@ */

void putpixel(SDL_Surface *screen, int x, int y, int color)
{
    unsigned int *ptr        = (unsigned int*)screen->pixels;
    int           lineoffset = y * (screen->pitch / 4);

    ptr[lineoffset + x] = color;
}


int event_exit_P()
{
 // Poll for events, and handle Quit.
    SDL_Event event;
    while (SDL_PollEvent(&event)) 
    {
     switch (event.type) 
     {
        case SDL_KEYDOWN:
          break;
        case SDL_KEYUP:
          // If escape is pressed, return (and thus, quit)
          //if (event.key.keysym.sym == SDLK_ESCAPE)
             //return(1);
          return event.key.keysym.sym;
          break;
        case SDL_QUIT:
           return(1);
     } /* end switch */
    } /* end while */

    return(0);
}


int event_not_exit_P() /* exit -> 0 else 1 */
{
 // Poll for events, and handle Quit.
    SDL_Event event;
    while (SDL_PollEvent(&event)) 
    {
    printf("EVENT\n");
     switch (event.type) 
     {
        case SDL_KEYDOWN:
          break;
        case SDL_KEYUP:
          // If escape is pressed, return (and thus, quit)
          if (event.key.keysym.sym == SDLK_ESCAPE)
             return(0);
          break;
        case SDL_QUIT:
           return(0);
     } /* end switch */
    } /* end while */

    return(1);
}

end-of-c-declare
)

;==============================================================;
;==============================================================;

;;; Initialize OSX code

;; (%if-sys
;;  "Darwin"
;;  (define SDL::init-osx
;;    (c-lambda ()
;;              void
;;              "sdl_osx_entry_point")))

(define sdl::draw-rect ;; x y width height rgb-color
  (c-lambda ((pointer "SDL_Surface") int int int int int)
   void
  "draw_rect"))
             
;; void set_clip_area(SDL_Surface *screen, int x, int y, int width, int height)
(define sdl::set-clip-area!
  (c-lambda ((pointer "SDL_Surface") int int int int)
            void
            "set_clip_area"))

;; SDL_Surface *SDL_LoadBMP(const char *file);
(define sdl-imp::load-bmp-file
    (c-lambda (char-string) (pointer "SDL_Surface") "SDL_LoadBMP"))

(define (sdl::load-bmp-file file-name-string)
  (let ( [surface (sdl-imp::load-bmp-file file-name-string)] )
    (if (not surface)
       (error "sdl::load-bmp-file: could not load BMP image from file"
              file-name-string)
       (make-will surface (lambda (surface) (sdl::free-surface surface))))
     surface)
)

(define sdl::set-window-icon
  (c-lambda ((pointer "SDL_Surface") (pointer unsigned-int8)) void
            "SDL_WM_SetIcon"))

;; void SDL_FreeSurface(SDL_Surface *surface);
(define sdl::free-surface
  (c-lambda ((pointer "SDL_Surface")) void "SDL_FreeSurface"))


;;void putpixel(SDL_Surface *screen, int x, int y, int color)
(define sdl::put-pixel
  (c-lambda ((pointer "SDL_Surface") int int unsigned-int32)
            void
            "putpixel"))

;; @@FIXME: define-foreign-struct accessors
(define sdl::screen-pitch
  (c-lambda ((pointer "SDL_Surface"))
            int
            "___result = ___arg1->pitch;"))


(define sdl::set-screen-pixel!
  (c-lambda ((pointer "SDL_Surface") unsigned-int32 unsigned-int32)
            void
            "((unsigned int*)((SDL_Surface *)(___arg1->pixels)))[ ___arg2 ] = ___arg3 ;"))

(define sdl::surface-pixels
  (c-lambda ((pointer "SDL_Surface"))
            (pointer unsigned-char)
            "___result_voidstar = ___arg1->pixels;"))

(define sdl::flip
  (c-lambda ((pointer "SDL_Surface")) void "SDL_Flip"))

(define sdl::event-not-exit
  (c-lambda ()
            bool
            "event_not_exit_P"))

(define sdl::event-exit
  (c-lambda ()
            int
            "event_exit_P"))

(define sdl::gl::SwapBuffers
  (c-lambda () void "SDL_GL_SwapBuffers"))

(define sdl::delay
  (c-lambda (unsigned-int32) void "SDL_Delay"))



;;;
;;; SDL symbolic constants
;;; ======================


;; Init constants for SDL subsystems

(define sdl::init-timer       #x00000001)
(define sdl::init-audio       #x00000010)
(define sdl::init-video       #x00000020)
(define sdl::init-cdrom       #x00000100)
(define sdl::init-joystick    #x00000200)
(define sdl::init-noparachute #x00100000)
(define sdl::init-eventthread #x01000000)
(define sdl::init-everything  #x0000FFFF)

;; Surface defines 

(define sdl::swsurface   #x00000000) ; For CreateRGBSurface
(define sdl::hwsurface   #x00000001)
(define sdl::asyncblit   #x00000004)
(define sdl::anyformat   #x10000000) ; For SetVideoMode
(define sdl::hwpalette   #x20000000)
(define sdl::doublebuf   #x40000000)
(define sdl::fullscreen  #x80000000)
(define sdl::opengl      #x00000002)
(define sdl::openglblit  #x0000000A)
(define sdl::resizable   #x00000010)
(define sdl::noframe     #x00000020)
(define sdl::hwaccel     #x00000100) ; Internal (read-only)
(define sdl::srccolorkey #x00001000)
(define sdl::rleaccelok  #x00002000)
(define sdl::rleaccel    #x00004000)
(define sdl::srcalpha    #x00010000)
(define sdl::prealloc    #x01000000)

;; GL attributes (sdl_GLattr)

(define sdl::gl-red-size          0)
(define sdl::gl-green-size        1)
(define sdl::gl-blue-size         2)
(define sdl::gl-alpha-size        3)
(define sdl::gl-buffer-size       4)
(define sdl::gl-doublebuffer      5)
(define sdl::gl-depth-size        6)
(define sdl::gl-stencil-size      7)
(define sdl::gl-accum-red-size    8)
(define sdl::gl-accum-green-size  9)
(define sdl::gl-accum-blue-size  10)
(define sdl::gl-accum-alpha-size 11)

;; sdl event type constants

(define sdl::no-event	        0)
(define sdl::active-event       1)
(define sdl::key-down	        2)
(define sdl::key-up	        3)
(define sdl::mouse-motion       4)
(define sdl::mouse-button-down  5)
(define sdl::mouse-button-up    6)
(define sdl::joy-axis-motion    7)
(define sdl::joy-ball-motion    8)
(define sdl::joy-hat-motion     9)
(define sdl::joy-button-down   10)
(define sdl::joy-button-up     11)
(define sdl::quit              12)
(define sdl::sys-wm-event      13)
(define sdl::event-reserved-a  14)
(define sdl::event-reserved-b  15)
(define sdl::video-resize      16)
(define sdl::video-expose      17)
(define sdl::event-reserved-2  18)
(define sdl::event-reserved-3  19)
(define sdl::event-reserved-4  20)
(define sdl::event-reserved-5  21)
(define sdl::event-reserved-6  22)
(define sdl::event-reserved-7  23)
(define sdl::user-event 	      24)
(define sdl::num-events 	      32)

;; Event actions

(define sdl::add-event   0)
(define sdl::peek-event  1)
(define sdl::get-event   2)

;; Input Grabbing modes

(define sdl::grab-query -1)
(define sdl::grab-off    0)
(define sdl::grab-on     1)

;; Keyboard/Mouse state enum

(define sdl::pressed     1)
(define sdl::released    0)

;; Mouse button enum

(define sdl::button-left   1)
(define sdl::button-middle 2)
(define sdl::button-right  3)

;; Joystick hat enum

(define sdl::hat-centered  0)
(define sdl::hat-up        1)
(define sdl::hat-right     2)
(define sdl::hat-down      4)
(define sdl::hat-left      8)
(define sdl::hat-rightup   (bitwise-ior sdl::hat-right sdl::hat-up))
(define sdl::hat-rightdown (bitwise-ior sdl::hat-right sdl::hat-down))
(define sdl::hat-leftup    (bitwise-ior sdl::hat-left  sdl::hat-up))
(define sdl::hat-leftdown  (bitwise-ior sdl::hat-left  sdl::hat-down))

;; Activate state

(define sdl::app-mouse-focus 1)
(define sdl::app-input-focus 2)
(define sdl::app-active      4)

;; sdl boolean type

(define sdl::false 0)
(define sdl::true  1)

;; Audio

(define sdl::audio-u8 #x0008)
(define sdl::audio-s8 #x8008)
(define sdl::audio-u16lsb #x0010)
(define sdl::audio-s16lsb #x8010)
(define sdl::audio-u16msb #x1010)
(define sdl::audio-s16msb #x9010)
(define sdl::audio-u16 sdl::audio-u16lsb)
(define sdl::audio-s16 sdl::audio-s16lsb)

;; CD

(define sdl::max-tracks    99)

(define sdl::audio-track #x00)
(define sdl::data-track  #x04)

(define sdl::trayempty   0)
(define sdl::stopped     1)
(define sdl::playing     2)
(define sdl::paused      3)
(define sdl::cd-error   -1)

;;;@@FIXME THROW PROPER ERRORs

;char *SDL_GetError(void);
(define sdl::GetError
  (c-lambda () char-string "SDL_GetError"))


(define (sdl::error string)
  (error (string-append string
                        " >SDL> "
                        (sdl::GetError)))
)

;;;
;;; SDL Functions 
;;; =============

;;int SDL_Init(Uint32 flags);
(define sdl::init (c-lambda (unsigned-int32) int "SDL_Init"))

;;void SDL_Quit(void);
(define sdl::exit (c-lambda () void "SDL_Quit"))

(define sdl::enable-unicode
  (c-lambda (bool) int32 "SDL_EnableUNICODE"))

;;; (sdl::within-sdl-lifetime sdl-flags thunk)
(define (sdl::within-sdl-lifetime sdl-flags thunk)
   (if (zero? (sdl::init sdl-flags))
       (begin
         (dynamic-wind
          (lambda () #f)
          thunk
          sdl::exit)
         #t)
       #f)
)

;; SDL_Surface *SDL_CreateRGBSurface(Uint32 flags, int width, int height, int bitsPerPixel, 
;;                                   Uint32 Rmask, Uint32 Gmask, Uint32 Bmask, Uint32 Amask)
(define sdl::create-rgbsurface
  (c-lambda (unsigned-int32 int int int unsigned-int32 unsigned-int32 unsigned-int32 unsigned-int32)
            (pointer "SDL_Surface")
            "SDL_CreateRGBSurface"))

;;SDL_Surface *SDL_SetVideoMode(int width, int height, int bpp, Uint32 flags)
(define sdl::set-video-mode
  (c-lambda (int int int unsigned-int32)
            (pointer "SDL_Surface")
            "SDL_SetVideoMode"))

;;void SDL_UpdateRect(SDL_Surface *screen, Sint32 x, Sint32 y, Sint32 w, Sint32 h);
(define sdl::update-rect
  (c-lambda ((pointer "SDL_Surface") int32 int32 int32 int32) void "SDL_UpdateRect"))


(define sdl::fill-rect
  (c-lambda ((pointer "SDL_Surface") (pointer "SDL_Rect") int32) void "SDL_FillRect"))


;;; SURFACE LOCKING

(define sdl-imp::must-lock-surface?
  (c-lambda ((pointer "SDL_Surface"))
            bool
            "must_lock_surface_P"))

(define sdl-imp::surface-unlocked? (make-parameter #t))


(define (sdl-imp::lock-surface surface)
  ;; Only lock surface once
  (if (sdl-imp::must-lock-surface? surface)
      (let ( (result (sdl-imp::really-lock-surface surface)) )
        (if result
            (sdl::error "Could not lock SDL surface"))))
)


(define sdl-imp::really-lock-surface
  (c-lambda ((pointer "SDL_Surface"))
            bool
            "SDL_LockSurface"))


(define (sdl-imp::unlock-surface surface)
  ;; Only lock surface once
  (if (sdl-imp::must-lock-surface? surface)
      (let ( (result (sdl-imp::really-unlock-surface surface)) )
        (if result
            (sdl::error "Could not lock SDL surface"))))
)


(define sdl-imp::really-unlock-surface
  (c-lambda ((pointer "SDL_Surface"))
            void
            "SDL_UnlockSurface"))


;;; (sdl::with-locked-surface surface proc)
(define (sdl::with-locked-surface surface proc)
  ;; Only lock surface once in outer call
  ;; Any number if nested calls are no-ops
  ;; Unlock on the way out
  (if (sdl-imp::surface-unlocked?)
      (dynamic-wind
          (lambda ()
            (sdl-imp::lock-surface surface)
            (sdl-imp::surface-unlocked? #f))
          proc
          (lambda ()
            (sdl-imp::unlock-surface surface)
            (sdl-imp::surface-unlocked? #t)))
      (proc)) ;; already locked
)

;; int SDL_BlitSurface(SDL_Surface *src, SDL_Rect *srcrect, SDL_Surface *dst, SDL_Rect *dstrect);

(define sdl::BLIT-surface
  (c-lambda ( (pointer "SDL_Surface") int32 int32 int32 int32   ;; source
              (pointer "SDL_Surface") int32 int32 int32 int32 ) ;; dest
            int32
            "SDL_blit_surface"))


;;; WINDOW CAPTION

;; void SDL_WM_SetCaption(const char *title, const char *icon_name);
(define sdl::set-window-caption
  (c-lambda (char-string char-string) void "SDL_WM_SetCaption"))


;;; TICKS

;; Uint32 SDL_GetTicks(void);
(define sdl::get-ticks
  (c-lambda () unsigned-int32 "SDL_GetTicks"))


;;;  EVENTS

;; int SDL_PollEvent(SDL_Event *event); 0 => none; 1 => event
(define sdl::poll-event
  (c-lambda ((pointer "SDL_Event")) bool "SDL_PollEvent"))


#|
(define (sdl::malloc-event-struct)
  (sdl::malloc "sdl::malloc-event-struct" (pointer "SDL_Event") "sizeof(SDL_Event)")
)
|#

(define sdl::raw-event-type
  (c-lambda ((pointer "SDL_Event")) unsigned-int8 "___result = ___arg1->type;"))

;; @@FIXME: move to macro include file..
;; @@FIXME: gen from C header file
(define-macro (sdl::make-field-ref args scheme-type field-name)
  `(c-lambda
    ,args
    ,scheme-type
    ,(string-append
      "___result = ___arg1->"
      field-name
      ";")
    )
)


;;FILE "SDL_events.h"
; /* Keyboard event structure */
; typedef struct SDL_KeyboardEvent {
; 	Uint8 type;	/* SDL_KEYDOWN or SDL_KEYUP */
; 	Uint8 which;	/* The keyboard device index */
; 	Uint8 state;	/* SDL_PRESSED or SDL_RELEASED */
; 	SDL_keysym keysym;
; } SDL_KeyboardEvent;

(define sdl::key-state
  (sdl::make-field-ref ((pointer "SDL_Event")) unsigned-int8  "key.state"))

;;FILE "SDL_keyboard.h"
; typedef struct SDL_keysym {
; 	Uint8 scancode;			/* hardware specific scancode */
; 	SDLKey sym;			/* SDL virtual keysym */
; 	SDLMod mod;			/* current key modifiers */
; 	Uint16 unicode;			/* translated character */
; } SDL_keysym;

;; "SDH_keysym.h"
; typedef enum {
; 	/* The keyboard syms have been cleverly chosen to map to ASCII */
; 	SDLK_UNKNOWN		= 0,
; 	SDLK_FIRST		= 0,
; 	SDLK_BACKSPACE		= 8,
; 	SDLK_TAB		= 9,
; 	SDLK_CLEAR		= 12,
; 	SDLK_RETURN		= 13,
; 	SDLK_PAUSE		= 19,
; 	SDLK_ESCAPE		= 27,
; 	SDLK_SPACE		= 32,
; 	SDLK_EXCLAIM		= 33,
; 	SDLK_QUOTEDBL		= 34,
; 	SDLK_HASH		= 35,
; 	SDLK_DOLLAR		= 36,
; 	SDLK_AMPERSAND		= 38,
; 	SDLK_QUOTE		= 39,
; 	SDLK_LEFTPAREN		= 40,
; 	SDLK_RIGHTPAREN		= 41,
; 	SDLK_ASTERISK		= 42,
; 	SDLK_PLUS		= 43,
; 	SDLK_COMMA		= 44,
; 	SDLK_MINUS		= 45,
; 	SDLK_PERIOD		= 46,
; 	SDLK_SLASH		= 47,
; 	SDLK_0			= 48,
; 	SDLK_1			= 49,
; 	SDLK_2			= 50,
; 	SDLK_3			= 51,
; 	SDLK_4			= 52,
; 	SDLK_5			= 53,
; 	SDLK_6			= 54,
; 	SDLK_7			= 55,
; 	SDLK_8			= 56,
; 	SDLK_9			= 57,
; 	SDLK_COLON		= 58,
; 	SDLK_SEMICOLON		= 59,
; 	SDLK_LESS		= 60,
; 	SDLK_EQUALS		= 61,
; 	SDLK_GREATER		= 62,
; 	SDLK_QUESTION		= 63,
; 	SDLK_AT			= 64,
; 	/* 
; 	   Skip uppercase letters
; 	 */
; 	SDLK_LEFTBRACKET	= 91,
; 	SDLK_BACKSLASH		= 92,
; 	SDLK_RIGHTBRACKET	= 93,
; 	SDLK_CARET		= 94,
; 	SDLK_UNDERSCORE		= 95,
; 	SDLK_BACKQUOTE		= 96,
; 	SDLK_a			= 97,
; 	SDLK_b			= 98,
; 	SDLK_c			= 99,
; 	SDLK_d			= 100,
; 	SDLK_e			= 101,
; 	SDLK_f			= 102,
; 	SDLK_g			= 103,
; 	SDLK_h			= 104,
; 	SDLK_i			= 105,
; 	SDLK_j			= 106,
; 	SDLK_k			= 107,
; 	SDLK_l			= 108,
; 	SDLK_m			= 109,
; 	SDLK_n			= 110,
; 	SDLK_o			= 111,
; 	SDLK_p			= 112,
; 	SDLK_q			= 113,
; 	SDLK_r			= 114,
; 	SDLK_s			= 115,
; 	SDLK_t			= 116,
; 	SDLK_u			= 117,
; 	SDLK_v			= 118,
; 	SDLK_w			= 119,
; 	SDLK_x			= 120,
; 	SDLK_y			= 121,
; 	SDLK_z			= 122,
; 	SDLK_DELETE		= 127,
; 	/* End of ASCII mapped keysyms */

; 	/* International keyboard syms */
; 	SDLK_WORLD_0		= 160,		/* 0xA0 */
; 	SDLK_WORLD_1		= 161,
; 	SDLK_WORLD_2		= 162,
; 	SDLK_WORLD_3		= 163,
; 	SDLK_WORLD_4		= 164,
; 	SDLK_WORLD_5		= 165,
; 	SDLK_WORLD_6		= 166,
; 	SDLK_WORLD_7		= 167,
; 	SDLK_WORLD_8		= 168,
; 	SDLK_WORLD_9		= 169,
; 	SDLK_WORLD_10		= 170,
; 	SDLK_WORLD_11		= 171,
; 	SDLK_WORLD_12		= 172,
; 	SDLK_WORLD_13		= 173,
; 	SDLK_WORLD_14		= 174,
; 	SDLK_WORLD_15		= 175,
; 	SDLK_WORLD_16		= 176,
; 	SDLK_WORLD_17		= 177,
; 	SDLK_WORLD_18		= 178,
; 	SDLK_WORLD_19		= 179,
; 	SDLK_WORLD_20		= 180,
; 	SDLK_WORLD_21		= 181,
; 	SDLK_WORLD_22		= 182,
; 	SDLK_WORLD_23		= 183,
; 	SDLK_WORLD_24		= 184,
; 	SDLK_WORLD_25		= 185,
; 	SDLK_WORLD_26		= 186,
; 	SDLK_WORLD_27		= 187,
; 	SDLK_WORLD_28		= 188,
; 	SDLK_WORLD_29		= 189,
; 	SDLK_WORLD_30		= 190,
; 	SDLK_WORLD_31		= 191,
; 	SDLK_WORLD_32		= 192,
; 	SDLK_WORLD_33		= 193,
; 	SDLK_WORLD_34		= 194,
; 	SDLK_WORLD_35		= 195,
; 	SDLK_WORLD_36		= 196,
; 	SDLK_WORLD_37		= 197,
; 	SDLK_WORLD_38		= 198,
; 	SDLK_WORLD_39		= 199,
; 	SDLK_WORLD_40		= 200,
; 	SDLK_WORLD_41		= 201,
; 	SDLK_WORLD_42		= 202,
; 	SDLK_WORLD_43		= 203,
; 	SDLK_WORLD_44		= 204,
; 	SDLK_WORLD_45		= 205,
; 	SDLK_WORLD_46		= 206,
; 	SDLK_WORLD_47		= 207,
; 	SDLK_WORLD_48		= 208,
; 	SDLK_WORLD_49		= 209,
; 	SDLK_WORLD_50		= 210,
; 	SDLK_WORLD_51		= 211,
; 	SDLK_WORLD_52		= 212,
; 	SDLK_WORLD_53		= 213,
; 	SDLK_WORLD_54		= 214,
; 	SDLK_WORLD_55		= 215,
; 	SDLK_WORLD_56		= 216,
; 	SDLK_WORLD_57		= 217,
; 	SDLK_WORLD_58		= 218,
; 	SDLK_WORLD_59		= 219,
; 	SDLK_WORLD_60		= 220,
; 	SDLK_WORLD_61		= 221,
; 	SDLK_WORLD_62		= 222,
; 	SDLK_WORLD_63		= 223,
; 	SDLK_WORLD_64		= 224,
; 	SDLK_WORLD_65		= 225,
; 	SDLK_WORLD_66		= 226,
; 	SDLK_WORLD_67		= 227,
; 	SDLK_WORLD_68		= 228,
; 	SDLK_WORLD_69		= 229,
; 	SDLK_WORLD_70		= 230,
; 	SDLK_WORLD_71		= 231,
; 	SDLK_WORLD_72		= 232,
; 	SDLK_WORLD_73		= 233,
; 	SDLK_WORLD_74		= 234,
; 	SDLK_WORLD_75		= 235,
; 	SDLK_WORLD_76		= 236,
; 	SDLK_WORLD_77		= 237,
; 	SDLK_WORLD_78		= 238,
; 	SDLK_WORLD_79		= 239,
; 	SDLK_WORLD_80		= 240,
; 	SDLK_WORLD_81		= 241,
; 	SDLK_WORLD_82		= 242,
; 	SDLK_WORLD_83		= 243,
; 	SDLK_WORLD_84		= 244,
; 	SDLK_WORLD_85		= 245,
; 	SDLK_WORLD_86		= 246,
; 	SDLK_WORLD_87		= 247,
; 	SDLK_WORLD_88		= 248,
; 	SDLK_WORLD_89		= 249,
; 	SDLK_WORLD_90		= 250,
; 	SDLK_WORLD_91		= 251,
; 	SDLK_WORLD_92		= 252,
; 	SDLK_WORLD_93		= 253,
; 	SDLK_WORLD_94		= 254,
; 	SDLK_WORLD_95		= 255,		/* 0xFF */

; 	/* Numeric keypad */
; 	SDLK_KP0		= 256,
; 	SDLK_KP1		= 257,
; 	SDLK_KP2		= 258,
; 	SDLK_KP3		= 259,
; 	SDLK_KP4		= 260,
; 	SDLK_KP5		= 261,
; 	SDLK_KP6		= 262,
; 	SDLK_KP7		= 263,
; 	SDLK_KP8		= 264,
; 	SDLK_KP9		= 265,
; 	SDLK_KP_PERIOD		= 266,
; 	SDLK_KP_DIVIDE		= 267,
; 	SDLK_KP_MULTIPLY	= 268,
; 	SDLK_KP_MINUS		= 269,
; 	SDLK_KP_PLUS		= 270,
; 	SDLK_KP_ENTER		= 271,
; 	SDLK_KP_EQUALS		= 272,

; 	/* Arrows + Home/End pad */
; 	SDLK_UP			= 273,
; 	SDLK_DOWN		= 274,
; 	SDLK_RIGHT		= 275,
; 	SDLK_LEFT		= 276,
; 	SDLK_INSERT		= 277,
; 	SDLK_HOME		= 278,
; 	SDLK_END		= 279,
; 	SDLK_PAGEUP		= 280,
; 	SDLK_PAGEDOWN		= 281,

; 	/* Function keys */
; 	SDLK_F1			= 282,
; 	SDLK_F2			= 283,
; 	SDLK_F3			= 284,
; 	SDLK_F4			= 285,
; 	SDLK_F5			= 286,
; 	SDLK_F6			= 287,
; 	SDLK_F7			= 288,
; 	SDLK_F8			= 289,
; 	SDLK_F9			= 290,
; 	SDLK_F10		= 291,
; 	SDLK_F11		= 292,
; 	SDLK_F12		= 293,
; 	SDLK_F13		= 294,
; 	SDLK_F14		= 295,
; 	SDLK_F15		= 296,

; 	/* Key state modifier keys */
; 	SDLK_NUMLOCK		= 300,
; 	SDLK_CAPSLOCK		= 301,
; 	SDLK_SCROLLOCK		= 302,
; 	SDLK_RSHIFT		= 303,
; 	SDLK_LSHIFT		= 304,
; 	SDLK_RCTRL		= 305,
; 	SDLK_LCTRL		= 306,
; 	SDLK_RALT		= 307,
; 	SDLK_LALT		= 308,
; 	SDLK_RMETA		= 309,
; 	SDLK_LMETA		= 310,
; 	SDLK_LSUPER		= 311,		/* Left "Windows" key */
; 	SDLK_RSUPER		= 312,		/* Right "Windows" key */
; 	SDLK_MODE		= 313,		/* "Alt Gr" key */
; 	SDLK_COMPOSE		= 314,		/* Multi-key compose key */

; 	/* Miscellaneous function keys */
; 	SDLK_HELP		= 315,
; 	SDLK_PRINT		= 316,
; 	SDLK_SYSREQ		= 317,
; 	SDLK_BREAK		= 318,
; 	SDLK_MENU		= 319,
; 	SDLK_POWER		= 320,		/* Power Macintosh power key */
; 	SDLK_EURO		= 321,		/* Some european keyboards */
; 	SDLK_UNDO		= 322,		/* Atari keyboard has Undo */

; 	/* Add any other keys here */

; 	SDLK_LAST
; } SDLKey;

(define (sdl::key-enum evt-struct)
  (sdl-imp::key-enum->symbol
   (sdl-imp::key-enum evt-struct)))

(define sdl-imp::key-enum
  (sdl::make-field-ref ((pointer "SDL_Event")) unsigned-int16 "key.keysym.sym"))

(define sdl::key-code sdl-imp::key-enum)

(define sdl-imp::key-enum->symbol
  (let* ( [xform (make-vector 325 'key-unknown)]
          [xform-len (vector-length xform)]
        )
     (vector-set! xform 8	 'key-backspace)
     (vector-set! xform 9	 'key-tab)
     (vector-set! xform 12	 'key-clear)
     (vector-set! xform 13	 'key-return)
     (vector-set! xform 19	 'key-pause)
     (vector-set! xform 27	 'key-escape)
     (vector-set! xform 32	 'key-space)
     (vector-set! xform 33	 'key-exclaim)
     (vector-set! xform 34	 'key-quotedbl)
     (vector-set! xform 35	 'key-hash)
     (vector-set! xform 36	 'key-dollar)
     (vector-set! xform 38	 'key-ampersand)
     (vector-set! xform 39	 'key-quote)
     (vector-set! xform 40	 'key-left-paren)
     (vector-set! xform 41	 'key-right-paren)
     (vector-set! xform 42	 'key-asterisk)
     (vector-set! xform 43	 'key-plus)
     (vector-set! xform 44	 'key-comma)
     (vector-set! xform 45	 'key-minus)
     (vector-set! xform 46	 'key-period)
     (vector-set! xform 47	 'key-slash)
     (vector-set! xform 48	 'key-0)
     (vector-set! xform 49	 'key-1)
     (vector-set! xform 50	 'key-2)
     (vector-set! xform 51	 'key-3)
     (vector-set! xform 52	 'key-4)
     (vector-set! xform 53	 'key-5)
     (vector-set! xform 54	 'key-6)
     (vector-set! xform 55	 'key-7)
     (vector-set! xform 56	 'key-8)
     (vector-set! xform 57	 'key-9)
     (vector-set! xform 58	 'key-colon)
     (vector-set! xform 59	 'key-semicolon)
     (vector-set! xform 60	 'key-less)
     (vector-set! xform 61	 'key-equals)
     (vector-set! xform 62	 'key-greater)
     (vector-set! xform 63	 'key-question)
     (vector-set! xform 64	 'key-at)
     ;;   skip uppercase letters
     (vector-set! xform 91	 'key-leftbracket)
     (vector-set! xform 92	 'key-backslash)
     (vector-set! xform 93	 'key-rightbracket)
     (vector-set! xform 94	 'key-caret)
     (vector-set! xform 95	 'key-underscore)
     (vector-set! xform 96	 'key-backquote)
     (vector-set! xform 97	 'key-a)
     (vector-set! xform 98	 'key-b)
     (vector-set! xform 99	 'key-c)
     (vector-set! xform 100	 'key-d)
     (vector-set! xform 101	 'key-e)
     (vector-set! xform 102	 'key-f)
     (vector-set! xform 103	 'key-g)
     (vector-set! xform 104	 'key-h)
     (vector-set! xform 105	 'key-i)
     (vector-set! xform 106	 'key-j)
     (vector-set! xform 107	 'key-k)
     (vector-set! xform 108	 'key-l)
     (vector-set! xform 109	 'key-m)
     (vector-set! xform 110	 'key-n)
     (vector-set! xform 111	 'key-o)
     (vector-set! xform 112	 'key-p)
     (vector-set! xform 113	 'key-q)
     (vector-set! xform 114	 'key-r)
     (vector-set! xform 115	 'key-s)
     (vector-set! xform 116	 'key-t)
     (vector-set! xform 117	 'key-u)
     (vector-set! xform 118	 'key-v)
     (vector-set! xform 119	 'key-w)
     (vector-set! xform 120	 'key-x)
     (vector-set! xform 121	 'key-y)
     (vector-set! xform 122	 'key-z)
     (vector-set! xform 127	 'key-delete)
     ;;/* end of ascii mapped keysyms */

     ;;/* international keyboard syms */
     (vector-set! xform 160	 'key-world-0) ; #xA0
     (vector-set! xform 161	 'key-world-1)
     (vector-set! xform 162	 'key-world-2)
     (vector-set! xform 163	 'key-world-3)
     (vector-set! xform 164	 'key-world-4)
     (vector-set! xform 165	 'key-world-5)
     (vector-set! xform 166	 'key-world-6)
     (vector-set! xform 167	 'key-world-7)
     (vector-set! xform 168	 'key-world-8)
     (vector-set! xform 169	 'key-world-9)
     (vector-set! xform 170	 'key-world-10)
     (vector-set! xform 171	 'key-world-11)
     (vector-set! xform 172	 'key-world-12)
     (vector-set! xform 173	 'key-world-13)
     (vector-set! xform 174	 'key-world-14)
     (vector-set! xform 175	 'key-world-15)
     (vector-set! xform 176	 'key-world-16)
     (vector-set! xform 177	 'key-world-17)
     (vector-set! xform 178	 'key-world-18)
     (vector-set! xform 179	 'key-world-19)
     (vector-set! xform 180	 'key-world-20)
     (vector-set! xform 181	 'key-world-21)
     (vector-set! xform 182	 'key-world-22)
     (vector-set! xform 183	 'key-world-23)
     (vector-set! xform 184	 'key-world-24)
     (vector-set! xform 185	 'key-world-25)
     (vector-set! xform 186	 'key-world-26)
     (vector-set! xform 187	 'key-world-27)
     (vector-set! xform 188	 'key-world-28)
     (vector-set! xform 189	 'key-world-29)
     (vector-set! xform 190	 'key-world-30)
     (vector-set! xform 191	 'key-world-31)
     (vector-set! xform 192	 'key-world-32)
     (vector-set! xform 193	 'key-world-33)
     (vector-set! xform 194	 'key-world-34)
     (vector-set! xform 195	 'key-world-35)
     (vector-set! xform 196	 'key-world-36)
     (vector-set! xform 197	 'key-world-37)
     (vector-set! xform 198	 'key-world-38)
     (vector-set! xform 199	 'key-world-39)
     (vector-set! xform 200	 'key-world-40)
     (vector-set! xform 201	 'key-world-41)
     (vector-set! xform 202	 'key-world-42)
     (vector-set! xform 203	 'key-world-43)
     (vector-set! xform 204	 'key-world-44)
     (vector-set! xform 205	 'key-world-45)
     (vector-set! xform 206	 'key-world-46)
     (vector-set! xform 207	 'key-world-47)
     (vector-set! xform 208	 'key-world-48)
     (vector-set! xform 209	 'key-world-49)
     (vector-set! xform 210	 'key-world-50)
     (vector-set! xform 211	 'key-world-51)
     (vector-set! xform 212	 'key-world-52)
     (vector-set! xform 213	 'key-world-53)
     (vector-set! xform 214	 'key-world-54)
     (vector-set! xform 215	 'key-world-55)
     (vector-set! xform 216	 'key-world-56)
     (vector-set! xform 217	 'key-world-57)
     (vector-set! xform 218	 'key-world-58)
     (vector-set! xform 219	 'key-world-59)
     (vector-set! xform 220	 'key-world-60)
     (vector-set! xform 221	 'key-world-61)
     (vector-set! xform 222	 'key-world-62)
     (vector-set! xform 223	 'key-world-63)
     (vector-set! xform 224	 'key-world-64)
     (vector-set! xform 225	 'key-world-65)
     (vector-set! xform 226	 'key-world-66)
     (vector-set! xform 227	 'key-world-67)
     (vector-set! xform 228	 'key-world-68)
     (vector-set! xform 229	 'key-world-69)
     (vector-set! xform 230	 'key-world-70)
     (vector-set! xform 231	 'key-world-71)
     (vector-set! xform 232	 'key-world-72)
     (vector-set! xform 233	 'key-world-73)
     (vector-set! xform 234	 'key-world-74)
     (vector-set! xform 235	 'key-world-75)
     (vector-set! xform 236	 'key-world-76)
     (vector-set! xform 237	 'key-world-77)
     (vector-set! xform 238	 'key-world-78)
     (vector-set! xform 239	 'key-world-79)
     (vector-set! xform 240	 'key-world-80)
     (vector-set! xform 241	 'key-world-81)
     (vector-set! xform 242	 'key-world-82)
     (vector-set! xform 243	 'key-world-83)
     (vector-set! xform 244	 'key-world-84)
     (vector-set! xform 245	 'key-world-85)
     (vector-set! xform 246	 'key-world-86)
     (vector-set! xform 247	 'key-world-87)
     (vector-set! xform 248	 'key-world-88)
     (vector-set! xform 249	 'key-world-89)
     (vector-set! xform 250	 'key-world-90)
     (vector-set! xform 251	 'key-world-91)
     (vector-set! xform 252	 'key-world-92)
     (vector-set! xform 253	 'key-world-93)
     (vector-set! xform 254	 'key-world-94)
     (vector-set! xform 255	 'key-world-95) ; #xFF

     ;;/* numeric keypad */
     (vector-set! xform 256	 'key-kp0)
     (vector-set! xform 257	 'key-kp1)
     (vector-set! xform 258	 'key-kp2)
     (vector-set! xform 259	 'key-kp3)
     (vector-set! xform 260	 'key-kp4)
     (vector-set! xform 261	 'key-kp5)
     (vector-set! xform 262	 'key-kp6)
     (vector-set! xform 263	 'key-kp7)
     (vector-set! xform 264	 'key-kp8)
     (vector-set! xform 265	 'key-kp9)
     (vector-set! xform 266	 'key-kp-period)
     (vector-set! xform 267	 'key-kp-divide)
     (vector-set! xform 268	 'key-kp-multiply)
     (vector-set! xform 269	 'key-kp-minus)
     (vector-set! xform 270	 'key-kp-plus)
     (vector-set! xform 271	 'key-kp-enter)
     (vector-set! xform 272	 'key-kp-equals)

     ;;/* arrows + home/end pad */
     (vector-set! xform 273	 'key-up-arrow)
     (vector-set! xform 274	 'key-down-arrow)
     (vector-set! xform 275	 'key-right-arrow)
     (vector-set! xform 276	 'key-left-arrow)
     (vector-set! xform 277	 'key-insert)
     (vector-set! xform 278	 'key-home)
     (vector-set! xform 279	 'key-end)
     (vector-set! xform 280	 'key-page-up)
     (vector-set! xform 281	 'key-page-down)
     
     ;;/* function keys */
     (vector-set! xform 282	 'key-f1)
     (vector-set! xform 283	 'key-f2)
     (vector-set! xform 284	 'key-f3)
     (vector-set! xform 285	 'key-f4)
     (vector-set! xform 286	 'key-f5)
     (vector-set! xform 287	 'key-f6)
     (vector-set! xform 288	 'key-f7)
     (vector-set! xform 289	 'key-f8)
     (vector-set! xform 290	 'key-f9)
     (vector-set! xform 291	 'key-f10)
     (vector-set! xform 292	 'key-f11)
     (vector-set! xform 293	 'key-f12)
     (vector-set! xform 294	 'key-f13)
     (vector-set! xform 295	 'key-f14)
     (vector-set! xform 296	 'key-f15)

     ;;/* key state modifier keys */
     (vector-set! xform 300	 'key-num-lock)
     (vector-set! xform 301	 'key-caps-lock)
     (vector-set! xform 302	 'key-scroll-lock)
     (vector-set! xform 303	 'key-right-shift)
     (vector-set! xform 304	 'key-left-shift)
     (vector-set! xform 305	 'key-right-control)
     (vector-set! xform 306	 'key-left-control)
     (vector-set! xform 307	 'key-right-alt)
     (vector-set! xform 308	 'key-left-alt)
     (vector-set! xform 309	 'key-right-meta)
     (vector-set! xform 310	 'key-left-meta)
     (vector-set! xform 311	 'key-left-super)   ; left  "windows"
     (vector-set! xform 312	 'key-right-super)  ; right "windows"
     (vector-set! xform 313	 'key-mode)	; "alt gr
     (vector-set! xform 314	 'key-compose)	; multi-key compose

     ;;/* miscellaneous function keys */
     (vector-set! xform 315	 'key-help)
     (vector-set! xform 316	 'key-print-screen)
     (vector-set! xform 317	 'key-system-request)
     (vector-set! xform 318	 'key-break)
     (vector-set! xform 319	 'key-menu)
     (vector-set! xform 320	 'key-power)	; power macintosh power key 
     (vector-set! xform 321	 'key-euro)	; some european keyboards 
     (vector-set! xform 322	 'key-undo)	; atari keyboard has undo 

     (lambda (key-enum)
       (if (<= 0 key-enum xform-len)
           (vector-ref xform key-enum)
           (string->symbol
            (string-append "key-unknown-"
                           (number->string key-enum)))
     ) )
) )

(define sdl::key-code->symbol sdl-imp::key-enum->symbol)

; /* Enumeration of valid key mods (possibly OR'd together) */
; typedef enum {
; 	KMOD_NONE  = 0x0000,
; 	KMOD_LSHIFT= 0x0001,
; 	KMOD_RSHIFT= 0x0002,
; 	KMOD_LCTRL = 0x0040,
; 	KMOD_RCTRL = 0x0080,
; 	KMOD_LALT  = 0x0100,
; 	KMOD_RALT  = 0x0200,
; 	KMOD_LMETA = 0x0400,
; 	KMOD_RMETA = 0x0800,
; 	KMOD_NUM   = 0x1000,
; 	KMOD_CAPS  = 0x2000,
; 	KMOD_MODE  = 0x4000,
; 	KMOD_RESERVED = 0x8000
; } SDLMod;
(define sdl::keymod-none           #x0000)
(define sdl::keymod-left-shift     #x0001)
(define sdl::keymod-right-shift    #x0002)
(define sdl::keymod-left-control   #x0040)
(define sdl::keymod-right-control  #x0080)
(define sdl::keymod-left-alt       #x0100)
(define sdl::keymod-right-alt      #x0200)
(define sdl::keymod-left-meta      #x0400)
(define sdl::keymod-right-meta     #x0800)
(define sdl::keymod-num            #x1000)
(define sdl::keymod-caps           #x2000)
(define sdl::keymod-mode           #x4000)

(define sdl-imp::key-modifiers
  (sdl::make-field-ref ((pointer "SDL_Event")) unsigned-int16 "key.keysym.mod"))

(define (sdl::key-modifiers evt-struct)
  (sdl-imp::key-modifiers->symbol-list
   (sdl-imp::key-modifiers evt-struct))
)

(define sdl-imp::key-modifiers->symbol-list
  (let ( [bits-and-names
          (list
           (cons sdl::keymod-left-shift    'keymod-left-shift   )
           (cons sdl::keymod-right-shift   'keymod-right-shift  )
           (cons sdl::keymod-left-control  'keymod-left-control )
           (cons sdl::keymod-right-control 'keymod-right-control)
           (cons sdl::keymod-left-alt      'keymod-left-alt  )
           (cons sdl::keymod-right-alt     'keymod-right-alt )
           (cons sdl::keymod-left-meta     'keymod-left-meta )
           (cons sdl::keymod-right-meta    'keymod-right-meta)
           (cons sdl::keymod-num           'keymod-num )
           (cons sdl::keymod-caps          'keymod-caps)
           (cons sdl::keymod-mode          'keymod-mode))
          ]
         [bit  car]
         [name cdr]
       )
    (lambda (keymods)
      (let ( [bit-set?
              (lambda (bit)
                (not (zero? (bitwise-and bit keymods))))]
           )
        (let loop ( [data bits-and-names] [modifiers '()] )
          (cond
           ((null? data) modifiers) ; done
           ((bit-set? (bit (car data)))
            (loop (cdr data) (cons (name (car data)) modifiers)))
           (else
            (loop (cdr data) modifiers))))))
) )

(define sdl::key-unicode
  (sdl::make-field-ref ((pointer "SDL_Event")) unsigned-int16 "key.keysym.unicode"))

; /* Mouse motion event structure */
; typedef struct SDL_MouseMotionEvent {
; 	Uint8 type;	/* SDL_MOUSEMOTION */
; 	Uint8 which;	/* The mouse device index */
; 	Uint8 state;	/* The current button state */
; 	Uint16 x, y;	/* The X/Y coordinates of the mouse */
; 	Sint16 xrel;	/* The relative motion in the X direction */
; 	Sint16 yrel;	/* The relative motion in the Y direction */
; } SDL_MouseMotionEvent;

(define sdl::move-state
  (sdl::make-field-ref ((pointer "SDL_Event")) unsigned-int8  "motion.state"))
(define sdl::move-x
  (sdl::make-field-ref ((pointer "SDL_Event")) unsigned-int16 "motion.x"))
(define sdl::move-y
  (sdl::make-field-ref ((pointer "SDL_Event")) unsigned-int16 "motion.y"))
(define sdl::move-rel-x
  (sdl::make-field-ref ((pointer "SDL_Event")) int16          "motion.xrel"))
(define sdl::move-rel-y
  (sdl::make-field-ref ((pointer "SDL_Event")) int16          "motion.yrel"))

; /* Mouse button event structure */
; typedef struct SDL_MouseButtonEvent {
; 	Uint8 type;	/* SDL_MOUSEBUTTONDOWN or SDL_MOUSEBUTTONUP */
; 	Uint8 which;	/* The mouse device index */
; 	Uint8 button;	/* The mouse button index */
; 	Uint8 state;	/* SDL_PRESSED or SDL_RELEASED */
; 	Uint16 x, y;	/* The X/Y coordinates of the mouse at press time */
; } SDL_MouseButtonEvent;

(define sdl::mouse-state
  (sdl::make-field-ref ((pointer "SDL_Event")) unsigned-int8  "button.state"))
(define sdl::mouse-x
  (sdl::make-field-ref ((pointer "SDL_Event")) unsigned-int16 "button.x"))
(define sdl::mouse-y
  (sdl::make-field-ref ((pointer "SDL_Event")) unsigned-int16 "button.y"))
(define sdl-imp::mouse-button
  (sdl::make-field-ref ((pointer "SDL_Event")) unsigned-int8  "button.button"))
(define (sdl::mouse-button evt-struct)
  (let ( [value (sdl-imp::mouse-button evt-struct)] )
    (case value
      ((1) 'left)
      ((2) 'middle)
      ((3) 'right)
      ((4) 'wheel-up)
      ((5) 'wheel-down)
      (else value) ;; unknown
      )
) )

; typedef struct SDL_ActiveEvent {
; 	Uint8 type;	/* SDL_ACTIVEEVENT */
; 	Uint8 gain;	/* Whether given states were gained or lost (1/0) */
; 	Uint8 state;	/* A mask of the focus states */
; } SDL_ActiveEvent;


(define sdl::active-gain?
  (sdl::make-field-ref ((pointer "SDL_Event")) bool  "active.gain")
)
(define sdl::active-state
  (sdl::make-field-ref ((pointer "SDL_Event")) int8  "active.state")
)

(define sdl::resize-w
  (sdl::make-field-ref ((pointer "SDL_Event")) int "resize.w"))

(define sdl::resize-h
  (sdl::make-field-ref ((pointer "SDL_Event")) int "resize.h"))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SDL Mixer interface
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; (define sdl::Mix::AUDIO_S16SYS
;;   ((c-lambda () unsigned-int16 "___result = AUDIO_S16SYS;")))

;; (define sdl::Mix::open-audio
;;   (c-lambda (int unsigned-int16 int int) int "Mix_OpenAudio"))

;; (define sdl::Mix::load-wav
;;   (c-lambda (char-string) (pointer "Mix_Chunk") "Mix_LoadWAV"))

;; (define sdl::Mix::free-chunk
;;   (c-lambda ((pointer "Mix_Chunk")) void "Mix_FreeChunk"))

;; (define sdl::Mix::play-channel
;;   (c-lambda (int (pointer "Mix_Chunk") int) int "Mix_PlayChannel"))

;; (define sdl::Mix::pause
;;   (c-lambda (int) void "Mix_Pause"))

;; (define sdl::Mix::resume
;;   (c-lambda (int) void "Mix_Resume"))

;; (define sdl::Mix::halt-channel
;;   (c-lambda (int) int "Mix_HaltChannel"))

;; (define sdl::MIX::load-mus
;;   (c-lambda (char-string) (pointer "Mix_Chunk") "Mix_LoadMUS"))


;;;   ---   E O F   ---   ;;;
