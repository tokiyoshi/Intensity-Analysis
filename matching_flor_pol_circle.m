function [pol_boolean,flor_boolean,overall_overlap_precent,good_precent, ...
    great_precent,AWESOME_precent,area_covered ] = matching_flor_pol_circle( location_path,results_path )
%This function should check if the two images defined in the path fall
%within eachothers circles as defined by the average minor and major axis,
%as defined by the blob_diff_circler function
%   Detailed explanation goes here

addpath('basic_functions','specific_functions');

%This is a toggle which will show what is happening so that it is easier to
%explain (1=on,0=off)
  show  = 0;

in_bulk = 1;

if in_bulk == 0
    timestamp=makefile_path({'circle comparison'},results_path); 
    comp_path=[results_path,'/','circle comparison','/'];
end
%This porition will go and find the image that we want to look at and
%give us the path to this location. This is based off of the naming
%conventions which I know are commonly used for the Raw Data dump
try
    [filepath_flor,flor_file] = find_file(location_path,'F','mono.bmp');
catch 
    %hopfully it's justr looking at the wrong file name
    [filepath_flor,flor_file] = find_file(location_path,'F','bandw.bmp');
end
try
    [filepath_pol,pol_file] = find_file(location_path,'MM','4545.bmp');
catch 
    %hopfully it's justr looking at the wrong file name... lets try 
    [filepath_pol,pol_file] = find_file(location_path,'MM','4545.bmp');
end    

if in_bulk == 0 
    copyfile(filepath_flor,comp_path);
    flor_comp_path = [comp_path,flor_file];
    copyfile(filepath_pol,comp_path);
    pol_comp_path = [comp_path,pol_file];
else
    flor_comp_path = filepath_flor;
    pol_comp_path =  filepath_pol;
end
%pulling globals because I dont want to pass 12 variables through 4
%function
if in_bulk ==1
    global flor_edge_crop flor_min_convexarea flor_min_minoraxislength flor_min_area ... 
    flor_min_solidity flor_diffmax_length pol_edge_crop pol_min_convexarea ...
    pol_min_minoraxislength pol_min_area pol_min_solidity pol_diffmax_length...
    edge_crop min_convexarea min_minoraxislength min_area min_solidity ...
        diffmax_length;
    
    edge_crop = flor_edge_crop;
    min_convexarea =  flor_min_convexarea;
    min_minoraxislength  = flor_min_minoraxislength;
    min_area = flor_min_area;
    min_solidity = flor_min_solidity;
    diffmax_length = flor_diffmax_length;
    [flor_boolean,flor_centroid,flor_minoraxis,flor_majoraxis] = blob_diff_circler(filepath_flor);
    
    edge_crop = pol_edge_crop;
    min_convexarea =  pol_min_convexarea;
    min_minoraxislength  = pol_min_minoraxislength;
    min_area = pol_min_area;
    min_solidity = pol_min_solidity;
    diffmax_length = pol_diffmax_length;
    [pol_boolean,pol_centroid,pol_minoraxis,pol_majoraxis] = blob_diff_circler(filepath_pol);
end
if flor_boolean == 1  && pol_boolean == 1;
    %in the blob_diff_circler we subtract 11 pixels from each side so we
    %have to add them back to the coords now
    flor_centroid = flor_centroid + [11,11];
    pol_centroid = pol_centroid + [11,11];
    overlap_image = zeros(1024,1280);
    overlap_image_1 = im2bw(rgb2gray(insertShape(overlap_image,'FilledCircle',[flor_centroid,(flor_minoraxis/2)],'Color',[1,1,1],'Opacity', 1)),.5);
    overlap_image_2 = im2bw(rgb2gray(insertShape(overlap_image,'FilledCircle',[flor_centroid,(flor_majoraxis/2)],'Color',[1,1,1],'Opacity', 1)),.5);
    overlap_image_3 = im2bw(rgb2gray(insertShape(overlap_image,'FilledCircle',[pol_centroid,(pol_minoraxis/2)],'Color',[1,1,1],'Opacity', 1)),.5);
    overlap_image_4 = im2bw(rgb2gray(insertShape(overlap_image,'FilledCircle',[pol_centroid,(pol_majoraxis/2)],'Color',[1,1,1],'Opacity', 1)),.5);
    %this section is how I am seperating the matchtypes where we have two
    %columns. The #X column is for pol and X# column is for flor. 2 means
    %it is within the minor circle and 1 means it is within the major
    %circle. We can find overlap from this
    bw_overlap_image = (overlap_image_1 + overlap_image_2 + overlap_image_3*10 + overlap_image_4*10);
    if show ==1;
        show_bw_overlap_image = (overlap_image_1 + overlap_image_2 + overlap_image_3 + overlap_image_4);
    end
    comp00 = sum(bw_overlap_image(:) == 00);
    comp01 = sum(bw_overlap_image(:) == 01);
    comp02 = sum(bw_overlap_image(:) == 02);
    comp10 = sum(bw_overlap_image(:) == 10);
    comp11 = sum(bw_overlap_image(:) == 11);
    comp12 = sum(bw_overlap_image(:) == 12);
    comp20 = sum(bw_overlap_image(:) == 20);
    comp21 = sum(bw_overlap_image(:) == 21);
    comp22 = sum(bw_overlap_image(:) == 22);
    zero_sum = comp00;
    zeros_sum = comp01+comp02+comp10+comp20;
    %this is done for uniformity of naming... looks stupid though
    ones_sum = comp11;
    mixs_sum = comp12 + comp21;
    twos_sum = comp22;
    AWESOME_precent = 100*(twos_sum/(twos_sum + mixs_sum +ones_sum+zeros_sum));
    great_precent = 100*(mixs_sum/(twos_sum + mixs_sum +ones_sum+zeros_sum));
    good_precent = 100*(ones_sum/(twos_sum + mixs_sum +ones_sum+zeros_sum));
    overall_overlap_precent = good_precent + great_precent + AWESOME_precent;
    area_covered = 100*((twos_sum + mixs_sum +ones_sum+zeros_sum)/zero_sum);
else
    overall_overlap_precent = 0;
    good_precent = 0;
    great_precent = 0;
    AWESOME_precent = 0;
    area_covered = 0;
end
if show == 1 && pol_boolean == 1 && flor_boolean == 1
    imshow (show_bw_overlap_image*.25);
    imwrite(bw_overlap_image,strrep(flor_comp_path,' mono',' bw_overlap_image'));
end

%The Results will be all numbers for ease of importing pulling through the
%program (since csvwrite is used to that) so detailed notes on what the
%numbers mean is nessecary
results = [pol_boolean flor_boolean overall_overlap_precent good_precent ...
    great_precent AWESOME_precent area_covered];




if in_bulk == 0
    home = cd(comp_path);
    csvwrite(['S_S_',(strrep(pol_file,'_4545.bmp','.csv'))],results);
    cd(home);
end
end
