#include "EasyBMP/EasyBMP.h"
#include <iomanip>
#include <bitset>
using namespace std;
int main( int argc, char* argv[] )
{
        BMP pattern,image;
        pattern.ReadFromFile("Inputs/collection_coin.bmp");
        image.ReadFromFile("Inputs/collection.bmp");
        // for( int i=0; i < Input.TellWidth(); i++)
        // {
        //         for( int j=0; j < Input.TellHeight(); j++)
        //
        //         {
        //                 cout<<"Pixel:("<<setw(4)<<i<<","<<setw(4)<<j<<") =(";
        //                 cout<<setw(3)<<hex<<bitset<8>(Input(i,j)->Red).to_ulong()<<dec<<",";
        //                 cout<<setw(3)<<hex<<bitset<8>(Input(i,j)->Green).to_ulong()<<dec<<",";
        //                 cout<<setw(3)<<hex<<bitset<8>(Input(i,j)->Blue).to_ulong()<<dec;
        //                 cout<<")"<<endl;
        //         }
        // }
        return 0;

}
