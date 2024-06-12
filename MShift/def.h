#ifndef _DEF_H_
#define _DEF_H_
#include <iostream>
#include <utility>
#include <string>
#include <limits>
#include <vector>
#include <cmath>
#include <cassert>
#include <algorithm>
#define P_PER_NODE 16
namespace clustering
{
typedef int FF_id;
typedef int Cluster_id;
typedef double eDist; //Euclidean distance
typedef int    mDist; //Manhattan distance
typedef std::pair<FF_id, eDist> NeighborFF;
typedef std::pair<double, double> Coor;

double SquareEuclideanDistance(const Coor& p1, const Coor& p2);
mDist ManhattanDistance(const Coor& p1, const Coor& p2);
double gaussian(const Coor& p1, const Coor& p2,const double bandwidth);
}

#endif
