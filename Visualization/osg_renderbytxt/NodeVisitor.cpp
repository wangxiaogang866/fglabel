#include "NodeVisitor.h"
#include <osg/Geode>
#include <osg/Node>
#include <osg/io_utils>
#include <osg/TriangleFunctor>
#include <osgDB/ReadFile>
#include <osg/Material>
#include <osg/PositionAttitudeTransform>


NodeVisitor::NodeVisitor(void) :osg::NodeVisitor(osg::NodeVisitor::TRAVERSE_ALL_CHILDREN), _indent(0)
{
	number = 1;
	count = 0;
	colorcount = 1;
	layernumber = 9999;
	proposalpoint = 1;
	newdata = false;
	groupnumber = 1;
	m_command = COMMAND_NULL;
}

NodeVisitor::~NodeVisitor(void)
{
	number = 1;
	count = 0;
	colorcount = 1;
	layernumber = 9999;
	proposalpoint = 1;
	newdata = false;
	groupnumber = 1;
	m_command = COMMAND_NULL;
}

void NodeVisitor::setCommand(COMMAND command)
{
	m_command = command;
}

void NodeVisitor::apply(osg::Node &node)
{
	for (int i = 0; i<_indent; ++i) std::cout << " ";
	std::cout << "[" << _indent + 1 << "]" << node.libraryName()
	<< "::" << node.className() << "::" << node.getName() << std::endl;

	string name = node.getName();
	string libraryname = node.libraryName();

	if (name == "db")
	{
		layernumber = _indent + 1;
	}

	if (_indent == layernumber)/////  
	{
		if (m_command == COMMAND_INIT)
		{
			osg::ref_ptr<osg::PositionAttitudeTransform> position = new osg::PositionAttitudeTransform();
			osg::ref_ptr<osg::Switch> sw = new osg::Switch();
			position->addChild(sw);

			sw->setName("sw" + name);
			position->setName("p" + name);
			sw->addChild(&node);
			node.getParent(0)->replaceChild(&node, position);
		}
	}

	if (layernumber + 2 == _indent + 1 && m_command == COMMAND_COLOR)//apart
	{
		newdata = true;
		char *tempChar = (char *)name.data();
		string tempStr = strtok(tempChar, "-");

		stringstream tempStream;
		tempStream << tempStr;
		tempStream >> temptype;
	}


	if (m_command == COMMAND_RESET && name[0] == 's'  && layernumber + 2 == _indent + 1)
	{
		node.asSwitch()->setAllChildrenOn();
	}

	if (m_command == COMMAND_RESET && name[0] == 'p' && layernumber + 1 == _indent + 1)
	{
		osg::Vec3 positionchange;
		switch (grouptype[groupnumber])
		{
		}

		osg::ref_ptr<osg::PositionAttitudeTransform> mt = dynamic_cast<osg::PositionAttitudeTransform *> (node.asTransform()->asPositionAttitudeTransform());
		if (mt)
		{
			mt->setPosition(mt->getPosition() - positionchange);
		}
	}

	if (name[0] == 'p' && m_command == COMMAND_COLOR && layernumber + 1 == _indent + 1)
	{
		osg::Vec3 positionchange;
		switch (grouptype[groupnumber])
		{
		}

		osg::ref_ptr<osg::PositionAttitudeTransform> mt = dynamic_cast<osg::PositionAttitudeTransform *> (node.asTransform()->asPositionAttitudeTransform());
		if (mt)
		{
			mt->setPosition(mt->getPosition() + positionchange);
		}
	}

	_indent++;
	traverse(node);
	_indent--;
}

void NodeVisitor::apply(osg::Geode& geode)
{
	osg::NodePath np(getNodePath().begin(), getNodePath().end() - 1);
	osg::Matrix matrix = osg::computeLocalToWorld(np);
	osg::Geode::DrawableList drawableList = geode.getDrawableList();

	osg::ref_ptr<osg::Vec4Array> changecolor = new osg::Vec4Array;

	if (m_command == COMMAND_COLOR)
	{
		if (!newdata)
		{
			groupnumber--;
		}

		if (temptype == 22)
		{
			changecolor->push_back(osg::Vec4(85.f / 255.f, 108.f / 255.f, 9.f / 255.f, 1.f));
		}
		else
		switch (grouptype[groupnumber])
		{
		case 1:
				changecolor->push_back(osg::Vec4(0.4431372549, 0.2392156863, 0.0509803922, 1.f));
				break;
			case 2:
				changecolor->push_back(osg::Vec4(0.8f, 0.0f, 0.8f, 1.f));
				break;
			case 3:
				changecolor->push_back(osg::Vec4(0.8, 0.8, 0.0, 1.f));
				break;
			case 4:
				changecolor->push_back(osg::Vec4(0.0f, 0.8f, 0.8f, 1.f));
				break;
			case 5:
				changecolor->push_back(osg::Vec4(1.0, 0.3490196078, 0.2, 1.f));
				break;
			case 6:
				changecolor->push_back(osg::Vec4(0.0f, 0.0f, 0.8f, 1.f));
				break;
			case 7:
				changecolor->push_back(osg::Vec4(0.6, 0.8549019608, 0.6, 1.f));
				break;
			case 8:
				changecolor->push_back(osg::Vec4(0.2862745098, 0, 0.9529411765, 1.f));
				break;
			case 9:
				changecolor->push_back(osg::Vec4(0.5450980392, 0.2745098039, 0.9098039216, 1.0));
				break;
		}


		for (osg::Geode::DrawableList::iterator itr = drawableList.begin(); itr < drawableList.end(); itr++)
		{
			osg::Geometry *geometry = (*itr)->asGeometry();
			osg::ref_ptr<osg::Array> geocolor = geometry->getColorArray();

			geometry->setColorArray(changecolor);
			geometry->setColorBinding(osg::Geometry::BIND_OVERALL);

			const GLvoid* data_pointer = geocolor->getDataPointer();

			osg::Vec4 color = osg::Vec4(0.10, 0.10, 0.10, 0.10);

			switch (geocolor->getDataType()){
			case GL_FLOAT:{
							  float* data = (float*)data_pointer;
							  color.set(data[0], data[1], data[2], data[3]);
							  break;
			}
			default:
				break;
			}
			osg::ref_ptr< osg::StateSet > state_set = geometry->getOrCreateStateSet();
			osg::ref_ptr< osg::Material > material = new osg::Material;
			material->setColorMode(osg::Material::AMBIENT_AND_DIFFUSE);
			material->setDiffuse(osg::Material::FRONT_AND_BACK, osg::Vec4(0.75f, 0.75f, 0.75f, 1.0f));
			material->setSpecular(osg::Material::FRONT_AND_BACK, osg::Vec4(0.75f, 0.75f, 0.75f, 1.0f));
			material->setAmbient(osg::Material::FRONT_AND_BACK, osg::Vec4(0.1171875f, 0.1171875f, 0.1171875f, 1.0f));
			material->setShininess(osg::Material::FRONT_AND_BACK, 51.2f);
			state_set->setAttributeAndModes(material.get(), osg::StateAttribute::ON);
		}
	}

	groupnumber++;

	newdata = false;
	

	_indent++;
	traverse(geode);
	_indent--;
}