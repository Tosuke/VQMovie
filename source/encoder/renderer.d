module encoder.renderer;

import encoder.imports;
import derelict.sdl2.sdl;

class Renderer{
  private{
    SDL_Window* window;
    SDL_Renderer* renderer;
    SDL_Texture* texture;
  }
  this(string title, int windowWidth, int windowHeight, Uint32 textureFormat, int textureWidth, int textureHeight){
    //Load library
    DerelictSDL2.load;

    SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "linear");
    SDL_Init(SDL_INIT_TIMER | SDL_INIT_VIDEO);

    window = SDL_CreateWindow(title.toStringz, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, windowWidth, windowHeight, SDL_WINDOW_SHOWN);
    renderer = window.SDL_CreateRenderer(-1, 0);
    texture = renderer.SDL_CreateTexture(textureFormat, SDL_TEXTUREACCESS_STREAMING, textureWidth, textureHeight);
  }
  ~this(){
    texture.SDL_DestroyTexture();
    renderer.SDL_DestroyRenderer();
    window.SDL_DestroyWindow();
    SDL_Quit();
  }

  void update(SDL_Surface* surface)
    in{
      Uint32 format; int w, h;
      texture.SDL_QueryTexture(&format, null, &w, &h);
      //assert(format == surface.format.format);
      //assert(w == surface.w);
      //assert(h == surface.h);
    }
    body{
      void* pixels; int pitch;
      texture.SDL_LockTexture(null, &pixels, &pitch);
      surface.SDL_LockSurface();
      static import core.stdc.string;
      core.stdc.string.memcpy(pixels, surface.pixels, pitch * surface.h);
      surface.SDL_UnlockSurface();
      texture.SDL_UnlockTexture();
    }

  void draw(){
    renderer.SDL_RenderClear();
    renderer.SDL_RenderCopy(texture, null, null);
    renderer.SDL_RenderPresent();
  }
}
