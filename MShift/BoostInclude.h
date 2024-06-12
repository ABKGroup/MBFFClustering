#ifndef _BOOST_INCLUDE_H_
#define _BOOST_INCLUDE_H_

#pragma GCC system_header
#include <boost/geometry.hpp>
#include <boost/geometry/geometries/point.hpp>
#include <boost/geometry/index/rtree.hpp>
#include <boost/foreach.hpp>
#include "def.h"
namespace bg = boost::geometry;
namespace bgi = boost::geometry::index;
namespace bgm = boost::geometry::model;
namespace clustering
{
typedef bg::model::point<double, 2, bg::cs::cartesian> Point;
typedef std::pair<Point, clustering::FF_id> PointWithID;
typedef bgi::rtree< PointWithID, bgi::quadratic<P_PER_NODE> > RTree;
double SquareEuclideanDistance(const Coor& p1, const PointWithID& p2);
mDist ManhattanDistance(const Coor& p1, const PointWithID& p2);
}
#endif
