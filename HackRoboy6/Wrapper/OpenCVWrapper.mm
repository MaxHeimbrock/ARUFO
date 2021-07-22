//
//  OpenCVWrapper.m
//  HackRoboy6
//
//  Created by Leenert Specht on 04.05.19.
//  Copyright © 2019 Leenert Specht. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#import "OpenCVWrapper.h"

@implementation OpenCVWrapper
-(NSString *) openCVVersionString
{
    return [NSString stringWithFormat:@"OpenCV Version %s", CV_VERSION];
}


-(NSString *) displayPositionOfMarker: (UIImage*) image
{
    // Convert UIImage to Mat for OpenCV
    cv::Mat img;
    UIImageToMat(image, img);
    
    cv::cvtColor(img, img, CV_RGB2HSV);
    
    cv::Mat mask;
    img.copyTo(mask);
    cv::inRange(img, cv::Scalar(110, 100, 100), cv::Scalar(130, 255, 255), mask);
    
    cv::cvtColor(img, img, CV_BGR2GRAY);
    
    cv::bitwise_and(img, mask, img);
    
    std::vector<std::vector<cv::Point>> contours;
    std::vector<cv::Vec4i> hierachy;
    int largest_area = 0;
    int largest_contour_index = 0;
    cv::findContours(img, contours, hierachy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE);
    
    if(contours.size() <= 0) {
        return @"-1:-1";
    }
    for(size_t i = 0; i < contours.size(); i++ ) // iterate through each contour.
    {
        double area = contourArea( contours[i] );  //  Find the area of contour
        
        if( area > largest_area )
        {
            largest_area = area;
            largest_contour_index = i;
        }
    }
    
    cv::Moments imageMoments = cv::moments(contours[largest_contour_index]);
    double x = imageMoments.m00 != 0.0 ? imageMoments.m10 / imageMoments.m00 : -1;
    double y = imageMoments.m00 != 0.0 ? imageMoments.m01 / imageMoments.m00 : -1;
        
    
    return [NSString stringWithFormat:@"%f:%f", x, y];
}




@end
