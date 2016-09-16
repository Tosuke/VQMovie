module encoder.application;

import encoder.imports;
import encoder.renderer;
import encoder.decoder;
import encoder.data;
import encoder.clustering;

import derelict.sdl2.sdl;

import std.algorithm, std.range, std.array;

class Application{
  private{
    Renderer renderer;
    IDecoder decoder;
  }
  this(){
    renderer = new Renderer("Test", 640, 480, SDL_PIXELFORMAT_RGBA8888, 320, 240);

    auto s = SDL_LoadBMP("./bmps/ba_1000.bmp".toStringz);
    s.format.BytesPerPixel.log;
    s.w.log;
    s.pitch.log;
    //auto s = SDL_CreateRGBSurface(0, 320, 240, 32, 0xff000000, 0x00ff0000, 0x0000ff00, 0x000000ff);
    auto surface = s.SDL_ConvertSurfaceFormat(SDL_PIXELFORMAT_RGB888, 0);
    s.SDL_FreeSurface;
    scope(exit) surface.SDL_FreeSurface();

    auto blocks = surface.toImage.toBlocks(8, 8);

    auto vectors = blocks.map!(a => a.toVector).array;
    renderer.update(vectors.map!(a => a.toBlock).array.toImage(320, 240, 8, 8).toSurface);

    auto result = clustering(vectors, 48, 10);
    auto book = result.centroids.map!(a => a.toBlock.image).array;

    result.indexes.map!"a.index".walkLength.log;
    result.centroids[0].vec.log;

    auto image = Image(320, 240);
    foreach(i; result.indexes){
      auto x = i.x; auto y = i.y;
      image[x..x + 8, y..y + 8] = book[i.index];
    }

    renderer.update(image.toSurface);

    decoder = new TestDecoder();
  }
  ~this(){
    //SDL_Quit();
  }
  void run(){
    bool running = true;
    while(running && !decoder.empty){
      SDL_Event e;
      while(SDL_PollEvent(&e)){
        switch(e.type){
          case SDL_KEYDOWN, SDL_QUIT:
            //running = false;
            break;
          default:
            break;
        }
      }
      /*auto surface = decoder.front;
      renderer.update(surface);
      surface.SDL_FreeSurface();
      decoder.popFront();*/
      renderer.draw();

      SDL_Delay((1000 / 15).to!uint);
    }
  }
}

Vector toVector(Block blk){
  //モノクロに限る
  Vector vec;
  vec.pos = blk.pos;
  foreach(y; 0..8){
    foreach(x; 0..8){
      auto c = blk.image[x, y];
      vec.vec[x + y * 8] = (c.r + c.g + c.b) / 3;
    }
  }
  return vec;
}

Block toBlock(Vector v){
  Block blk;
  blk.image = Image(8, 8);
  blk.pos = v.pos;
  foreach(y; 0..8){
    foreach(x; 0..8){
      ubyte a = v.vec[x + y * 8].to!uint & 0xff;
      Color c;
      c.r = a;
      c.g = a;
      c.b = a;
      c.a = 0;
      blk[x, y] = c;
    }
  }
  return blk;
}
