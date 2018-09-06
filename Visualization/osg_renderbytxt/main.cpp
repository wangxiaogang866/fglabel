#include <osgViewer/Viewer>
#include <osg/Node>
#include <osg/LightModel>
#include <osg/Group>
#include <osgDB/readFile>
#include <osgGA/TrackballManipulator>
#include "NodeVisitor.h"
#include <osg/Camera>
#include <osgViewer/CompositeViewer>
#include <osg/Material>
#include <io.h>
#include <time.h>
#include <string>
#include "NodeVisitor.h"
#include <osg/Image>
#include <osgDB/ReadFile>
#include <osgDB/WriteFile>
#include <osg/PositionAttitudeTransform>

#include <osg/TextureCubeMap>
#include <osg/TexGen>
#include <osg/TexEnvCombine>
#include <osg/ShadeModel>
#include <osg/Multisample>
#include <osgUtil/ReflectionMapGenerator>
#include <osgUtil/HighlightMapGenerator>
#include <osgUtil/HalfWayMapGenerator>

#include <osgUtil/Optimizer>
#include <osg/LineWidth>
#include <osgGA/NodeTrackerManipulator>
#include <osgGA/UFOManipulator>
#include <osgGA/FlightManipulator>
#include <osgGA/TerrainManipulator>

#include <osgShadow/ShadowMap>
#include <osgShadow/ShadowedScene>
#include <osgShadow/ShadowTexture>
#include <osgUtil/SmoothingVisitor>
#include <osgShadow/ParallelSplitShadowMap>
#include <osgShadow/ShadowVolume>
#include <osgShadow/SoftShadowMap>
#include <osg/PolygonMode>
#include <osg/PolygonOffset>

osg::ref_ptr<osg::Image> image_c = new osg::Image();

osg::Vec3d upArray[3] = { osg::Vec3d(0.0f, 1.0f, 0.0f), osg::Vec3d(0.0f, 1.0f, -1.0f), osg::Vec3d(0.0f, 1.0f, 1.0f) };

const float GOLDENMEAN = 0.618;

osg::Vec3d eyeArray[20] = { osg::Vec3d(0, 1 / GOLDENMEAN, GOLDENMEAN), osg::Vec3d(0, -1 / GOLDENMEAN, GOLDENMEAN), osg::Vec3d(0, 1 / GOLDENMEAN, -GOLDENMEAN),
osg::Vec3d(0, -1 / GOLDENMEAN, -GOLDENMEAN), osg::Vec3d(1 / GOLDENMEAN, GOLDENMEAN, 0), osg::Vec3d(-1 / GOLDENMEAN, GOLDENMEAN, 0), osg::Vec3d(1 / GOLDENMEAN, -GOLDENMEAN, 0),
osg::Vec3d(-1 / GOLDENMEAN, -GOLDENMEAN, 0), osg::Vec3d(GOLDENMEAN, 0, 1 / GOLDENMEAN), osg::Vec3d(-GOLDENMEAN, 0, 1 / GOLDENMEAN), osg::Vec3d(GOLDENMEAN, 0, -1 / GOLDENMEAN),
osg::Vec3d(-GOLDENMEAN, 0, -1 / GOLDENMEAN), osg::Vec3d(1, 1, 1), osg::Vec3d(-1, 1, 1), osg::Vec3d(1, -1, 1), osg::Vec3d(1, 1, -1), osg::Vec3d(-1, 1, -1), osg::Vec3d(-1, -1, 1),
osg::Vec3d(1, -1, -1), osg::Vec3d(-1, -1, -1) };

using namespace std;

vector<string> files;
vector<string> files2;

void create_specular_highlights(osg::Node *node)
{
	osg::StateSet *ss = node->getOrCreateStateSet();

	// create and setup the texture object
	osg::TextureCubeMap *tcm = new osg::TextureCubeMap;
	tcm->setWrap(osg::Texture::WRAP_S, osg::Texture::CLAMP);
	tcm->setWrap(osg::Texture::WRAP_T, osg::Texture::CLAMP);
	tcm->setWrap(osg::Texture::WRAP_R, osg::Texture::CLAMP);
	tcm->setFilter(osg::Texture::MIN_FILTER, osg::Texture::LINEAR_MIPMAP_LINEAR);
	tcm->setFilter(osg::Texture::MAG_FILTER, osg::Texture::LINEAR);

	// generate the six highlight map images (light direction = [1, 1, -1])
	osgUtil::HighlightMapGenerator *mapgen = new osgUtil::HighlightMapGenerator(
		osg::Vec3(1, 0, 1),   // light direction
		osg::Vec4(0.2, 0.2, 0.2, 0.2),    // light color
		16);                             // specular exponent

	mapgen->generateMap();

	// assign the six images to the texture object
	tcm->setImage(osg::TextureCubeMap::POSITIVE_X, mapgen->getImage(osg::TextureCubeMap::POSITIVE_X));
	tcm->setImage(osg::TextureCubeMap::NEGATIVE_X, mapgen->getImage(osg::TextureCubeMap::NEGATIVE_X));
	tcm->setImage(osg::TextureCubeMap::POSITIVE_Y, mapgen->getImage(osg::TextureCubeMap::POSITIVE_Y));
	tcm->setImage(osg::TextureCubeMap::NEGATIVE_Y, mapgen->getImage(osg::TextureCubeMap::NEGATIVE_Y));
	tcm->setImage(osg::TextureCubeMap::POSITIVE_Z, mapgen->getImage(osg::TextureCubeMap::POSITIVE_Z));
	tcm->setImage(osg::TextureCubeMap::NEGATIVE_Z, mapgen->getImage(osg::TextureCubeMap::NEGATIVE_Z));

	// enable texturing, replacing any textures in the subgraphs
	ss->setTextureAttributeAndModes(0, tcm, osg::StateAttribute::OVERRIDE | osg::StateAttribute::ON);

	// texture coordinate generation
	osg::TexGen *tg = new osg::TexGen;
	tg->setMode(osg::TexGen::REFLECTION_MAP);
	ss->setTextureAttributeAndModes(0, tg, osg::StateAttribute::OVERRIDE | osg::StateAttribute::ON);

	// use TexEnvCombine to add the highlights to the original lighting
	osg::TexEnvCombine *te = new osg::TexEnvCombine;
	te->setCombine_RGB(osg::TexEnvCombine::ADD);
	te->setSource0_RGB(osg::TexEnvCombine::TEXTURE);
	te->setOperand0_RGB(osg::TexEnvCombine::SRC_COLOR);
	te->setSource1_RGB(osg::TexEnvCombine::PRIMARY_COLOR);
	te->setOperand1_RGB(osg::TexEnvCombine::SRC_COLOR);
	ss->setTextureAttributeAndModes(0, te, osg::StateAttribute::OVERRIDE | osg::StateAttribute::ON);
}

void OSGSUBGRAPHFiles(string path, vector<string>& files)
{
	long   hFile = 0;

	struct _finddata_t fileinfo;
	string p;
	string filename;
	if ((hFile = _findfirst(p.assign(path).append("\\*").c_str(), &fileinfo)) != -1)
	{
		do
		{
			if ((fileinfo.attrib &  _A_SUBDIR))  //is fold
			{
				if (strcmp(fileinfo.name, ".") != 0 && strcmp(fileinfo.name, "..") != 0)
				{
					OSGSUBGRAPHFiles(p.assign(path).append("\\").append(fileinfo.name), files);
				}
			}
			else 
			{
				files.push_back(p.assign(path).append("\\").append(fileinfo.name));
			}

		} while (_findnext(hFile, &fileinfo) == 0);

		_findclose(hFile); 
	}
}

void ModelColor(string path, string filename)
{
	int pixelwidth = 1680, pixelheight = 1050;

	osg::ref_ptr<osg::GraphicsContext::Traits> traits = new osg::GraphicsContext::Traits;
	traits->x = 0;
	traits->y = 0;
	traits->width = pixelwidth;
	traits->height = pixelheight;
	traits->windowDecoration = true;
	traits->doubleBuffer = true;
	traits->sharedContext = 0;
	traits->samples = 16;

	osg::ref_ptr<osg::GraphicsContext> gc = osg::GraphicsContext::createGraphicsContext(traits.get());
	if (gc->valid())
	{
		osg::notify(osg::INFO) << " GraphicsWindow has been created successfully." << std::endl;
	}
	else
	{
		osg::notify(osg::NOTICE) << " GraphicsWindow has not been created successfully." << std::endl;
	}

	osg::ref_ptr<osgViewer::Viewer> viewer = new osgViewer::Viewer;
	osg::ref_ptr<osg::Group> root = new osg::Group;

	osgDB::Options* a = new osgDB::Options(std::string("noTriStripPolygons"));
	osg::ref_ptr<osg::Node> model = osgDB::readNodeFile(path + "model.ive", a);

	create_specular_highlights(model);

	osg::StateSet* state = root->getOrCreateStateSet();
	osg::ref_ptr<osg::LightModel> TwoSideLight = new osg::LightModel;
	TwoSideLight->setTwoSided(true);
	state->setMode(GL_CULL_FACE, osg::StateAttribute::OVERRIDE | osg::StateAttribute::OFF | osg::StateAttribute::PROTECTED);   // 只关闭背面裁剪，造成生成背面不透明，但黑面;
	state->setAttributeAndModes(TwoSideLight, osg::StateAttribute::OVERRIDE | osg::StateAttribute::ON | osg::StateAttribute::PROTECTED);  //再加上双面光照，使背面完全出现;

	osgUtil::Optimizer optimzer;
	optimzer.optimize(model);

	osg::ref_ptr<osg::PositionAttitudeTransform> positionTransform = new osg::PositionAttitudeTransform;
	positionTransform->setPivotPoint(osg::Vec3(0.0, 0.0, 0.0));

	osg::ref_ptr<osg::MatrixTransform> matrixTransform = new osg::MatrixTransform;
	matrixTransform->addChild(positionTransform);

	positionTransform->addChild(model);

	root->addChild(matrixTransform.get());

	osg::StateSet* root_state = root->getOrCreateStateSet();
	root_state->setMode(GL_LIGHTING, osg::StateAttribute::ON);
	state->setMode(GL_LIGHT0, osg::StateAttribute::ON);
	state->setMode(GL_LIGHT1, osg::StateAttribute::ON);
	state->setMode(GL_LIGHT2, osg::StateAttribute::ON);
	state->setMode(GL_LIGHT3, osg::StateAttribute::ON);
	state->setMode(GL_LIGHT4, osg::StateAttribute::ON);
	state->setMode(GL_LIGHT5, osg::StateAttribute::ON);

	osg::ref_ptr<osg::Light> light0 = new osg::Light();
	light0->setLightNum(0);
	light0->setPosition(osg::Vec4(3.0f, 0.0f, 3.0f, 1.0f));
	light0->setAmbient(osg::Vec4(0.5f, 0.5f, 0.5f, 1.0f));
	light0->setDiffuse(osg::Vec4(0.6f, 0.6f, 0.6f, 1.0f));
	light0->setSpecular(osg::Vec4(0.7f, 0.7f, 0.7f, 1.0f));

	osg::ref_ptr<osg::LightSource> ls0 = new osg::LightSource();
	ls0->setLight(light0);

	root->addChild(ls0);

	viewer->setSceneData(root);

	viewer->getCamera()->setClearColor(osg::Vec4f(1.0f, 1.0f, 1.0f, 1.0f));
	viewer->getCamera()->setGraphicsContext(gc);
	viewer->getCamera()->setViewport(new osg::Viewport(0, 0, traits->width, traits->height));

	double fovy, aspectRatio, zNear, zFar;
	viewer->getCamera()->getProjectionMatrixAsPerspective(fovy, aspectRatio, zNear, zFar);

	double newAspectRatio = double(traits->width) / double(traits->height);
	double aspectRatioChange = newAspectRatio / aspectRatio;

	viewer->getCamera()->setProjectionMatrixAsPerspective(25, aspectRatioChange, zNear, zFar);//other 25 // //plane 18 //cabinet 30 // car 15

	
	if (aspectRatioChange != 1.0)
	{
		viewer->getCamera()->getProjectionMatrix() *= osg::Matrix::scale(1.0 / aspectRatioChange, 1.0, 1.0);
	}

	osg::Vec3 vPosEye, vCenter, vUp;
	viewer->getCamera()->getViewMatrixAsLookAt(vPosEye, vCenter, vUp);
	viewer->getCamera()->setViewMatrixAsLookAt(osg::Vec3(0.0, -3.0, 0.0), osg::Vec3(0.0, 0.0, 0.0), osg::Vec3(0.0, 0.0, 1.0));
	viewer->setSceneData(root);
	CaptureDrawCallback* capturedrawcallback = new CaptureDrawCallback(image_c.get());
	viewer->getCamera()->setPostDrawCallback(capturedrawcallback);

	NodeVisitor initnodevisitor = NodeVisitor();
	initnodevisitor.setCommand(COMMAND_INIT);
	model->accept(initnodevisitor);
	
	for (int i = 1; i <= 1; i++)
	{
		NodeVisitor apartnodevisitor = NodeVisitor();
		NodeVisitor nodevisitor = NodeVisitor();

		string txtname = "Final_results\\Motor\\" + filename + "_label_" + to_string(long long(i)) + ".txt";	//txt path
		ifstream selectfile(txtname);
		string temp;
		int groupnumber = 1;
		while (getline(selectfile, temp))
		{
			int tempid;
			string tempStr;
			char *tempChar = (char *)temp.data();
			tempStr = strtok(tempChar, " ");

			stringstream tempStream;
			tempStream << tempStr;
			tempStream >> tempid;

			temp = strtok(NULL, " ");
			int temptype;
			string typeStr;
			char *typeChar = (char *)temp.data();
			typeStr = strtok(typeChar, " ");

			stringstream typeStream;
			typeStream << typeStr;
			typeStream >> temptype;

			apartnodevisitor.grouptype[groupnumber] = temptype;
			nodevisitor.grouptype[groupnumber] = temptype;

			groupnumber++;
		}

		apartnodevisitor.grouptype[0] = groupnumber - 1;
		nodevisitor.grouptype[0] = groupnumber - 1;

		viewer->frame();


		nodevisitor.setCommand(COMMAND_COLOR);
		model->accept(nodevisitor);
		nodevisitor.setCommand(COMMAND_NULL);

		viewer->renderingTraversals();
		viewer->renderingTraversals();
		viewer->renderingTraversals();

		selectfile.close();

		osg::ref_ptr<osg::PositionAttitudeTransform> mt = positionTransform;
		
		string flodername = "motor";		//image save Path

		if (mt)
		{
			mt->setAttitude(osg::Quat(osg::DegreesToRadians(80.0f), osg::Vec3(1.0, 0.0, 0.0),
			osg::DegreesToRadians(10.0f), osg::Vec3(0.0, 1.0, 0.0),
			osg::DegreesToRadians(220.0f), osg::Vec3(0.0, 0.0, 1.0)));
			viewer->renderingTraversals();
			viewer->renderingTraversals();
			viewer->renderingTraversals();
			viewer->renderingTraversals();
			image_c->readPixels(0, 0, pixelwidth, pixelheight, GL_RGB, GL_UNSIGNED_BYTE);
			osgDB::writeImageFile(*(image_c.get()), flodername + "\\" + filename + "_" + to_string(long long(i)) + "_view.bmp");//motor view 


		}
	}

	viewer->realize();
}


void OSGFiles(string path, vector<string>& files)
{
	long   hFile = 0;
	//file informations
	struct _finddata_t fileinfo;
	string p;
	string filename;
	if ((hFile = _findfirst(p.assign(path).append("\\*").c_str(), &fileinfo)) != -1) 
	{
		do
		{
			if ((fileinfo.attrib &  _A_SUBDIR))  //if is fold
			{
				if (strcmp(fileinfo.name, ".") != 0 && strcmp(fileinfo.name, "..") != 0)
				{
					files.push_back(p.assign(path).append("\\").append(fileinfo.name));
					OSGFiles(p.assign(path).append("\\").append(fileinfo.name), files);
				}
			}
			else 
			{
				if (string(fileinfo.name) == "model.ive")//read model.ive
				{
					double start = clock();
					std::cout << "start handle" << endl;
					path = path + "\\";
					filename = path;
					string tempStr;
					char *tempChar = (char *)filename.data();
					filename = strtok(tempChar, "\\");
					for (int i = 0; i < 2; i++)//
					{
						filename = strtok(NULL, "\\");
					}

					ModelColor(path, filename);
					double finish = clock();
					std::cout << (double)(finish - start) / CLOCKS_PER_SEC << std::endl;
				}
			}
		} while (_findnext(hFile, &fileinfo) == 0);
		_findclose(hFile); //end if
	}
}

int main()
{
	string txtname = "motor_filename.txt";
	ifstream selectfile(txtname);
	string temp;
	while (getline(selectfile, temp))
	{
		files.push_back(temp);
	}
		
	for (int i = 0; i < files.size(); i++)
	{
		string filename;
		filename = files[i];
		string path = "Models\\motor\\" + filename + "\\";		//.ive model path
		ModelColor(path, filename);
	}
	selectfile.close();
}
