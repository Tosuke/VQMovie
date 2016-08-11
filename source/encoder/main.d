module encoder.application;

import encoder.imports;
import encoder.renderer;
import encoder.decoder;
import encoder.data;

import derelict.sdl2.sdl;

class Application{
  private{
    Renderer renderer;
    IDecoder decoder;
  }
  this(){
    renderer = new Renderer("Test", 640, 480, SDL_PIXELFORMAT_RGBA8888, 8, 8);

    auto s = SDL_LoadBMP("./bmps/ba_0100.bmp".toStringz);
    s.format.BytesPerPixel.log;
    s.w.log;
    s.pitch.log;
    //auto s = SDL_CreateRGBSurface(0, 320, 240, 32, 0xff000000, 0x00ff0000, 0x0000ff00, 0x000000ff);
    auto surface = s.SDL_ConvertSurfaceFormat(SDL_PIXELFORMAT_RGB888, 0);
    s.SDL_FreeSurface;
    scope(exit) surface.SDL_FreeSurface();

    //surface.SDL_FillRect(new SDL_Rect(0, 0, 320, 240), surface.format.SDL_MapRGB(255, 255, 255));
    //surface.SDL_FillRect(new SDL_Rect(0, 0, 1, 1), surface.format.SDL_MapRGB(64, 128, 255));

    auto pixels = new ubyte[](surface.pitch * surface.h);
    static import core.stdc.string;
    core.stdc.string.memcpy(pixels.ptr, surface.pixels, surface.pitch * surface.h);

    auto image = surface.toImage;
    auto c = image[0, 0];
    c.r.log;
    c.g.log;
    c.b.log;
    auto i = image[0..8, 0..8];

    renderer.update(i.toSurface);

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
            running = false;
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


import std.experimental.ndslice;
SDL_Color[][] convertPixelData(SDL_Surface* surface)
  in{
    assert(surface.format.format == SDL_PIXELFORMAT_RGB888);
  }
  body{
    import std.range, std.algorithm;
    const p = cast(ubyte*)(surface.pixels);
    const ubyte[] data = p[0..surface.pitch * surface.h];
    auto pixels = new SDL_Color[][](surface.h, surface.w); //[y, x]
    auto pixeldata = cast(SDL_Color[])pixels.ptr[0..surface.w * surface.h];
    foreach(a; data.chunks(4).enumerate){
      SDL_Color c;
      c.a = a.value[3];
      c.r = a.value[2];
      c.g = a.value[1];
      c.b = a.value[0];
      /*
      c.a = a.value[0];
      c.r = a.value[1];
      c.g = a.value[2];
      c.b = a.value[3];
      */
      pixeldata[a.index] = c;
    }

    return pixels;
  }

//auto convertPixelData()

unittest{
  import std.algorithm, std.range;
  auto a = [1, 2, 3, 4].sliced(2, 2);
  a[].log;
  a.byElement.log;
}
