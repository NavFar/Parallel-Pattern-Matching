// System includes
#include <stdio.h>
#include <stdlib.h>
#include <chrono>
#include <assert.h>
#include <math.h>
#include "EasyBMP/EasyBMP.h"
#include <vector>
#include <cmath>
using namespace std;
// CUDA runtime
#include <cuda_runtime.h>
#include <device_launch_parameters.h>
#define BLOCK_SIZE 512
#define THRESHOLD 0.999
////////////////////////////////////////////////////////////
/*_  __                    _
 | |/ /___ _ __ _ __   ___| |___
 | ' // _ \ '__| '_ \ / _ \ / __|
 | . \  __/ |  | | | |  __/ \__ \
 |_|\_\___|_|  |_| |_|\___|_|___/
 */
////////////////////////////////////////////////////////////
__global__ void corr(RGBpixel *image,RGBpixel*pattern,uint* size,long patternMultRes)
{
        int overalIndex=blockIdx.x * blockDim.x +threadIdx.x;
        int imageIIndex=overalIndex/size[0];
        int imageJIndex=overalIndex%size[0];
        if(imageIIndex>=size[0]-size[2]||imageJIndex>=size[1]-size[3])
                return;
        long top=0;
        long bot=0;
        int sum=0;
        RGBpixel tempPat,tempImg;
        for(int i=0; i<size[2]; i++)
        {
                for(int j=0; j<size[3]; j++)
                {
                        sum++;
                        tempPat=pattern[i*size[3]+j];
                        tempImg=image[(imageIIndex+i)*size[1]+(imageJIndex+j)];
                        top+=((tempPat.Red   * tempImg.Red)+
                              (tempPat.Green * tempImg.Green)+
                              (tempPat.Blue  * tempImg.Blue))/3;
                        bot+=((tempImg.Red   * tempImg.Red)+
                              (tempImg.Green * tempImg.Green)+
                              (tempImg.Blue  * tempImg.Blue))/3;
                }
        }
        if((top/sqrt((float)(patternMultRes*bot)))>=THRESHOLD)
                printf("%d,%d\n",imageIIndex,imageJIndex);

}
////////////////////////////////////////////////////////////
__global__ void patternMultSum(RGBpixel * pattern, uint * size,long * result)
{
        extern __shared__ long load[];
        int overalIndex = blockIdx.x*blockDim.x+threadIdx.x;
        int j=overalIndex/size[0];
        int i=overalIndex%size[0];
        if(i>=size[0]||j>=size[1])
                load[threadIdx.x]=0;
        else{
                load[threadIdx.x]= ((pattern[overalIndex].Red*pattern[overalIndex].Red)+
                                    (pattern[overalIndex].Green*pattern[overalIndex].Green)+
                                    (pattern[overalIndex].Blue*pattern[overalIndex].Blue))/3;
        }
        __syncthreads();
        for(uint step=blockDim.x/2; step>0; step>>=1) {
                if(threadIdx.x<step)
                        load[threadIdx.x]+=load[threadIdx.x+step];
                __syncthreads();
        }
        if(threadIdx.x==0)
                result[blockIdx.x]=load[0];
}
////////////////////////////////////////////////////////////
void cudaDeviceWarmUp(int devID=0){
        cudaSetDevice(devID);
        cudaError_t error;
        cudaDeviceProp deviceProp;
        error = cudaGetDevice(&devID);
        if (error != cudaSuccess)
        {
                printf("cudaGetDevice returned error %s (code %d), line(%d)\n", cudaGetErrorString(error), error, __LINE__);
                exit(EXIT_SUCCESS);
        }
        error = cudaGetDeviceProperties(&deviceProp, devID);
        if (deviceProp.computeMode == cudaComputeModeProhibited)
        {
                fprintf(stderr, "Error: device is running in <Compute Mode Prohibited>, no threads can use ::cudaSetDevice().\n");
                exit(EXIT_SUCCESS);
        }
        if (error != cudaSuccess)
        {
                printf("cudaGetDeviceProperties returned error %s (code %d), line(%d)\n", cudaGetErrorString(error), error, __LINE__);
                exit(EXIT_SUCCESS);
        }
        else
        {
                printf("GPU Device %d: \"%s\" with compute capability %d.%d\n", devID, deviceProp.name, deviceProp.major, deviceProp.minor);
        }
}
////////////////////////////////////////////////////////////
void runCor(BMP pattern,BMP image, long multRes)
{
        cudaError_t error;
        RGBpixel *patternData;
        int patternSize=pattern.TellWidth()*pattern.TellHeight();
        patternData = new RGBpixel[patternSize];
        for(int i=0; i<pattern.TellWidth(); i++)
        {
                for(int j=0; j<pattern.TellHeight(); j++)
                {
                        patternData[i*pattern.TellHeight()+j].Red=pattern(i,j)->Red;
                        patternData[i*pattern.TellHeight()+j].Green=pattern(i,j)->Green;
                        patternData[i*pattern.TellHeight()+j].Blue=pattern(i,j)->Blue;
                }
        }
        RGBpixel *d_patternData;
        error = cudaMalloc((void **)&d_patternData, patternSize* sizeof (RGBpixel));
        if (error != cudaSuccess)
        {
                printf("cudaMalloc d_input returned error %s (code %d), line(%d)\n", cudaGetErrorString(error), error, __LINE__);
                exit(EXIT_FAILURE);
        }
        error = cudaMemcpy(d_patternData, patternData, patternSize* sizeof (RGBpixel), cudaMemcpyHostToDevice);
        if (error != cudaSuccess)
        {
                printf("cudaMemcpy (d_patternData, patternData) returned error %s (code %d), line(%d)\n", cudaGetErrorString(error), error, __LINE__);
                exit(EXIT_FAILURE);
        }
        RGBpixel *imageData;
        int imageSize=image.TellWidth()*image.TellHeight();
        int numberOfBlocks=(int)ceil((float)imageSize/BLOCK_SIZE);
        imageData = new RGBpixel[imageSize];
        for(int i=0; i<image.TellWidth(); i++)
        {
                for(int j=0; j<image.TellHeight(); j++)
                {
                        imageData[i*image.TellHeight()+j].Red=image(i,j)->Red;
                        imageData[i*image.TellHeight()+j].Green=image(i,j)->Green;
                        imageData[i*image.TellHeight()+j].Blue=image(i,j)->Blue;
                }
        }
        RGBpixel * d_imageData;
        error = cudaMalloc((void **)&d_imageData, imageSize* sizeof (RGBpixel));
        if (error != cudaSuccess)
        {
                printf("cudaMalloc d_input returned error %s (code %d), line(%d)\n", cudaGetErrorString(error), error, __LINE__);
                exit(EXIT_FAILURE);
        }
        error = cudaMemcpy(d_imageData, imageData, imageSize* sizeof (RGBpixel), cudaMemcpyHostToDevice);
        if (error != cudaSuccess)
        {
                printf("cudaMemcpy (d_patternData, patternData) returned error %s (code %d), line(%d)\n", cudaGetErrorString(error), error, __LINE__);
                exit(EXIT_FAILURE);
        }

        uint size[]={(uint)image.TellWidth(),(uint)image.TellHeight(),(uint)pattern.TellWidth(),(uint)pattern.TellHeight()};
        uint *d_size;
        error = cudaMalloc((void **)&d_size,  4*sizeof (uint));
        if (error != cudaSuccess)
        {
                printf("cudaMalloc d_input returned error %s (code %d), line(%d)\n", cudaGetErrorString(error), error, __LINE__);
                exit(EXIT_FAILURE);
        }
        error = cudaMemcpy(d_size, size, 4*sizeof (uint), cudaMemcpyHostToDevice);
        if (error != cudaSuccess)
        {
                printf("cudaMemcpy (d_patternData, patternData) returned error %s (code %d), line(%d)\n", cudaGetErrorString(error), error, __LINE__);
                exit(EXIT_FAILURE);
        }
        /////////////////////// grid and threads
        dim3 grid(numberOfBlocks,1,1);
        dim3 threads(BLOCK_SIZE,1,1);
        ///////////////////////
        cudaEvent_t start;
        error = cudaEventCreate(&start);
        if (error != cudaSuccess)
        {
                fprintf(stderr, "Failed to create start event (error code %s)!\n", cudaGetErrorString(error));
                exit(EXIT_FAILURE);
        }
        cudaEvent_t stop;
        error = cudaEventCreate(&stop);
        if (error != cudaSuccess)
        {
                fprintf(stderr, "Failed to create stop event (error code %s)!\n", cudaGetErrorString(error));
                exit(EXIT_FAILURE);
        }
        error = cudaEventRecord(start, NULL);
        if (error != cudaSuccess)
        {
                fprintf(stderr, "Failed to record start event (error code %s)!\n", cudaGetErrorString(error));
                exit(EXIT_FAILURE);
        }
        corr<<< grid, threads>>> (d_imageData,d_patternData,d_size,multRes);
        error = cudaGetLastError();
        if (error != cudaSuccess)
        {
                fprintf(stderr, "Failed to launch kernel!\n", cudaGetErrorString(error));
                exit(EXIT_FAILURE);
        }

        // Record the stop event
        error = cudaEventRecord(stop, NULL);

        if (error != cudaSuccess)
        {
                fprintf(stderr, "Failed to record stop event (error code %s)!\n", cudaGetErrorString(error));
                exit(EXIT_FAILURE);
        }

        // Wait for the stop event to complete
        error = cudaEventSynchronize(stop);
        float msecTotal = 0.0f;
        error = cudaEventElapsedTime(&msecTotal, start, stop);
        if (error != cudaSuccess)
        {
                fprintf(stderr, "Failed to get time elapsed between events (error code %s)!\n", cudaGetErrorString(error));
                exit(EXIT_FAILURE);
        }
        cudaFree(d_size);
        cudaFree(d_imageData);
        cudaFree(d_patternData);
        free(imageData);

}
////////////////////////////////////////////////////////////
long runPatternMult(BMP pattern)
{
        cudaError_t error;
        RGBpixel *patternData;
        int patternSize=pattern.TellWidth()*pattern.TellHeight();
        int numberOfBlocks=(int)ceil((float)patternSize/BLOCK_SIZE);
        patternData = new RGBpixel[patternSize];
        for(int i=0; i<patternSize; i++) {
                patternData[i].Red=pattern(i%pattern.TellWidth(),i/pattern.TellWidth())->Red;
                patternData[i].Green=pattern(i%pattern.TellWidth(),i/pattern.TellWidth())->Green;
                patternData[i].Blue=pattern(i%pattern.TellWidth(),i/pattern.TellWidth())->Blue;
        }
        RGBpixel *d_patternData;
        error = cudaMalloc((void **)&d_patternData, patternSize* sizeof (RGBpixel));
        if (error != cudaSuccess)
        {
                printf("cudaMalloc d_input returned error %s (code %d), line(%d)\n", cudaGetErrorString(error), error, __LINE__);
                exit(EXIT_FAILURE);
        }
        error = cudaMemcpy(d_patternData, patternData, patternSize* sizeof (RGBpixel), cudaMemcpyHostToDevice);
        if (error != cudaSuccess)
        {
                printf("cudaMemcpy (d_patternData, patternData) returned error %s (code %d), line(%d)\n", cudaGetErrorString(error), error, __LINE__);
                exit(EXIT_FAILURE);
        }
        long *d_patternSum;
        error = cudaMalloc((void **)&d_patternSum, numberOfBlocks* sizeof (long));
        if (error != cudaSuccess)
        {
                printf("cudaMalloc d_input returned error %s (code %d), line(%d)\n", cudaGetErrorString(error), error, __LINE__);
                exit(EXIT_FAILURE);
        }
        uint patternDim[2];
        patternDim[0]=pattern.TellWidth();
        patternDim[1]=pattern.TellHeight();
        uint * d_patternDim;
        error = cudaMalloc((void **)&d_patternDim, 2* sizeof (uint));
        if (error != cudaSuccess)
        {
                printf("cudaMalloc d_input returned error %s (code %d), line(%d)\n", cudaGetErrorString(error), error, __LINE__);
                exit(EXIT_FAILURE);
        }
        error = cudaMemcpy(d_patternDim, patternDim, 2* sizeof (uint), cudaMemcpyHostToDevice);
        if (error != cudaSuccess)
        {
                printf("cudaMemcpy (d_patternData, patternData) returned error %s (code %d), line(%d)\n", cudaGetErrorString(error), error, __LINE__);
                exit(EXIT_FAILURE);
        }
        /////////////////////// grid and threads
        dim3 grid(numberOfBlocks,1,1);
        dim3 threads(BLOCK_SIZE,1,1);
        ///////////////////////
        cudaEvent_t start;
        error = cudaEventCreate(&start);
        if (error != cudaSuccess)
        {
                fprintf(stderr, "Failed to create start event (error code %s)!\n", cudaGetErrorString(error));
                exit(EXIT_FAILURE);
        }
        cudaEvent_t stop;
        error = cudaEventCreate(&stop);
        if (error != cudaSuccess)
        {
                fprintf(stderr, "Failed to create stop event (error code %s)!\n", cudaGetErrorString(error));
                exit(EXIT_FAILURE);
        }
        error = cudaEventRecord(start, NULL);
        if (error != cudaSuccess)
        {
                fprintf(stderr, "Failed to record start event (error code %s)!\n", cudaGetErrorString(error));
                exit(EXIT_FAILURE);
        }
        patternMultSum<<< grid, threads,BLOCK_SIZE * sizeof(long)>>> (d_patternData,d_patternDim,d_patternSum);
        error = cudaGetLastError();
        if (error != cudaSuccess)
        {
                fprintf(stderr, "Failed to launch kernel!\n", cudaGetErrorString(error));
                exit(EXIT_FAILURE);
        }

        // Record the stop event
        error = cudaEventRecord(stop, NULL);

        if (error != cudaSuccess)
        {
                fprintf(stderr, "Failed to record stop event (error code %s)!\n", cudaGetErrorString(error));
                exit(EXIT_FAILURE);
        }

        // Wait for the stop event to complete
        error = cudaEventSynchronize(stop);
        float msecTotal = 0.0f;
        error = cudaEventElapsedTime(&msecTotal, start, stop);
        if (error != cudaSuccess)
        {
                fprintf(stderr, "Failed to get time elapsed between events (error code %s)!\n", cudaGetErrorString(error));
                exit(EXIT_FAILURE);
        }
        long * patternSum;
        patternSum= new long[numberOfBlocks];
        error = cudaMemcpy(patternSum, d_patternSum, numberOfBlocks * sizeof (long), cudaMemcpyDeviceToHost);
        if (error != cudaSuccess)
        {
                printf("cudaMemcpy (h_output,d_input) returned error %s (code %d), line(%d)\n", cudaGetErrorString(error), error, __LINE__);
                exit(EXIT_FAILURE);
        }
        long sum=0;
        for(int i=0; i<numberOfBlocks; i++)
                sum+=patternSum[i];
        // cout<<sum<<endl;
        cudaFree(d_patternData);
        cudaFree(d_patternDim);
        cudaFree(d_patternSum);
        free(patternSum);
        free(patternData);
        return sum;

}
// void runCor(RGBpixel * d_pattern,BMP image, long multRes,uint patternWidth, uint patternHeight)

////////////////////////////////////////////////////////////
int main()
{
        cudaDeviceWarmUp();
        BMP pattern,rPattern,image;
        long patternMultSum=0;
        image.ReadFromFile("Inputs/collection.bmp");
        pattern.ReadFromFile("Inputs/collection_coin.bmp");
        patternMultSum=runPatternMult(pattern);
        runCor(pattern,image,patternMultSum);
        rotateImage(pattern, rPattern);
        runCor(rPattern,image,patternMultSum);
}
