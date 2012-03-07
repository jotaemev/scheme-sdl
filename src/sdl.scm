gg;; Copyright (c) 2012, Alvaro Castro-Castilla.
;; Inspired by Kenneth Dickey's SDL bindings

;-------------------------------------------------------------------------------
; Includes
;-------------------------------------------------------------------------------

(c-declare #<<end-of-c-declare
#include <stdlib.h>
#include "SDL.h"
#include "SDL_keysym.h"
#include "SDL_events.h"
#include "SDL_keyboard.h"

#ifdef __APPLE__
#include "osx-sdl.h"
#endif
end-of-c-declare
)

;-------------------------------------------------------------------------------
; Constants
;-------------------------------------------------------------------------------

;;; Init constants for SDL subsystems

(define sdl::init-timer       #x00000001)
(define sdl::init-audio       #x00000010)
(define sdl::init-video       #x00000020)
(define sdl::init-cdrom       #x00000100)
(define sdl::init-joystick    #x00000200)
(define sdl::init-noparachute #x00100000)
(define sdl::init-eventthread #x01000000)
(define sdl::init-everything  #x0000FFFF)

;;; Surface defines 

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

;;; GL attributes (sdl_GLattr)

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

;;; sdl event type constants

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

;;; Input Grabbing modes

(define sdl::grab-query -1)
(define sdl::grab-off    0)
(define sdl::grab-on     1)

;;; Keyboard/Mouse state enum

(define sdl::pressed     1)
(define sdl::released    0)

;;; Mouse button enum

(define sdl::button-left   1)
(define sdl::button-middle 2)
(define sdl::button-right  3)

;;; Joystick hat enum

(define sdl::hat-centered  0)
(define sdl::hat-up        1)
(define sdl::hat-right     2)
(define sdl::hat-down      4)
(define sdl::hat-left      8)
(define sdl::hat-rightup   (bitwise-ior sdl::hat-right sdl::hat-up))
(define sdl::hat-rightdown (bitwise-ior sdl::hat-right sdl::hat-down))
(define sdl::hat-leftup    (bitwise-ior sdl::hat-left  sdl::hat-up))
(define sdl::hat-leftdown  (bitwise-ior sdl::hat-left  sdl::hat-down))

;;; Activate state

(define sdl::app-mouse-focus 1)
(define sdl::app-input-focus 2)
(define sdl::app-active      4)

;;; sdl boolean type

(define sdl::false 0)
(define sdl::true  1)

;;; Audio

(define sdl::audio-u8 #x0008)
(define sdl::audio-s8 #x8008)
(define sdl::audio-u16lsb #x0010)
(define sdl::audio-s16lsb #x8010)
(define sdl::audio-u16msb #x1010)
(define sdl::audio-s16msb #x9010)
(define sdl::audio-u16 sdl::audio-u16lsb)
(define sdl::audio-s16 sdl::audio-s16lsb)

;;; CD

(define sdl::max-tracks    99)
(define sdl::audio-track #x00)
(define sdl::data-track  #x04)
(define sdl::trayempty   0)
(define sdl::stopped     1)
(define sdl::playing     2)
(define sdl::paused      3)
(define sdl::cd-error   -1)

;;; Key modifiers

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

;-------------------------------------------------------------------------------
; Types
;-------------------------------------------------------------------------------

(c-define-type sdl::event "SDL_Event")
(c-define-type sdl::event* (pointer sdl::event))
(c-define-type sdl::keyboard-event "SDL_KeyboardEvent")
(c-define-type sdl::keyboard-event* (pointer sdl::keyboard-event))
(c-define-type sdl::keysym "SDL_keysym")
(c-define-type sdl::keysym* (pointer sdl::keysym))

;-------------------------------------------------------------------------------
; Functions
;-------------------------------------------------------------------------------

(define sdl::fill-rect
  (c-lambda ((pointer "SDL_Surface") (pointer "SDL_Rect") int32) void
            "SDL_FillRect"))
(define sdl::set-window-icon
  (c-lambda ((pointer "SDL_Surface") (pointer unsigned-int8)) void
            "SDL_WM_SetIcon"))
(define sdl::set-window-caption
  (c-lambda (char-string char-string) void
            "SDL_WM_SetCaption"))
(define sdl::free-surface
  (c-lambda ((pointer "SDL_Surface")) void
            "SDL_FreeSurface"))
(define sdl::create-rgbsurface
  (c-lambda (unsigned-int32 int int int unsigned-int32 unsigned-int32 unsigned-int32 unsigned-int32)
            (pointer "SDL_Surface")
            "SDL_CreateRGBSurface"))
(define sdl::set-video-mode
  (c-lambda (int int int unsigned-int32) (pointer "SDL_Surface")
            "SDL_SetVideoMode"))
(define sdl::update-rect
  (c-lambda ((pointer "SDL_Surface") int32 int32 int32 int32) void
            "SDL_UpdateRect"))
(define sdl::flip
  (c-lambda ((pointer "SDL_Surface")) void
            "SDL_Flip"))
(define sdl::gl-swap-buffers
  (c-lambda () void
            "SDL_GL_SwapBuffers"))
(define sdl::delay
  (c-lambda (unsigned-int32) void
            "SDL_Delay"))
(define sdl::get-error
  (c-lambda () char-string
            "SDL_GetError"))
(define sdl::init
  (c-lambda (unsigned-int32) int
            "SDL_Init"))
(define sdl::exit
  (c-lambda () void
            "SDL_Quit"))
(define sdl::enable-unicode
  (c-lambda (bool) int32
            "SDL_EnableUNICODE"))
(define sdl::get-ticks
  (c-lambda () unsigned-int32
            "SDL_GetTicks"))
(define sdl::lock-surface
  (c-lambda ((pointer "SDL_Surface")) bool
            "SDL_LockSurface"))
(define sdl::unlock-surface
  (c-lambda ((pointer "SDL_Surface")) void
            "SDL_UnlockSurface"))
(define sdl::show-cursor
  (c-lambda (int)
            int
            "SDL_ShowCursor"))
(define sdl::pump-events
  (c-lambda ()
            void
            "SDL_PumpEvents"))
(define sdl::event-state
  (c-lambda (unsigned-int8 int)
            void
            "SDL_EventState"))








;;; TODO!!! IMPORT
(define-macro (make-field-ref c-type scheme-type field-name)
  `(c-lambda
    (,c-type)
    ,scheme-type
    ,(string-append "___result = ___arg1->" field-name ";")))

;-------------------------------------------------------------------------------
; Raw events
;-------------------------------------------------------------------------------

;;; Globals for handling events with Scheme environment

(c-declare "
SDL_Event _g_event;
___U16 _g_pressed_keys[325];
int _g_pressed_buttons[5];
")

;;; Check if there is a new event, while saving it in a global variable and other
;;; global state variables

(define sdl::events-next?
  (c-lambda ()
            bool
            "
___BOOL r = SDL_PollEvent(&_g_event);
switch( _g_event.type ){
  case SDL_KEYDOWN:
    _g_pressed_keys[_g_event.key.keysym.sym] = true;
  break;
  case SDL_KEYUP:
    _g_pressed_keys[_g_event.key.keysym.sym] = false;
  break;
  case SDL_MOUSEBUTTONDOWN:
    _g_pressed_buttons[_g_event.button.button] = true;
  break;
  case SDL_MOUSEBUTTONUP:
    _g_pressed_buttons[_g_event.button.button] = false;
  break;
  default:
  break;
}
___result = r;
"))

;;; Get the currently available event

(define sdl::events-get
  (c-lambda ()
            sdl::event
            "___result_voidstar = &_g_event;"))

;;; Wait and get envent

;;; Return error and event
;; (define sdl::wait-event
;;     (c-lambda ()
;;               sdl::event
;;               "
;; SDL_WaitEvent(&_g_event);
;; ___result_voidstar = &_g_event;
;; "))

;;; TODO: Wait event with timeout

;;; Get the event type

(define sdl::event-type
  (make-field-ref sdl::event* unsigned-int16 "type"))

(define sdl::event-active-gain?
  (make-field-ref sdl::event* bool "active.gain"))

(define sdl::event-active-state
  (make-field-ref sdl::event* int8 "active.state"))

(define sdl::event-resize-w
  (make-field-ref sdl::event* int "resize.w"))

(define sdl::event-resize-h
  (make-field-ref sdl::event* int "resize.h"))

;-------------------------------------------------------------------------------
; Mouse events
;-------------------------------------------------------------------------------

;;; Check whether a mouse button is pressed

(define sdl::mouse-pressed?
  (lambda (button)
    (let recur ()
      (if (sdl::events-next?)
          (recur)))
    ((c-lambda (int)
               bool
               "___result = _g_pressed_buttons[___arg1];") button)))

(define sdl::event-move-state
  (make-field-ref sdl::event* unsigned-int8  "motion.state"))

(define sdl::event-move-x
  (make-field-ref sdl::event* unsigned-int16 "motion.x"))

(define sdl::event-move-y
  (make-field-ref sdl::event* unsigned-int16 "motion.y"))

(define sdl::event-move-rel-x
  (make-field-ref sdl::event* int16 "motion.xrel"))

(define sdl::event-move-rel-y
  (make-field-ref sdl::event* int16 "motion.yrel"))

(define sdl::event-mouse-state
  (make-field-ref sdl::event* unsigned-int8 "button.state"))

(define sdl::event-mouse-x
  (make-field-ref sdl::event* unsigned-int16 "button.x"))

(define sdl::event-mouse-y
  (make-field-ref sdl::event* unsigned-int16 "button.y"))

(define sdl::mouse-button
  (make-field-ref sdl::event* unsigned-int8 "button.button"))

(define (sdl::event-mouse-button event)
  (let ((value (sdl::mouse-button event)))
    (case value
      ((1) 'left)
      ((2) 'middle)
      ((3) 'right)
      ((4) 'wheel-up)
      ((5) 'wheel-down)
      ;; unknown
      (else value))))

;;; Globals for handling events with Scheme environment

(c-declare "
int _g_mouse_x;
int _g_mouse_y;
")

(define (sdl::get-mouse-state)
  ((c-lambda () void "SDL_GetMouseState(&_g_mouse_x, &_g_mouse_y);"))
  (values
   ((c-lambda () int "___result = _g_mouse_x;"))
   ((c-lambda () int "___result = _g_mouse_y;"))))

;-------------------------------------------------------------------------------
; Key events
;-------------------------------------------------------------------------------

;;; Check whether the given key-coded key is pressed
;;; ___arg1 (int) : key code
;;; TODO: Should be done with SDL_GetKeyState(NULL)

(define sdl::key-pressed?
  (lambda (key)
    (let recur ()
      (if (sdl::events-next?)
          (recur)))
    ((c-lambda (int)
               bool
               "___result = _g_pressed_keys[___arg1];") key)))
#;
(define sdl::key-pressed?
  (c-lambda (int)
            bool
            "
Uint8 *state = SDL_GetKeyState(NULL);
___result = state[___arg1];
"))
;;; Event fields and subfields

(define sdl::event-key
  (make-field-ref sdl::event* sdl::keyboard-event "key"))

(define sdl::event-key-state
  (make-field-ref sdl::event* unsigned-int8 "key.state"))

(define sdl::event-key-keysym
  (make-field-ref sdl::event* sdl::keysym "key.keysym"))

(define sdl::event-key-keysym-sym
  (make-field-ref sdl::event* unsigned-int16 "key.keysym.sym"))

(define sdl::event-key-keysym-modifiers
  (make-field-ref sdl::event* unsigned-int16 "key.keysym.mod"))

(define sdl::event-key-keysym-unicode
  (make-field-ref sdl::event* unsigned-int16 "key.keysym.unicode"))

;;; Key fields

(define sdl::key-state
  (make-field-ref sdl::keyboard-event* unsigned-int8 "state"))

(define sdl::key-keysym
  (make-field-ref sdl::keyboard-event* sdl::keysym "keysym"))

;;; Keysyms

(define sdl::keysym-sym->symbol
  (let* ((keysyms (make-vector 325 'key-unknown))
         (keysyms-len (vector-length keysyms)))
    (vector-set! keysyms 8	 'key-backspace)
    (vector-set! keysyms 9	 'key-tab)
    (vector-set! keysyms 12	 'key-clear)
    (vector-set! keysyms 13	 'key-return)
    (vector-set! keysyms 19	 'key-pause)
    (vector-set! keysyms 27	 'key-escape)
    (vector-set! keysyms 32	 'key-space)
    (vector-set! keysyms 33	 'key-exclaim)
    (vector-set! keysyms 34	 'key-quotedbl)
    (vector-set! keysyms 35	 'key-hash)
    (vector-set! keysyms 36	 'key-dollar)
    (vector-set! keysyms 38	 'key-ampersand)
    (vector-set! keysyms 39	 'key-quote)
    (vector-set! keysyms 40	 'key-left-paren)
    (vector-set! keysyms 41	 'key-right-paren)
    (vector-set! keysyms 42	 'key-asterisk)
    (vector-set! keysyms 43	 'key-plus)
    (vector-set! keysyms 44	 'key-comma)
    (vector-set! keysyms 45	 'key-minus)
    (vector-set! keysyms 46	 'key-period)
    (vector-set! keysyms 47	 'key-slash)
    (vector-set! keysyms 48	 'key-0)
    (vector-set! keysyms 49	 'key-1)
    (vector-set! keysyms 50	 'key-2)
    (vector-set! keysyms 51	 'key-3)
    (vector-set! keysyms 52	 'key-4)
    (vector-set! keysyms 53	 'key-5)
    (vector-set! keysyms 54	 'key-6)
    (vector-set! keysyms 55	 'key-7)
    (vector-set! keysyms 56	 'key-8)
    (vector-set! keysyms 57	 'key-9)
    (vector-set! keysyms 58	 'key-colon)
    (vector-set! keysyms 59	 'key-semicolon)
    (vector-set! keysyms 60	 'key-less)
    (vector-set! keysyms 61	 'key-equals)
    (vector-set! keysyms 62	 'key-greater)
    (vector-set! keysyms 63	 'key-question)
    (vector-set! keysyms 64	 'key-at)
    ;;   skip uppercase letters
    (vector-set! keysyms 91	 'key-leftbracket)
    (vector-set! keysyms 92	 'key-backslash)
    (vector-set! keysyms 93	 'key-rightbracket)
    (vector-set! keysyms 94	 'key-caret)
    (vector-set! keysyms 95	 'key-underscore)
    (vector-set! keysyms 96	 'key-backquote)
    (vector-set! keysyms 97	 'key-a)
    (vector-set! keysyms 98	 'key-b)
    (vector-set! keysyms 99	 'key-c)
    (vector-set! keysyms 100	 'key-d)
    (vector-set! keysyms 101	 'key-e)
    (vector-set! keysyms 102	 'key-f)
    (vector-set! keysyms 103	 'key-g)
    (vector-set! keysyms 104	 'key-h)
    (vector-set! keysyms 105	 'key-i)
    (vector-set! keysyms 106	 'key-j)
    (vector-set! keysyms 107	 'key-k)
    (vector-set! keysyms 108	 'key-l)
    (vector-set! keysyms 109	 'key-m)
    (vector-set! keysyms 110	 'key-n)
    (vector-set! keysyms 111	 'key-o)
    (vector-set! keysyms 112	 'key-p)
    (vector-set! keysyms 113	 'key-q)
    (vector-set! keysyms 114	 'key-r)
    (vector-set! keysyms 115	 'key-s)
    (vector-set! keysyms 116	 'key-t)
    (vector-set! keysyms 117	 'key-u)
    (vector-set! keysyms 118	 'key-v)
    (vector-set! keysyms 119	 'key-w)
    (vector-set! keysyms 120	 'key-x)
    (vector-set! keysyms 121	 'key-y)
    (vector-set! keysyms 122	 'key-z)
    (vector-set! keysyms 127	 'key-delete)
    ;;/* end of ascii mapped keysyms */

    ;;/* international keyboard syms */
    (vector-set! keysyms 160	 'key-world-0) ; #xA0
    (vector-set! keysyms 161	 'key-world-1)
    (vector-set! keysyms 162	 'key-world-2)
    (vector-set! keysyms 163	 'key-world-3)
    (vector-set! keysyms 164	 'key-world-4)
    (vector-set! keysyms 165	 'key-world-5)
    (vector-set! keysyms 166	 'key-world-6)
    (vector-set! keysyms 167	 'key-world-7)
    (vector-set! keysyms 168	 'key-world-8)
    (vector-set! keysyms 169	 'key-world-9)
    (vector-set! keysyms 170	 'key-world-10)
    (vector-set! keysyms 171	 'key-world-11)
    (vector-set! keysyms 172	 'key-world-12)
    (vector-set! keysyms 173	 'key-world-13)
    (vector-set! keysyms 174	 'key-world-14)
    (vector-set! keysyms 175	 'key-world-15)
    (vector-set! keysyms 176	 'key-world-16)
    (vector-set! keysyms 177	 'key-world-17)
    (vector-set! keysyms 178	 'key-world-18)
    (vector-set! keysyms 179	 'key-world-19)
    (vector-set! keysyms 180	 'key-world-20)
    (vector-set! keysyms 181	 'key-world-21)
    (vector-set! keysyms 182	 'key-world-22)
    (vector-set! keysyms 183	 'key-world-23)
    (vector-set! keysyms 184	 'key-world-24)
    (vector-set! keysyms 185	 'key-world-25)
    (vector-set! keysyms 186	 'key-world-26)
    (vector-set! keysyms 187	 'key-world-27)
    (vector-set! keysyms 188	 'key-world-28)
    (vector-set! keysyms 189	 'key-world-29)
    (vector-set! keysyms 190	 'key-world-30)
    (vector-set! keysyms 191	 'key-world-31)
    (vector-set! keysyms 192	 'key-world-32)
    (vector-set! keysyms 193	 'key-world-33)
    (vector-set! keysyms 194	 'key-world-34)
    (vector-set! keysyms 195	 'key-world-35)
    (vector-set! keysyms 196	 'key-world-36)
    (vector-set! keysyms 197	 'key-world-37)
    (vector-set! keysyms 198	 'key-world-38)
    (vector-set! keysyms 199	 'key-world-39)
    (vector-set! keysyms 200	 'key-world-40)
    (vector-set! keysyms 201	 'key-world-41)
    (vector-set! keysyms 202	 'key-world-42)
    (vector-set! keysyms 203	 'key-world-43)
    (vector-set! keysyms 204	 'key-world-44)
    (vector-set! keysyms 205	 'key-world-45)
    (vector-set! keysyms 206	 'key-world-46)
    (vector-set! keysyms 207	 'key-world-47)
    (vector-set! keysyms 208	 'key-world-48)
    (vector-set! keysyms 209	 'key-world-49)
    (vector-set! keysyms 210	 'key-world-50)
    (vector-set! keysyms 211	 'key-world-51)
    (vector-set! keysyms 212	 'key-world-52)
    (vector-set! keysyms 213	 'key-world-53)
    (vector-set! keysyms 214	 'key-world-54)
    (vector-set! keysyms 215	 'key-world-55)
    (vector-set! keysyms 216	 'key-world-56)
    (vector-set! keysyms 217	 'key-world-57)
    (vector-set! keysyms 218	 'key-world-58)
    (vector-set! keysyms 219	 'key-world-59)
    (vector-set! keysyms 220	 'key-world-60)
    (vector-set! keysyms 221	 'key-world-61)
    (vector-set! keysyms 222	 'key-world-62)
    (vector-set! keysyms 223	 'key-world-63)
    (vector-set! keysyms 224	 'key-world-64)
    (vector-set! keysyms 225	 'key-world-65)
    (vector-set! keysyms 226	 'key-world-66)
    (vector-set! keysyms 227	 'key-world-67)
    (vector-set! keysyms 228	 'key-world-68)
    (vector-set! keysyms 229	 'key-world-69)
    (vector-set! keysyms 230	 'key-world-70)
    (vector-set! keysyms 231	 'key-world-71)
    (vector-set! keysyms 232	 'key-world-72)
    (vector-set! keysyms 233	 'key-world-73)
    (vector-set! keysyms 234	 'key-world-74)
    (vector-set! keysyms 235	 'key-world-75)
    (vector-set! keysyms 236	 'key-world-76)
    (vector-set! keysyms 237	 'key-world-77)
    (vector-set! keysyms 238	 'key-world-78)
    (vector-set! keysyms 239	 'key-world-79)
    (vector-set! keysyms 240	 'key-world-80)
    (vector-set! keysyms 241	 'key-world-81)
    (vector-set! keysyms 242	 'key-world-82)
    (vector-set! keysyms 243	 'key-world-83)
    (vector-set! keysyms 244	 'key-world-84)
    (vector-set! keysyms 245	 'key-world-85)
    (vector-set! keysyms 246	 'key-world-86)
    (vector-set! keysyms 247	 'key-world-87)
    (vector-set! keysyms 248	 'key-world-88)
    (vector-set! keysyms 249	 'key-world-89)
    (vector-set! keysyms 250	 'key-world-90)
    (vector-set! keysyms 251	 'key-world-91)
    (vector-set! keysyms 252	 'key-world-92)
    (vector-set! keysyms 253	 'key-world-93)
    (vector-set! keysyms 254	 'key-world-94)
    (vector-set! keysyms 255	 'key-world-95) ; #xFF

    ;;/* numeric keypad */
    (vector-set! keysyms 256	 'key-kp0)
    (vector-set! keysyms 257	 'key-kp1)
    (vector-set! keysyms 258	 'key-kp2)
    (vector-set! keysyms 259	 'key-kp3)
    (vector-set! keysyms 260	 'key-kp4)
    (vector-set! keysyms 261	 'key-kp5)
    (vector-set! keysyms 262	 'key-kp6)
    (vector-set! keysyms 263	 'key-kp7)
    (vector-set! keysyms 264	 'key-kp8)
    (vector-set! keysyms 265	 'key-kp9)
    (vector-set! keysyms 266	 'key-kp-period)
    (vector-set! keysyms 267	 'key-kp-divide)
    (vector-set! keysyms 268	 'key-kp-multiply)
    (vector-set! keysyms 269	 'key-kp-minus)
    (vector-set! keysyms 270	 'key-kp-plus)
    (vector-set! keysyms 271	 'key-kp-enter)
    (vector-set! keysyms 272	 'key-kp-equals)

    ;;/* arrows + home/end pad */
    (vector-set! keysyms 273	 'key-up-arrow)
    (vector-set! keysyms 274	 'key-down-arrow)
    (vector-set! keysyms 275	 'key-right-arrow)
    (vector-set! keysyms 276	 'key-left-arrow)
    (vector-set! keysyms 277	 'key-insert)
    (vector-set! keysyms 278	 'key-home)
    (vector-set! keysyms 279	 'key-end)
    (vector-set! keysyms 280	 'key-page-up)
    (vector-set! keysyms 281	 'key-page-down)
     
    ;;/* function keys */
    (vector-set! keysyms 282	 'key-f1)
    (vector-set! keysyms 283	 'key-f2)
    (vector-set! keysyms 284	 'key-f3)
    (vector-set! keysyms 285	 'key-f4)
    (vector-set! keysyms 286	 'key-f5)
    (vector-set! keysyms 287	 'key-f6)
    (vector-set! keysyms 288	 'key-f7)
    (vector-set! keysyms 289	 'key-f8)
    (vector-set! keysyms 290	 'key-f9)
    (vector-set! keysyms 291	 'key-f10)
    (vector-set! keysyms 292	 'key-f11)
    (vector-set! keysyms 293	 'key-f12)
    (vector-set! keysyms 294	 'key-f13)
    (vector-set! keysyms 295	 'key-f14)
    (vector-set! keysyms 296	 'key-f15)

    ;;/* key state modifier keys */
    (vector-set! keysyms 300	 'key-num-lock)
    (vector-set! keysyms 301	 'key-caps-lock)
    (vector-set! keysyms 302	 'key-scroll-lock)
    (vector-set! keysyms 303	 'key-right-shift)
    (vector-set! keysyms 304	 'key-left-shift)
    (vector-set! keysyms 305	 'key-right-control)
    (vector-set! keysyms 306	 'key-left-control)
    (vector-set! keysyms 307	 'key-right-alt)
    (vector-set! keysyms 308	 'key-left-alt)
    (vector-set! keysyms 309	 'key-right-meta)
    (vector-set! keysyms 310	 'key-left-meta)
    (vector-set! keysyms 311	 'key-left-super)  ; left  "windows"
    (vector-set! keysyms 312	 'key-right-super) ; right "windows"
    (vector-set! keysyms 313	 'key-mode)        ; "alt gr
    (vector-set! keysyms 314	 'key-compose)     ; multi-key compose

    ;;/* miscellaneous function keys */
    (vector-set! keysyms 315	 'key-help)
    (vector-set! keysyms 316	 'key-print-screen)
    (vector-set! keysyms 317	 'key-system-request)
    (vector-set! keysyms 318	 'key-break)
    (vector-set! keysyms 319	 'key-menu)
    (vector-set! keysyms 320	 'key-power) ; power macintosh power key 
    (vector-set! keysyms 321	 'key-euro) ; some european keyboards 
    (vector-set! keysyms 322	 'key-undo) ; atari keyboard has undo 

    (lambda (key-enum)
      (if (<= 0 key-enum keysyms-len)
          (vector-ref keysyms key-enum)
          (string->symbol
           (string-append "key-unknown-"
                          (number->string key-enum)))))))

;; TODO
(define (sdl::symbol->keysym-sym symbol) symbol)

(define (sdl::event-key-symbol event)
  (sdl::keysym-sym->symbol
   (sdl::event-key-keysym-sym event)))

;;; Key modifiers

(define sdl::key-modifiers->symbol-list
  (let ((bits-and-names
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
          (cons sdl::keymod-mode          'keymod-mode)))
        (bit  car)
        (name cdr))
    (lambda (keymods)
      (let ((bit-set?
             (lambda (bit)
               (not (zero? (bitwise-and bit keymods))))))
        (let loop ( [data bits-and-names] [modifiers '()] )
          (cond
           ((null? data) modifiers)     ; done
           ((bit-set? (bit (car data)))
            (loop (cdr data) (cons (name (car data)) modifiers)))
           (else
            (loop (cdr data) modifiers))))))))

(define (sdl::event-key-modifiers event)
  (sdl::key-modifiers->symbol-list
   (sdl::event-keysym-key-modifiers event)))

;-------------------------------------------------------------------------------
; Display
;-------------------------------------------------------------------------------

;;; Set clip area

(c-declare #<<end-of-c-declare
/* set_clip_area */
void set_clip_area(SDL_Surface *screen,
                   int x,     int y,
                   int width, int height) {
 SDL_Rect rect;

 rect.x = (Sint16)x;
 rect.y = (Sint16)y;
 rect.w = (Uint16)width;
 rect.h = (Uint16)height;
 
 SDL_SetClipRect( screen , &rect );
}
end-of-c-declare
)
(define sdl::set-clip-area!
  (c-lambda ((pointer "SDL_Surface") int int int int)
            void
            "set_clip_area"))

;;; Screen.pitch

(define sdl::screen-pitch
  (c-lambda ((pointer "SDL_Surface"))
            int
            "___result = ___arg1->pitch;"))

;;; Screen.pixels

(define sdl::surface-pixels
  (c-lambda ((pointer "SDL_Surface"))
            (pointer unsigned-char)
            "___result_voidstar = ___arg1->pixels;"))

;;; Blit surface

(c-declare #<<end-of-c-declare
int SDL_blit_surface( SDL_Surface *src,
                      int src_x, int src_y, int src_width, int src_height,
                      SDL_Surface *dest,
                      int dest_x, int dest_y, int dest_width, int dest_height ) {
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
end-of-c-declare
)
(define sdl::blit-surface
  (c-lambda ( (pointer "SDL_Surface") int32 int32 int32 int32 ;; source
              (pointer "SDL_Surface") int32 int32 int32 int32 ) ;; dest
            int32
            "SDL_blit_surface"))

;;; Surface locking

(c-declare #<<end-of-c-declare
int must_lock_surface_P(SDL_Surface *screen)
{
  return( SDL_MUSTLOCK(screen) );
}
end-of-c-declare
)
(define sdl::must-lock-surface?
    (c-lambda ((pointer "SDL_Surface"))
              bool
              "must_lock_surface_P"))

(define sdl::surface-unlocked? (make-parameter #t))

(define (sdl::with-locked-surface surface proc)
  (define (%%sdl::lock-surface surface)
    (if (sdl::must-lock-surface? surface)
        (let ( (result (sdl::lock-surface surface)) )
          (if result
              (sdl::error "Could not lock SDL surface")))))
  (define (%%sdl::unlock-surface surface)
    (if (sdl::must-lock-surface? surface)
        (let ((result (sdl::unlock-surface surface)))
          (if result
              (sdl::error "Could not lock SDL surface")))))  
  ;; Only lock surface once in outer call
  ;; Any number if nested calls are no-ops
  ;; Unlock on the way out
  (if (sdl::surface-unlocked?)
      (dynamic-wind
          (lambda ()
            (%%sdl::lock-surface surface)
            (sdl::surface-unlocked? #f))
          proc
          (lambda ()
            (%%sdl::unlock-surface surface)
            (sdl::surface-unlocked? #t)))
      (proc)))

;-------------------------------------------------------------------------------
; Draw
;-------------------------------------------------------------------------------

;;; Draw a rectangle

(c-declare #<<end-of-c-declare
/* draw_rect: return 0 => success, -1 =>error */
void draw_rect(SDL_Surface *screen,
              int x,     int y,
              int width, int height,
              int rgb_color ) {
 SDL_Rect rect;
 rect.x = (Sint16)x;
 rect.y = (Sint16)y;
 rect.w = (Uint16)width;
 rect.h = (Uint16)height;
 SDL_FillRect( screen, &rect, rgb_color ) ;
}
end-of-c-declare
)
(define sdl::draw-rect ;; x y width height rgb-color
  (c-lambda ((pointer "SDL_Surface") int int int int int)
            void
            "draw_rect"))

;;; Set screen pixel in a continuous array

(define sdl::set-screen-pixel!
  (c-lambda ((pointer "SDL_Surface") unsigned-int32 unsigned-int32)
            void
            "((unsigned int*)((SDL_Surface *)(___arg1->pixels)))[ ___arg2 ] = ___arg3 ;"))

;;; Set screen pixel given its x and y coordinates

(c-declare #<<end-of-c-declare
void putpixel(SDL_Surface *screen, int x, int y, int color) {
  unsigned int *ptr = (unsigned int*)screen->pixels;
  int lineoffset = y * (screen->pitch / 4);
  ptr[lineoffset + x] = color;
}       
end-of-c-declare
)
(define sdl::put-pixel!
  (c-lambda ((pointer "SDL_Surface") int int unsigned-int32)
            void
            "putpixel"))

;;; Load BMP

(define (sdl::load-bmp-file file-name-string)
  (define %sdl::load-bmp-file
    (c-lambda (char-string) (pointer "SDL_Surface") "SDL_LoadBMP"))
  (let ((surface (%sdl::load-bmp-file file-name-string)) )
    (if (not surface)
        (error "sdl::load-bmp-file: could not load BMP image from file"
               file-name-string)
        (make-will surface (lambda (surface) (sdl::free-surface surface))))
    surface))

;-------------------------------------------------------------------------------
; Misc
;-------------------------------------------------------------------------------

(define (sdl::error string)
  (error (string-append string
                        " >SDL> "
                        (sdl::get-error))))

(define (sdl::within-sdl-lifetime sdl-flags thunk)
  (if (zero? (sdl::init sdl-flags))
      (begin
        (dynamic-wind
            (lambda () #f)
            thunk
            sdl::exit)
        #t)
      #f))

;-------------------------------------------------------------------------------
; Platform-specific
;-------------------------------------------------------------------------------

;;; Initialize OSX code

;; (%if-sys
;;  "Darwin"
;;  (define SDL::init-osx
;;    (c-lambda ()
;;              void
;;              "sdl_osx_entry_point")))
    


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
