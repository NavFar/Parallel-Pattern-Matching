#include "EasyBMP/EasyBMP.h"
#include <chrono>
#include <vector>
using namespace std;
//////////////////////////////////////////////////////////////////////////////////////////
void patternMatching(BMP &,BMP&,vector<uint>&);
//////////////////////////////////////////////////////////////////////////////////////////
int main( int argc, char* argv[] )
{
        if(argc<3 || (argc-1)%2!=0)
        {
                cout<<"Wrong number of arguments \nYou should give arguments to program like this.\n [program name] image1.bmp template1.bmp image2.bmp template2.bmp ...";
        }
        for(int i=1; i<argc; i+=2)
        {
                BMP pattern,image;
                image.ReadFromFile(argv[i]);
                pattern.ReadFromFile(argv[i+1]);
                vector<uint>res1,res2;
                auto start_time = chrono::high_resolution_clock::now();
                patternMatching(image,pattern,res1);
                auto end_time = chrono::high_resolution_clock::now();
                auto totalTime = chrono::duration_cast<chrono::seconds>(end_time - start_time);
                cout<<(res1.size()+res2.size())/2<<"times.\n";
                cout<<totalTime.count()<<"Seconds.\n";
        }
        return 0;
}
//////////////////////////////////////////////////////////////////////////////////////////
void patternMatching(BMP &image,BMP& pattern,vector<uint>& res){

        long TSum=0;
        for(int i=0; i<pattern.TellWidth(); i++)
        {
                for(int j=0; j<pattern.TellHeight(); j++)
                {
                        TSum+=((pattern(i,j)->Red*pattern(i,j)->Red)+
                               (pattern(i,j)->Green*pattern(i,j)->Green)+
                               (pattern(i,j)->Blue*pattern(i,j)->Blue))/3;
                }
        }
        int ** IMult;
        IMult=new int*[image.TellWidth()];
        for(int i=0; i<image.TellWidth(); i++)
                IMult[i]=new int[image.TellHeight()];

        for(int i=0; i<image.TellWidth(); i++)
        {
                for(int j=0; j<image.TellHeight(); j++)
                {
                        IMult[i][j]=((image(i,j)->Red*image(i,j)->Red)+
                                     (image(i,j)->Green*image(i,j)->Green)+
                                     (image(i,j)->Blue*image(i,j)->Blue))/3;
                }
        }
        vector<uint> tempRes1;
        double maxValue=0;
        bool flag=1;
        for(int i=0; i<image.TellWidth()-pattern.TellWidth(); i++)
        {
                for(int j=0; j<image.TellHeight()-pattern.TellHeight(); j++)
                {
                        double curVal = 0;
                        long ISum=0;
                        for(int k=0; k<pattern.TellWidth(); k++)
                        {
                                for(int z=0; z<pattern.TellHeight(); z++)
                                {
                                        curVal+=((pattern(k,z)->Red*image(i+k,j+z)->Red)+
                                                 (pattern(k,z)->Green*image(i+k,j+z)->Green)+
                                                 (pattern(k,z)->Blue*image(i+k,j+z)->Blue))/3;
                                        ISum+=IMult[i+k][j+z];
                                }
                        }
                        curVal=(curVal*curVal)/(ISum*TSum);
                        if(flag||(curVal>maxValue))
                        {
                                flag=0;
                                tempRes1.clear();
                                tempRes1.push_back(i);
                                tempRes1.push_back(j);
                                maxValue=curVal;
                        }else if(curVal == maxValue) {
                                tempRes1.push_back(i);
                                tempRes1.push_back(j);
                        }
                }
        }

        vector<uint> tempRes2;
        BMP RPattern;
        rotateImage(pattern, RPattern);
        maxValue=0;
        flag=1;
        for(int i=0; i<image.TellWidth()-RPattern.TellWidth(); i++)
        {
                for(int j=0; j<image.TellHeight()-RPattern.TellHeight(); j++)
                {
                        double curVal = 0;
                        long ISum=0;
                        for(int k=0; k<RPattern.TellWidth(); k++)
                        {
                                for(int z=0; z<RPattern.TellHeight(); z++)
                                {
                                        curVal+=((RPattern(k,z)->Red*image(i+k,j+z)->Red)+
                                                 (RPattern(k,z)->Green*image(i+k,j+z)->Green)+
                                                 (RPattern(k,z)->Blue*image(i+k,j+z)->Blue))/3;
                                        ISum+=IMult[i+k][j+z];
                                }
                        }
                        curVal=(curVal*curVal)/(ISum*TSum);
                        if(flag||(curVal>maxValue))
                        {
                                flag=0;
                                tempRes2.clear();
                                tempRes2.push_back(i);
                                tempRes2.push_back(j);
                                maxValue=curVal;
                        }else if(curVal == maxValue) {
                                tempRes2.push_back(i);
                                tempRes2.push_back(j);
                        }
                }
        }
        for(uint i=0; i<tempRes1.size(); i++)
                res.push_back(tempRes1.at(i));
        for(uint i=0; i<tempRes2.size(); i++)
                res.push_back(tempRes2.at(i));
        return;
}
