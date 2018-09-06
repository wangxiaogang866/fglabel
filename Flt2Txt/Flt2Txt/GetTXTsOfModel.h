#pragma once

#include <stdarg.h>
#include <osg/Node>
#include <osg/Group>
#include <osg/Geode>
#include <osg/ComputeBoundsVisitor>
#include <osg/ShapeDrawable>
#include <osg/PolygonMode>
#include <osg/LineWidth>
#include <osg/Geometry>
#include <osg/Geode>
#include <osgDB/ReadFile>
#include <osgViewer/Viewer>
#include <osg/Array>
#include <iostream>
#include <osg/TriangleFunctor>
#include <direct.h> 

class Edge
{
public:
	Edge(){}
	Edge(osg::Vec3 v1,osg::Vec3 v2)
	{
		if(v1<v2)
		{
			a=v1;
			b=v2;
		}
		else
		{
			a=v2;
			b=v1;
		}
		length=sqrt((v1.x()-v2.x())*(v1.x()-v2.x())+
			(v1.y()-v2.y())*(v1.y()-v2.y())+
			(v1.z()-v2.z())*(v1.z()-v2.z()));
	}
	~Edge(){}

	bool operator==(const Edge &t) const//redefine "==" operation  
	{  
		return (a==t.a)&&(b==t.b); 
	} 

	bool operator<(const Edge &t) const//redefine  "<" operation 
	{  
		return (a<t.a)||(a==t.a&&b<t.b); 
	}

	osg::Vec3 a;
	osg::Vec3 b;
	double length;
};

//Save triangular patch infomations
class Triangle
{
public:
	Triangle();
	Triangle(osg::Vec3 v1,osg::Vec3 v2,osg::Vec3 v3)
	{
		if(v1<v2)
		{
			if(v2<v3)
			{
				a=v1;
				b=v2;
				c=v3;
			}
			else if(v1<v3)
			{
				a=v1;
				b=v3;
				c=v2;
			}
			else
			{
				a=v3;
				b=v1;
				c=v2;
			}
		}
		else
		{
			if(v3<v2)
			{
				a=v3;
				b=v2;
				c=v1;
			}
			else if(v1<v3)
			{
				a=v2;
				b=v1;
				c=v3;
			}
			else
			{
				a=v2;
				b=v3;
				c=v1;
			}
		}
	}
	~Triangle(){}

	bool operator==(const Triangle &t) const//redefine "==" operation  
	{  
		return (a==t.a)&&(b==t.b)&&(c==t.c); 
	} 

	bool operator<(const Triangle &t) const//redefine  "<" operation 
	{  
		return (a<t.a)||(a==t.a&&b<t.b)||(a==t.a&&b==t.b&&c<t.c); 
	}

	osg::Vec3 a;
	osg::Vec3 b;
	osg::Vec3 c;
};

//vertices set, edge set and triangular patch set
typedef std::set<osg::Vec3> Vec3Set;
typedef std::set<Edge> EdgeSet;
typedef std::set<Triangle> TriangleSet;

//class to save vertices set, edge set and triangular patch set
class Graph
{
public:
	Graph(){}
	Graph(Vec3Set* _vec3vector,EdgeSet* _edgevector,TriangleSet* _trianglevector)
	{
		vec3vector=_vec3vector;
		edgevector=_edgevector;
		trianglevector=_trianglevector;
	}
	~Graph()
	{
		delete(vec3vector);
		delete(edgevector);
		delete(trianglevector);
	}

	Vec3Set* vec3vector;
	EdgeSet* edgevector;
	TriangleSet* trianglevector; 
};

//traverse all triangle faces and save vertices,edges and faces
class TriangleOperator
{
public:
	void operator()(const osg::Vec3 &v1,const osg::Vec3 &v2,const osg::Vec3 &v3,bool )
	{
		trianglevector->insert(Triangle(v1,v2,v3));

		vec3vector->insert(v1);
		vec3vector->insert(v2);
		vec3vector->insert(v3);

		edgevector->insert(Edge(v1,v2));
		edgevector->insert(Edge(v2,v3));
		edgevector->insert(Edge(v3,v1));
	}

	TriangleSet *trianglevector;
	Vec3Set* vec3vector;
	EdgeSet* edgevector;
};

class TriangleNodeVisitor:public osg::NodeVisitor
{
public:
	TriangleNodeVisitor::TriangleNodeVisitor():osg::NodeVisitor(osg::NodeVisitor::TRAVERSE_ALL_CHILDREN)
	{
		trianglevector=new TriangleSet();
		vec3vector=new Vec3Set();
		edgevector=new EdgeSet();
	}
	~TriangleNodeVisitor(){}

	virtual void apply(osg::Geode &geode)
	{
		unsigned int i=0;
		osg::TriangleFunctor<TriangleOperator> to;
		to.trianglevector=trianglevector;
		to.vec3vector=vec3vector;
		to.edgevector=edgevector;
		for(i=0;i<geode.getNumDrawables();i++)
		{
			geode.getDrawable(i)->accept(to);
		}   
		traverse(geode);
	}

	TriangleSet* get_trianglevector()
	{
		return trianglevector;
	}

	EdgeSet* get_edgevector()
	{
		return edgevector;
	}

	Vec3Set* get_vec3vector()
	{
		return vec3vector;
	}

private:
	TriangleSet* trianglevector;
	EdgeSet* edgevector;
	Vec3Set* vec3vector;
};

class GetTXTsOfModel
{
public:
	GetTXTsOfModel();
	~GetTXTsOfModel();
	//save vertices¡¢faces¡¢parts¡¢groups to txts
	void save_txts_of_model(std::string,std::string);

private:
	Graph* getVertices_and_Edges_and_Triangles_UnderNode(osg::Node*);
	void getAllPartNodesUnderNode(osg::Node* node,std::vector<osg::Group*>* partnodes);
};