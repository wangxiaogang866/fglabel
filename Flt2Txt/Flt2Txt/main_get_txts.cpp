#include "GetTXTsOfModel.h"
#include <io.h>
void TransFlt2Ive(std::string path, std::vector<std::string>& files)
{
	long   hFile = 0; 
	struct _finddata_t fileinfo;
	std::string p;
	if ((hFile = _findfirst(p.assign(path).append("\\*").c_str(), &fileinfo)) != -1)
	{
		do
		{
			if ((fileinfo.attrib &  _A_SUBDIR))  //if is a folder
			{
				if (strcmp(fileinfo.name, ".") != 0 && strcmp(fileinfo.name, "..") != 0) //go into the folder
				{
					files.push_back(p.assign(path).append("\\").append(fileinfo.name));
					TransFlt2Ive(p.assign(path).append("\\").append(fileinfo.name), files);
				}
			}
			else //if is a document, convert .flt to .ive file.
			{
				std::string fname = std::string(fileinfo.name);
				std::string suffix = fname.substr(fname.size()-4, 4);
				if (suffix == ".flt")
				{
					std::string command = "osgconv " + path + "\\"+fname+" " + path + "\\"+fname.substr(0, fname.size()-4)+".ive";
					std::system(command.c_str());
				}
			}
		} while (_findnext(hFile, &fileinfo) == 0);
		_findclose(hFile); //find close  
	}
}

void TransIve2Txt(std::string path, std::vector<std::string>& files){
	GetTXTsOfModel GetTXTs;
	long   hFile = 0;
	struct _finddata_t fileinfo;
	std::string p;
	if ((hFile = _findfirst(p.assign(path).append("\\*").c_str(), &fileinfo)) != -1){
		do{
			if ((fileinfo.attrib &  _A_SUBDIR)){  //if is a folder
				if (strcmp(fileinfo.name, ".") != 0 && strcmp(fileinfo.name, "..") != 0)  //go into the folder  
				{
					files.push_back(p.assign(path).append("\\").append(fileinfo.name));
					TransIve2Txt(p.assign(path).append("\\").append(fileinfo.name), files);
				}
			}
			else{ //if is a document, convert .ive to .txt files.
				std::string fname = std::string(fileinfo.name);
				std::string suffix = fname.substr(fname.size()-4, 4);
				if (suffix == ".ive"){
					std::string read_path = path;
					read_path = read_path+"\\"+std::string(fileinfo.name);
					std::string savepath = path;

					GetTXTs.save_txts_of_model(read_path,savepath);
				}
			}
		} while (_findnext(hFile, &fileinfo) == 0);
		_findclose(hFile); //find close  
	}
}

int main()
{
	std::string model_path = "G:\\shilin\\test\\models\\car";
	std::vector<std::string> files;
	TransFlt2Ive(model_path, files);		//if models in model_path are .ive files, annotate this line
	TransIve2Txt(model_path, files);
	return 0;
}