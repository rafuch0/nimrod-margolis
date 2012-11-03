from sdl import PSurface
from sdl_gfx import boxRGBA
import math
converter toInt16dammit(x: int): int16 = return int16(x)

const HEIGHT = 176
const WIDTH = 176
const size = 6

var thresh : int = 0x7f

const SCREENWIDTH = WIDTH*size
const SCREENHEIGHT = HEIGHT*size
const SCREENBPP = 32
const SCREENFLAGS = sdl.HWSURFACE or sdl.DOUBLEBUF

var pSurface : sdl.PSurface = sdl.CreateRGBSurface(SCREENFLAGS, SCREENWIDTH, SCREENHEIGHT, SCREENBPP, 255, 255, 255, 0)
#var keyEvent : sdl.PEvent
var keyEvent : sdl.TEvent

var automataData: array[0..(HEIGHT*WIDTH), int]
for i in countup(0, (HEIGHT*WIDTH) - 1):
  automataData[i] = 0

var c : int
template drawSemi(x1 : int, y1 : int, x2 : int, y2 : int) =
  c = getCell(x1, y1)
  discard sdl_gfx.boxRGBA(dst = pSurface, x1 = x1*size, y1 = y1*size, x2 = (x1+1)*size - 1, y2 = (y1+1)*size - 1, r = Byte(c), g = Byte(c), b = Byte(c), a = 255)
  c = getCell(x2, y2)
  discard sdl_gfx.boxRGBA(dst = pSurface, x1 = x2*size, y1 = y2*size, x2 = (x2+1)*size - 1, y2 = (y2+1)*size - 1, r = Byte(c), g = Byte(c), b = Byte(c), a = 255)

template drawFull() = 
  var c : int
  for i in countup(0, HEIGHT - 1):
    for j in countup(0, WIDTH - 1):
      c = getCell(i, j)
      discard sdl_gfx.boxRGBA(dst = pSurface, x1 = i*size, y1 = j*size, x2 = (i+1)*size - 1, y2 = (j+1)*size - 1, r = Byte(c), g = Byte(c), b = Byte(c), a = 255)

template fixX(x: int): int =
  ((WIDTH + (x)) mod WIDTH)
template fixY(y: int): int =
  ((HEIGHT + (y)) mod HEIGHT)
template getCell(x: int, y:int): int =
  (automataData[fixX(x) + (fixY(y)*WIDTH)])

var temp : int
proc swap(x1: int, y1: int, x2: int, y2: int) =
  temp = getCell(x1, y1)
  getCell(x1, y1) = getCell(x2, y2)
  getCell(x2, y2) = temp
  drawSemi(x1, y1, x2, y2)  

template swapDiag1(x: int, y: int) =
  swap(x, y, x+1, y+1)
template swapDiag2(x: int, y: int) =
  swap(x+1, y, x, y+1)
template swapHoriz1(x: int, y: int) =
  swap(x, y, x+1, y)
template swapHoriz2(x: int, y: int) =
  swap(x, y+1, x+1, y+1)
template swapVert1(x: int, y: int) =
  swap(x, y, x, y+1)
template swapVert2(x: int, y: int) =
  swap(x+1, y, x+1, y+1)

const T = true
const F = false

var rules: array[0..16 - 1, array[0..6 - 1, bool]] = [[F, F, F, F, F, F], 
    [T, F, F, F, F, F], [F, T, F, F, F, F], [F, F, F, F, F, F], 
    [F, T, F, F, F, F], [F, F, F, F, F, F], [F, F, T, T, F, F], 
    [T, F, F, F, F, F], [T, F, F, F, F, F], [F, F, T, T, F, F], 
    [F, F, F, F, F, F], [F, T, F, F, F, F], [F, F, F, F, F, F], 
    [F, T, F, F, F, F], [T, F, F, F, F, F], [F, F, F, F, F, F]]

proc initMap1() =
  for i in countup(0, HEIGHT - 1):
    for j in countup(0, WIDTH - 1):
      if i >= HEIGHT div 4 and i < HEIGHT-(HEIGHT div 4) and j >= WIDTH div 4 and j < WIDTH - (WIDTH div 4):
        automataData[i*WIDTH+j] = 255
      else:
        automataData[i*WIDTH+j] = 0
  drawFull()

proc initMap2() =
  for i in countup(0, HEIGHT - 1):
    for j in countup(0, WIDTH - 1):
      if i >= HEIGHT div 4 and i < HEIGHT-(HEIGHT div 4) and j >= WIDTH div 4 and j < WIDTH - (WIDTH div 4):
        automataData[i*WIDTH+j] = 128 + (i * i + j * j) mod (WIDTH div 2)
      else:
        automataData[i*WIDTH+j] = 0 + (i * i + j * j) mod (WIDTH div 2)
  drawFull()

proc randomThresh() =
  thresh = random(256)

proc randomRules() =
  for i in countup(0, 15):
    for j in countup(0, 5):
        if random(50) > 25:
          rules[i][j] = false
        else:
          rules[i][j] = true

proc doTransition(x: int, y: int, currState: int) =
  for i in countup(0, 5):
    if rules[currState][i]:
      case i
      of 0:
        swapDiag1(x, y)
      of 1:
        swapDiag2(x, y)
      of 2:
        swapHoriz1(x, y)
      of 3:
        swapHoriz2(x, y)
      of 4:
        swapVert1(x, y)
      of 5:
        swapVert2(x, y)
      else:
        nil

template getConfiguration(i: int, j: int): int =
  ((if getCell(i+1, j+1) > thresh: 8 else: 0) + (if getCell(i, j+1) > thresh: 4 else: 0) + (if getCell(i+1, j) > thresh: 2 else: 0) + (if getCell(i, j) > thresh: 1 else: 0))

var evenodd = 1
proc nextGeneration() =
  evenodd = (evenodd + 1) mod 2
  for i in countup(evenodd, HEIGHT - 1, 2):
    for j in countup(evenodd, WIDTH - 1, 2):
      doTransition(i, j, getConfiguration(i, j))

if true:
  if sdl.Init(sdl.INIT_VIDEO) < 0:
    echo "error initializing video"
  else:
    echo "video initialized"

  pSurface = sdl.SetVideoMode(SCREENWIDTH, SCREENHEIGHT, SCREENBPP, SCREENFLAGS)

  initMap1()

  var running = true
  while running:
    nextGeneration()
    #drawFull()
    discard sdl.Flip(pSurface)
    while sdl.PollEvent(addr keyEvent).bool:
      case keyEvent.kind
      of sdl.KEYUP:
        case sdl.evKeyboard(addr keyEvent).keysym.sym
        of sdl.K_DOWN:
          randomRules()
        of sdl.K_UP:
          randomThresh()
        of sdl.K_LEFT:
          initMap1()
        of sdl.K_RIGHT:
          initMap2()
        of sdl.K_SPACE:
          echo "test"
        of sdl.K_ESCAPE:
          running = false
        else:
          echo "no"
      else:
        nil
