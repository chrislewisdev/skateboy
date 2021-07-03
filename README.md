# skateboy

Skateboy (working title) is a skateboarding game for the original Gameboy, built using assembly.

## Current Status

The game in its current form is really just a proof of concept, with some technical/design elements still needing to be fleshed out. I am in two minds as to how far I will take it mainly due to the realisation that a game intended to be fast-paced like this one is not terribly well suited to the original Gameboy hardware, due to the poor screen visibility and response time.

## Building

Building this project requires that you have `make` installed as well as [rgbds](https://github.com/gbdev/rgbds) and [Aseprite](https://github.com/aseprite/aseprite) (which can be built from source if you do not have the paid version).

Provided you have all dependencies, the ROM of the game can be built by simply running `make`.

To play the game, you will need to load it into a Gameboy emulator (I use [BGB](https://bgb.bircd.org/) for testing) or better yet, real hardware using a flash cart of some kind.
