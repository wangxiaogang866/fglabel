#ifndef NODE_VISITOR_H
#define NODE_VISITOR_H

#include <osg/NodeVisitor>
#include <iostream>
#include <fstream> 
#include <vector>
#include <osg/Switch>
#include <osg/ShapeDrawable>

using namespace std;

enum COMMAND{ COMMAND_INIT, COMMAND_NULL, COMMAND_APART, COMMAND_COLOR, COMMAND_RESET, COMMAND_COLORINIT };

struct CaptureDrawCallback : public osg::Camera::DrawCallback
{
	CaptureDrawCallback(osg::ref_ptr<osg::Image> image)
	{
		_image = image;
	}

	~CaptureDrawCallback(){}

	virtual void operator()(const osg::Camera& camera)const
	{
		osg::ref_ptr<osg::GraphicsContext::WindowingSystemInterface> wsi = osg::GraphicsContext::getWindowingSystemInterface();
		unsigned int width, height;

		wsi->getScreenResolution(osg::GraphicsContext::ScreenIdentifier(0), width, height);

		_image->allocateImage(1680, 1050, 1, GL_RGB, GL_UNSIGNED_BYTE);
		_image->readPixels(0, 0, 1680, 1050, GL_RGB, GL_UNSIGNED_BYTE);
	}

	osg::ref_ptr<osg::Image> _image;

};
class NodeVisitor :
	public osg::NodeVisitor
{
public:
	NodeVisitor(void);
	~NodeVisitor(void);
	int number;
	vector<osg::Vec3> veclist;
	int temptype;
	int count;
	int colorcount;
	int layernumber;
	int grouptype[10001];
	int proposalpoint;
	bool newdata;
	int groupnumber;

public:
	virtual void apply(osg::Node &node);
	virtual void apply(osg::Geode &node);
	void setCommand(COMMAND command);

protected:
	int  _indent;
	COMMAND m_command;

};


#endif