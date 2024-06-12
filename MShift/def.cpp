#include "def.h"
#include "BoostInclude.h"
namespace clustering
{
double SquareEuclideanDistance(const Coor& p1, const Coor& p2)
{
   return std::pow(p1.first  - p2.first , 2) +
          std::pow(p1.second - p2.second, 2); 
}
mDist ManhattanDistance(const Coor& p1, const Coor& p2)
{
    return std::abs((mDist)p1.first  - (mDist)p2.first) +
           std::abs((mDist)p1.second - (mDist)p2.second);
}
double gaussian(const Coor& p1, const Coor& p2, const double bandwidth)
{
    double nom = SquareEuclideanDistance(p1, p2);
    double denom = -2 * std::pow(bandwidth, 2);
    double ans = std::exp(nom/denom);
    return ans;
}
}
