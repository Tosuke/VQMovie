module encoder.vector;

import std.algorithm, std.range, std.array;
import std.conv : to;
import std.traits, std.meta;

import encoder.imports;

//ベクトルをダックタイピング的に使えるようにする

//四則演算と比較が実装されているか
public enum bool isScalar(T) = is(typeof(
  (T a){
    {auto t1 = a + a;}
    {auto t1 = a - a;}
    {auto t1 = a * a;}
    {auto t1 = a / a;}

    bool b = a == a;
  }
));

public enum bool isVector(T) = is(typeof(
  (T v){
    size_t length = v.length;

    auto e = v[0];

    static assert(isScalar!(typeof(e)));
  }
));

public enum bool isMutableVector(T) = isVector!T && is(typeof(
  (T v){
    v[0] = ElementType!T.init;
  }
));

public struct SVector(T, size_t size) if(isScalar!T && size >= 1){
  @property public size_t length(){return size;}

  private T[size] data;

  public T opIndex(size_t index){
    return data[index];
  }

  public void opIndexAssign(T value, size_t index){
    data[index] = value;
  }

  mixin VectorMixin;
  mixin MutableVectorMixin;
}

public auto vector(T)(size_t size) if(isScalar!T)
in{
  assert(size >= 1);
}body{
  struct AVector{ //Allocated Vector
    this(size_t size){
      length = size;
      data = new T[size];
    }

    private size_t length_;
    @property{
      public size_t length(){return length_;}
      private void length(size_t a){length_ = a;}
    }

    private T[] data;
    public{
      T opIndex(size_t index){
        return data[index];
      }
      void opIndexAssign(T value, size_t index){
        data[index] = value;
      }
    }

    mixin VectorMixin;
    mixin MutableVectorMixin;
  }

  return AVector(size);
}

public auto vector(Range)(Range r)
  if(isInputRange!Range && !isInfinite!Range && isScalar!(ElementType!Range)){

  size_t length;
  static if(hasLength!Range){
    length = r.length;
  }else{
    length = r.walkLength;
  }

  auto vec = vector!(ElementType!Range)(length);
  size_t i = 0;
  foreach(e; r){
    vec[i++] = e;
  }

  return vec;
}

template ElementType(V) if(isVector!V){
  static if(is(typeof(V.init[0].init) T)){
    alias ElementType = T;
  }else{
    alias ElementType = void;
  }
}

unittest{
  static import std.math;

  static assert(isVector!(SVector!(float, 64)));
  auto vec = vector!float(64);
  static assert(isVector!(typeof(vec)));
  auto v1 = vector([1, 2, 3]);
  assert(v1[0] == 1);
  auto v2 = vector([3, 2, 1]);
  assert((v1 + v2) == vector([4, 4, 4]));

  auto v3 = (v1 + v2) / 4;
  assert(v3 == vector([1, 1, 1]));
  assert(v3.norm == std.math.sqrt(3.0));

  SVector!(int, 3) v4;
  v4 = v3;
}

//ベクトルの演算子などの実装
public mixin template VectorMixin(){
public:
  //ベクトル同士の加減算
  auto opBinary(string op, Vec)(Vec a) if((op == "+" || op == "-") && isVector!Vec){
    return vectorOpVector!op(this, a);
  }

  //ベクトルとスカラの四則演算
  auto opBinary(string op, T)(T a)
    if((op == "+" || op == "-" || op == "*" || op == "/") && isScalar!T){

    return vectorOpScalar!op(this, a);
  }

  //ベクトルの比較
  bool opEquals(Vec)(Vec vec) if(isVector!Vec)
  in{
    assert(this.length == vec.length); //長さの違うベクトル同士の演算は許されない
  }body{
    return iota(this.length).all!(i => this[i] == vec[i]);
  }
}

//代入可能なベクトルに対する操作の実装
public mixin template MutableVectorMixin(){
public:
  //ベクトルの代入
  void opAssign(Vec)(Vec vec) if(isVector!Vec)
  in{
    assert(this.length == vec.length);
  }body{
    iota(this.length).each!(
      (i){
        this[i] = vec[i];
      }
    );
  }
}

//ベクトル演算
//ベクトル同士の加減算
private auto vectorOpVector(string op, Vec1, Vec2)(Vec1 v1, Vec2 v2)
  if((op == "+" || op == "-") &&
    (isVector!Vec1 && isVector!Vec2) &&
    (!is(CommonType!(ElementType!Vec1, ElementType!Vec2) == void)))
in{
  assert(v1.length == v2.length);
}body{
  struct Vector{
    private{
      Vec1 vec1;
      Vec2 vec2;
    }
    public{
      this(Vec1 v1, Vec2 v2){
        vec1 = v1;
        vec2 = v2;
      }

      @property size_t length(){return vec1.length;}

      auto opIndex(size_t index){
        return mixin(`vec1[index]` ~ op ~ `vec2[index]`);
      }
    }

    mixin VectorMixin;
  }

  return Vector(v1, v2);
}

//ベクトルとスカラの四則演算
private auto vectorOpScalar(string op, Vec, T)(Vec v, T a)
  if((op == "+" || op == "-" || op == "*" || op == "/") &&
    (isVector!Vec && isScalar!T && !is(CommonType!(ElementType!Vec, T) == void))){

  struct Vector{
    private{
      Vec vec;
      T num;
    }
    public{
      this(Vec v, T n){
        vec = v;
        num = n;
      }

      @property size_t length(){return vec.length;}

      auto opIndex(size_t index){
        return mixin(`vec[index]` ~ op ~ `num`);
      }
    }

    mixin VectorMixin;
  }

  return Vector(v, a);
}

//内積
public auto dot(Vec1, Vec2)(Vec1 v1, Vec2 v2) if(isVector!Vec1 && isVector!Vec2)
in{
  assert(v1.length == v2.length); //長さの異なるベクトル同士の演算は許されない
}body{
  return iota(v1.length).map!(i => v1[i] * v2[i]).sum;
}

//精度の高い内積
public real dot_pred(Vec1, Vec2)(Vec1 v1, Vec2 v2) if(isVector!Vec1 && isVector!Vec2)
in{
  assert(v1.length == v2.length);
}body{
  return iota(v1.length).map!(i => v1[i].to!real * v2[i].to!real).sum;
}

//ベクトルの大きさ
public auto norm(Vec)(Vec vec) if(isVector!Vec){
  import std.math;
  return sqrt(dot(vec, vec).to!real);
}

//精度の高いベクトルの大きさ
public auto norm_pred(Vec)(Vec vec) if(isVector!Vec){
  import std.math;
  return sqrt(dot_pred(vec, vec));
}

//単位ベクトル
public auto normalized(Vec)(Vec vec) if(isVector!Vec){
  return vec / vec.norm;
}

//精度の高い単位ベクトル
public auto normalized_pred(Vec)(Vec vec) if(isVector!Vec){
  return vec / vec.norm_pred;
}
