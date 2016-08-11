module encoder.decoder;

import encoder.imports;
import derelict.sdl2.sdl;

interface IDecoder{
  @property int fps();
  @property int frames();
  @property SDL_Surface* front();
  void popFront();
  @property bool empty();
}

class TestDecoder : IDecoder{
  private int count = 0;
  @property int fps(){
    return 15;
  }
  @property int frames(){
    return 3282;
  }
  @property SDL_Surface* front()
    in{
      assert(!empty);
    }
    body{
      import std.format;
      auto s = SDL_LoadBMP(format("./bmps/ba_%04d.bmp", count).toStringz);
      auto surface = s.SDL_ConvertSurfaceFormat(SDL_PIXELFORMAT_RGBA8888, 0);
      s.SDL_FreeSurface();
      return surface;
    }
  void popFront()
    in{
      assert(!empty);
    }
    body{
      count++;
    }
  @property bool empty(){
    return count >= frames;
  }
}
