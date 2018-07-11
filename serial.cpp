#include "EasyBMP/EasyBMP.h"
#include <iomanip>
#include <bitset>
#include <vector>
#include <cmath>
using namespace std;
//////////////////////////////////////////////////////////////////////////////////////////
void patternMatching(BMP &,BMP&,vector<uint>&);
//////////////////////////////////////////////////////////////////////////////////////////
int main( int argc, char* argv[] )
{
        BMP pattern,image;
        image.ReadFromFile("Inputs/collection.bmp");
        pattern.ReadFromFile("Inputs/collection_coin.bmp");
        monoChromatic(pattern);
        monoChromatic(image);
        vector<uint>res;
        patternMatching(image,pattern,res);
        cout<<"Pattern Repeated"<<res.size()<<"time(s).\n";
        for(uint i=0; i<res.size()/2; i++) {
                cout<<"(x"<<i<<",y"<<i<<")=("<<res.at(2*i)<<","<<res.at(2*i+1)<<")\t";

        }
        return 0;
}
//////////////////////////////////////////////////////////////////////////////////////////
void patternMatching(BMP &image,BMP& pattern,vector<uint>& res){
        double maxValue=0;
        bool flag=1;
        for(int i=0; i<image.TellWidth()-pattern.TellWidth(); i++)
        {
                for(int j=0; j<image.TellHeight()-pattern.TellHeight(); j++)
                {
                        double curVal = 0;
                        long TSum=0;
                        long ISum=0;
                        for(int k=0; k<pattern.TellWidth(); k++)
                        {
                                for(int z=0; z<pattern.TellHeight(); z++)
                                {
                                        curVal+=pattern(k,z)->Red*image(i+k,j+z)->Red;
                                        TSum+=pattern(k,z)->Red*pattern(k,z)->Red;
                                        ISum+=image(i+k,j+z)->Red*image(i+k,j+z)->Red;
                                }
                        }
                        curVal=curVal/sqrt(TSum*ISum);
                        if(flag||(curVal>maxValue))
                        {
                                flag=0;
                                res.clear();
                                res.push_back(i);
                                res.push_back(j);
                                maxValue=curVal;
                        }else if(curVal == maxValue) {
                                res.push_back(i);
                                res.push_back(j);
                        }
                }
        }
        return;
}
