rgbasm -i src -o build/main.o src/main.asm && (
  rgblink -o build/skateboy.gb -n build/skateboy.sym build/main.o && (
    rgbfix -p0 -v build/skateboy.gb && (
      echo Build complete
    )
  )
) 
