# connect-4-zx-spectrum-48
z80 assembly implementation of a connect 4 game

These are my first steps into z80 assembly. I learnt with this fantastic series of tutorials:

https://www.youtube.com/watch?v=1gHlMpO8gqw&t=1379s

The code is quite different since I mostly watched the videos to get the gist of it but wrote my own code and refactored 
many parts as I learnt more. Also the tutorial deals with only graphics, while this is the complete game.

I don't recommend anyone to take this project as an example, since the code is likely very poorly written, and I will use it as a baseline 
where to try different techniques. Right now it contains plenty of bodges that I'm sure there must be much much more elegant ways to go around; 
some examples are pushing and poping the stack just to move values between the ix and hl registers, or a lot of code that in any other language
I would have modularised for reuse, rather than copy pasting.
