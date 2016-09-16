module encoder.clustering;

import encoder.data;
import encoder.imports;

import std.algorithm, std.range, std.array, std.conv : to;
import std.typecons;

alias Index = Tuple!(int, "x", int, "y", int, "index");
struct ClusteringResult{
  Index[] indexes;
  Vector[] centroids;
}

ClusteringResult clustering(Vector[] vectors, int clusterNum, int maxIter = 10){
  import std.random;
  auto clusters = new Cluster[](clusterNum);
    foreach(ref a; clusters) a = new Cluster();

  //初期値決定
  import std.container;
  SList!Vector list;
  auto set = new HashSet!Vector;
  foreach(v; vectors) set.add(v);
  Vector v0 = vectors[0];
  set.remove(v0);
  list.insert(v0);
  clusters[0].set.add(v0);
  foreach(i; 1..clusterNum){
    set.rehash;
    v0 = zip(set[], set[].map!(a => list[].map!(b => distance(a, b)).minCount[0])).maxCount!"a[1]<b[1]"()[0][0];
    set.remove(v0);
    list.insert(v0);
    clusters[i].set.add(v0);
    i.log;
  }

  foreach(ref a; clusters) a.update;

  foreach(i; 0..maxIter){
    //集合の内容をリセットする
    foreach(ref a; clusters) a.set.clear;

    //各要素に一番近い集合に入れる
    foreach(v; vectors){
      zip(clusters[], clusters.map!(a => distance(v, a.centroid))).minCount!"a[1]<b[1]"()[0][0].set.add(v);
    }
    i.log;

    //セントロイドを更新する
    foreach(ref a; clusters) a.update;
  }

  Appender!(Index[]) indexes;
  foreach(index, c; clusters.enumerate){
    indexes ~=
      c.set[].map!(
        (a){
          Index i;
          i.x = a.pos.x;
          i.y = a.pos.y;
          i.index = index.to!int;
          return i;
        }
      );
  }

  Vector[] centroids = clusters.map!"a.centroid".array;
  vectors.length.log;
  clusters.map!"a.set.length".log;

  ClusteringResult result;
  result.indexes = indexes.data;
  result.centroids = centroids;

  return result;
}

class Cluster{
  this(){
    set = new HashSet!Vector();
  }

  HashSet!Vector set;
  Vector centroid;

  void update(){
    if(!set[].empty){
      centroid.vec = set[].reduce!((a, b) => a + b).vec[] / (set.length != 0 ? set.length.to!uint : 1);
    }
  }
}

class HashSet(T){
  protected ubyte[T] data;
  private size_t l;

  final auto opSlice(){
    return data.byKey;
  }

  void add(T a){
    if(a !in data) l++;
    data[a] = 0;
  }

  void remove(T a){
    if(a in data){
      data.remove(a);
      l--;
    }
  }

  void clear(){
    data = null;
    l = 0;
  }

  void rehash(){
    data.rehash;
  }

  bool contains(T a){
    return cast(bool)(a in data);
  }

  size_t length(){
    return l;
  }
}

auto distance(Vector a, Vector b){
  import std.algorithm, std.range;
  return ((a - b) * (a - b)).vec[].sum;
}
