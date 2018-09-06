#include "GetTXTsOfModel.h"

GetTXTsOfModel::GetTXTsOfModel(){}

GetTXTsOfModel::~GetTXTsOfModel(){}

void GetTXTsOfModel::getAllPartNodesUnderNode(osg::Node* node,std::vector<osg::Group*>* partnodes)
{
	std::list<osg::Group*> dofnodequeue;
	osg::ref_ptr<osg::Group> tempgroup;

	int i=0,num=0;
	tempgroup=node->asGroup();
	dofnodequeue.push_back(tempgroup);
	if(isdigit(tempgroup->getName()[0]))
		partnodes->push_back(tempgroup);
	while(!dofnodequeue.empty())
	{
		tempgroup=dofnodequeue.front();
		dofnodequeue.pop_front();
		num=tempgroup->getNumChildren();
		for(i=0;i<num;i++)
		{
			if(!isdigit(tempgroup->getChild(i)->getName()[0]))
				dofnodequeue.push_back(tempgroup->getChild(i)->asGroup());
			else
				partnodes->push_back(tempgroup->getChild(i)->asGroup());
		}
	}
}

Graph* GetTXTsOfModel::getVertices_and_Edges_and_Triangles_UnderNode(osg::Node* node)
{
	TriangleNodeVisitor tnv;
	node->accept(tnv);
	Graph* graph=new Graph(tnv.get_vec3vector(),tnv.get_edgevector(),tnv.get_trianglevector());
	return graph;
}

void GetTXTsOfModel::save_txts_of_model(std::string model_path,std::string save_path)
{
	osg::ref_ptr<osg::Node> Model=osgDB::readNodeFile(model_path);
	if(Model==NULL)
		return;
	//print vertices and faces to txts
	Graph *graph=new Graph();
	graph=getVertices_and_Edges_and_Triangles_UnderNode(Model);
	Vec3Set::iterator vit;
	TriangleSet::iterator tit;
	std::map<osg::Vec3,int> temp_vertices_map;
	std::map<osg::Vec3,int>::iterator temp_it;

	std::map<Triangle,int> temp_faces_map;
	std::map<Triangle,int>::iterator tempjt;

	int i=0,j=0;

	std::string verticespath=save_path+"\\vertices.txt";
	std::string patchespath=save_path+"\\faces.txt";
	std::ofstream verticesmessage,patchesmessage;
	verticesmessage.open(verticespath);
	patchesmessage.open(patchespath);
	i=1;
	for(vit=graph->vec3vector->begin();vit!=graph->vec3vector->end();vit++)
	{
		verticesmessage<<vit->x()<<" "<<vit->y()<<" "<<vit->z()<<std::endl;
		temp_vertices_map.insert(std::pair<osg::Vec3,int>((*vit),i));
		i++;
	}
	i=1;
	for(tit=graph->trianglevector->begin();tit!=graph->trianglevector->end();tit++)
	{
		temp_faces_map.insert(std::pair<Triangle,int>((*tit),i));

		int index1=0,index2=0,index3=0,find=0;
		temp_it=temp_vertices_map.find(tit->a);
		index1=temp_it->second;
		temp_it=temp_vertices_map.find(tit->b);
		index2=temp_it->second;
		temp_it=temp_vertices_map.find(tit->c);
		index3=temp_it->second;
		patchesmessage<<index1<<" "<<index2<<" "<<index3<<std::endl;
		i++;
	}
	verticesmessage.close();
	patchesmessage.close();
	//print groups and labeled parts to txts
	std::string partspath=save_path+"\\parts.txt";
	std::string groupspath=save_path+"\\groups.txt";
	std::ofstream partsmessage,groupsmessage;
	partsmessage.open(partspath);
	groupsmessage.open(groupspath);
	//add part to partnodes
	std::vector<osg::Group*> partnodes;
	getAllPartNodesUnderNode(Model,&partnodes);

	int group_cnt=1;
	for(i=0;i<partnodes.size();i++)
	{
		partsmessage<<"Part"<<partnodes[i]->getName()<<std::endl;
		for(j=0;j<partnodes[i]->getNumChildren();j++)
		{
			groupsmessage<<"Group"<<group_cnt<<std::endl;
			partsmessage<<group_cnt<<std::endl;
			Graph *group_graph=new Graph();
			group_graph=getVertices_and_Edges_and_Triangles_UnderNode(partnodes[i]->getChild(j));
			TriangleSet::iterator git;
			for(git=group_graph->trianglevector->begin();git!=group_graph->trianglevector->end();git++)
			{
				tempjt=temp_faces_map.find(*git);
				groupsmessage<<tempjt->second<<std::endl;
			}
			group_cnt++;
			group_graph->~Graph();
		}
	}
	partsmessage.close();
	groupsmessage.close();
	graph->~Graph();
}