%% reading marker table
% This script loads a marker .csv file exported from Espion, manipulates it
% into the markers 4D array and then plots intensity curves of each marker.
% 

%clear all;                                                                 %clearing all vars. If this is commented out, then it is currently set up to be used by a master script (script that runs other scrpts).
%   Loading and Manipulating Marker Table to be a usable form 
%[file, folder] = uigetfile('*.csv');                                        %allow the user to choose the file they want markers extracted from. If this is commented, this is set-up for master script use.                                         
T = readtable(fullfile(folder,file));                                       %reads the marker data into a table data structure
T(:,end) = [];                                                              %deleting the last column of the table because it is empty and causes errors
names = table2cell(T(1,:));                                                 %copying the first row of the table into a names cell
names(3) = {'Cage'};                                                        %changing 'Cage #' to 'Cage' because MATLAB does not allow spaces and special chars in table vars
names(10) = {'Marker'};                                                     %similar thing here
T.Properties.VariableNames = names;                                         %setting the variable names of the table to be the names we pulled earlier
T(1:2,:) = [];                                                              %deleting the first two rows of the table because they are empty 

%extracting table data to cell
C = table2cell(T(:,{'Eye', 'Marker', 'uV', 'ms'}));                         %extracting the info we're interested in into a cell
                                                                            %Takes 'C' cell and divides the data into four arrays REa, REB, LEa and
                                                                            %LEB to separate by eye and marker. 
                                                                                  %eye = 1: RE      
                                                                                  %eye = 2: LE
                                                                                  %wave = 1: a
                                                                            %wave = 2: B
REa = [];                                                                   %Initializing arrays that will hold eye/marker specific times and voltages                                                                 
REB = [];
LEa = [];
LEB = [];
%for each data point 
for i=1:size(C,1) 
    %scans eye and marker columns
    for j=1:2
        if strcmp(C{i,j}, {'LE'})                                           %if 'LE' is the eye classification of this data point
           eye = 2;                                                         %set the eye marker equal to 2 (Left)
        elseif strcmp(C{i,j}, {'RE'}) 
           eye = 1;
        elseif strcmp(C{i,j}, {'a'})                                        %if the marker column of the C cell is 'a', set the wave marker to a (a wave)
           wave = 1;
        elseif strcmp(C{i,j}, {'B'})
           wave = 2;
        end 
    end 
    %divides data into REa, REB, LEa, LEB
        %row1: uV
        %row2: ms
    if eye==1 && wave==1                                                    %if the datapoint is right eye(eye==1) and a wave (wave==1), add its time and voltage to the REa matrix
        REa = cat(2, REa, [str2num(C{i,4});str2num(C{i,3})]);
    elseif eye==1 && wave==2
        REB = cat(2, REB, [str2num(C{i,4});str2num(C{i,3})]);
    elseif eye==2 && wave==1
        LEa = cat(2, LEa,[str2num(C{i,4});str2num(C{i,3})]);
    elseif eye==2 && wave==2
        LEB = cat(2, LEB, [str2num(C{i,4});str2num(C{i,3})]);
    end 
end 
markers = [];
markers(1,1,:,:) = REa;                                                     %stacks data into a 4D array. [eye, marker, uV or ms, steps)
markers(1,2,:,:) = REB;
markers(2,1,:,:) = LEa;
markers(2,2,:,:) = LEB;

markers = permute(markers, [1 2 4 3]);                                      %swaps the positions of the third and fourth dim (originally data type and step) to be:
                                                                            %[eye, marker, step, data type] to match the data format of ABFinder.m

%% Plotting Left vs Right Eye 'A' wave intensity

%extracting name from file name
if strfind(file, 'Light')                           %if the string 'Light' is present in our filename
    adaption = 'Light';                             %label this as a light adapted experiment. 
elseif strfind(file, 'Dark')                        %.....
    adaption = 'Dark';
end 

if strfind(file, 'Light')                           %if this is a light adapted experiment, set the cd scale to [1 3 10 30 100]
    cd = [1 3 10 30 100];
elseif strfind(file, 'Dark')
    cd = [0.003 0.01 0.1 1 3 10 30 100];
end 

%extracting animal name from folder path. Adaptable to changing folder
%structure but not to changing the name of animal. Recognizes RHO-DTR
folderseparated = regexp(folder, '\', 'split');     %separates the folder path into a cell with each component path piece
indx = find(contains(folderseparated,'RHO-DTR'));   %find the piece that contains 'RHO-DTR'. THIS MUST BE CHANGED IF YOUR ANIMAL NAME LABELLING SYSTEM IS DIFFERENT
animal = folderseparated{indx};                     %labels the animal name i.e 'RHO-DTR N1' under the animal var. 

%Left and Right eye a wave intensity. 
figa = figure;                                                                          %declare figa as the figure object of the figure we're going to make. Basically allows us to make more than figure at a time and allows us to retroactively edit the figure.
h = axes;                                                                               %declaring h as the axes object, which allows us to make the axes log scale. 
set(h,'xscale','log');                                                                  %setting the scale to be log
hold on;                                                                                %allows multiple lines to be plotted on the same figure
plot(cd, reshape(abs(markers(1,1,:,2)),[1 size(LEa,2)]));                               %plots a reshaped absolute value of the voltages against cd vector. reason for reshape: trying to call 1D array from a 4D one in this manner creates a 1x1xsteps array that we need to reshape to be 1xsteps
plot(cd, reshape(abs(markers(2,1,:,2)),[1 size(LEa,2)]));
title([animal ': ' adaption ' adapted "a" wave intensity in left versus right eye']);   %sets our title depending on animal name and adaption type
legend('Left Eye', 'Right Eye');                                                        %figure legend


%savefig(figa,fullfile(folder,"Dark_A.fig"));
%saveas(figa,fullfile(folder,"Dark_A.png"));
%% Dark Adapted Plotting Left vs Right Eye 'B' wave intensity
%cd = [0.003 0.01 0.1 1 3 10 30 100];

%Left and Right eye a wave intensity. 
figb = figure;                                                                          %almost identical to previous plotting except we're plotting the b wave. 
h = axes;
set(h,'xscale','log');
hold on;
hold on;
plot(cd, reshape(markers(1,2,:,2),[1 size(LEa,2)]));
plot(cd, reshape(markers(2,2,:,2),[1 size(LEa,2)]));
title([animal ': ' adaption ' adapted "B" wave intensity in left versus right eye']);
legend('Left Eye', 'Right Eye');

%savefig(figb,fullfile(folder,"Dark_B.fig"));
%saveas(figb,fullfile(folder,"Dark_B.png"));