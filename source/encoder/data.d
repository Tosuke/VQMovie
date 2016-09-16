module encoder.data;

import encoder.imports;
import std.string;
import derelict.sdl2.sdl;
import std.experimental.logger;

unittest{
  Color a;
  a.rgba.log;
}

//データ型の定義
struct Color{
  ubyte r, g, b, a;
  @property{
    uint rgba(){
      return r << 24 | g << 16 | b << 8 | a;
    }
    void rgba(uint k){
      r = (k & 0xff000000) >> 24;
      g = (k & 0x00ff0000) >> 16;
      b = (k & 0x0000ff00) >>  8;
      a = (k & 0x000000ff);
    }
  }
}
struct Image{
  private Color[][] pixels_;
  private size_t width_, height_;
  @property{

    public Color[][] pixels(){return pixels_;}

    public size_t width(){return width_;}
    private void width(size_t a){width_ = a;}

    public size_t height(){return  height_;}
    private void height(size_t a){height_ = a;}
  }

  this(size_t w, size_t h){
    pixels_ = new Color[][](w, h);
    width = w;
    height = h;
  }
  this(Color[][] p){
    pixels_ = p;
    height = p.length;
    width = p.length > 0 ? p[0].length : 0;
  }

  Color opIndex(in size_t x, in size_t y){
    return pixels[x][y];
  }
  void opIndexAssign(in Color value, in size_t x, in size_t y){
    pixels_[x][y] = value;
  }
  Image opIndex(in size_t[2] x, in size_t[2] y){
    auto image = Image(x[1] - x[0], y[1] - y[0]);
    foreach(cx; x[0]..x[1]){
      foreach(cy; y[0]..y[1]){
        image[cx - x[0], cy - y[0]] = this[cx, cy];
      }
    }
    return image;
  }
  void opIndexAssign(Image value, in size_t[2] x, in size_t[2] y){
    foreach(cx; x[0]..x[1]){
      foreach(cy; y[0]..y[1]){
        this[cx, cy] = value[cx - x[0], cy - y[0]];
      }
    }
  }

  size_t[2] opSlice(size_t dim)(size_t begin, size_t end) if(0 <= dim && dim < 2)
    in{
      assert(0 <= begin);
      assert(end <= this.opDollar!dim());
    }
    body{
      return [begin, end];
    }
  @property size_t opDollar(size_t dim : 0)(){return width;}
  @property size_t opDollar(size_t dim : 1)(){return height;}
}

unittest{
  auto a = Image(320, 240);

  auto b = a[0..8, 0..8];
  b.width.log;
}

Image toImage(SDL_Surface* surface){
  uint w, h, pitch, bpp;
  w = surface.w; h = surface.h;
  pitch = surface.pitch; bpp = surface.format.BytesPerPixel;
  SDL_PixelFormat* fmt = surface.format;

  auto image = Image(w, h);
  ubyte[] pixelData = (cast(ubyte*)surface.pixels)[0..h * pitch];

  foreach(y; 0..h){
    //BytesPerPixel = 4と決めつける
    uint[] pixels = cast(uint[])(pixelData[y * pitch..y * pitch + w * 4]);

    foreach(x; 0..w){
      Color c;
      uint pixel = pixels[x];
      c.r = cast(ubyte)(((pixel & fmt.Rmask) >> fmt.Rshift) << fmt.Rloss);
      c.g = cast(ubyte)(((pixel & fmt.Gmask) >> fmt.Gshift) << fmt.Gloss);
      c.b = cast(ubyte)(((pixel & fmt.Bmask) >> fmt.Bshift) << fmt.Bloss);
      c.a = cast(ubyte)(((pixel & fmt.Amask) >> fmt.Ashift) << fmt.Aloss);

      image[x, y] = c;
    }
  }

  return image;
}

SDL_Surface* toSurface(Image image){
  import std.algorithm, std.array;
  auto pixels = new Color[](image.width * image.height);
  foreach(y; 0..image.height){
    foreach(x; 0..image.width){
      pixels[x + y * image.width] = image[x, y];
    }
  }
  auto pixelData = pixels.map!"a.rgba".array;

  return SDL_CreateRGBSurfaceFrom(cast(void*)pixelData.ptr, image.width.to!int, image.height.to!int, 32, image.width.to!int * 4,
                                  0xff000000, 0x00ff0000, 0x0000ff00, 0x000000ff);
}

//ブロック
import std.typecons;
alias Vec2 = Tuple!(int, "x", int, "y");
struct Block{
  Image image;
  Vec2 pos;

  alias image this;
}

Block[] toBlocks(Image img, int w, int h){
  assert(img.width % w == 0);
  assert(img.height % h == 0);

  import std.array;
  Appender!(Block[]) blocks;
  for(int y = 0; y < img.height; y += h){
    for(int x = 0; x < img.width; x += w){
      Block block;
      block.image = img[x..x + w, y..y + h];
      block.pos.x = x;
      block.pos.y = y;
      blocks ~= block;
    }
  }

  return blocks.data;
}

Image toImage(Block[] blocks, int w, int h, int bw, int bh){
  auto img = Image(w, h);
  foreach(a; blocks){
    auto x = a.pos.x; auto y = a.pos.y;
    img[x..x + bw, y..y + bh] = a.image;
  }
  return img;
}
//ベクトル
struct Vector{
  float[64] vec;
  Vec2 pos;

  //alias vec this;

  Vector opBinary(string op)(Vector a){
    Vector b;
    import std.algorithm, std.range, std.array;
    auto vec = zip(this.vec[], a.vec[]).map!(a => mixin("a[0]"~op~"a[1]")).array;
    b.vec[] = vec[];
    return b;
  }
}
