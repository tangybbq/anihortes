The Anihortes keyboard

I have used the MessagEase keyboard for a number of years. The developer behind the iOS keyboard app
for this has been unresponsive for over 6 years, and the app is no longer usable with modern
versions of iOS.

So, the Anihortes keyboard, named after the key layout.

# This application

This application is a small iOS that initial doesn't do anything, other than provide a keyboard
extension that can be enabled by the user.

The idea of the keyboard is that the keyboard is basically shaped as a numeric keyboard, with a
larger zero and a space next to it:

> 123
> 456
> 789
> 0 _

But this is only in numeric mode. In alphabetic mode, the superficial presentation is:

> ani
> hor
> tes
> ___

with a larger spacebar.  But, each key actually has up to 8 additional function which are typed with
a simple gesture starting from that key and moving in one of the 8 cardinal directions from it.  The
rest of the letters are clustered around the center, and punctuation surrounds. The full layout is:

```
C    `^'
 a-  +n!  ?i
$•v  /l\  x=€

{ %  qup  |↑}
(hk  cob  mr)
[✓_  gdj  @↓]

~◌̈y  "w'  f&°
<t*   ez  #s>
  ␉  ,.:  ;
```

The "C" in the upper left is a "compose" character, which will not be initially implemented.  The
accents can modify the previous character if that makes sense. The up and down arrows are case
conversions. The checkmark types out ".com", and the rest are just the characters themselves.

To the side are 4 vertical buttons, the same size as the numeric, the top is the "world" to switch
keyboards, below that is an 'abc/123' key which switches the primary letters to numbers, then a
backspace, and at the bottom a newline.

# Git commit style

- Single-line summary at top (imperative mood, ~50 chars)
- Blank line
- Body paragraphs wrapped at 75 characters explaining the change
